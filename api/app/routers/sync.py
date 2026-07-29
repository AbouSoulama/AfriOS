from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.deps import get_current_business, get_current_user
from app.models import (
    Business,
    Client,
    DeviceToken,
    Invoice,
    Notification,
    Product,
    SyncOperation,
    User,
)
from app.schemas import FcmTokenRequest, NotificationResponse, SyncPullResponse, SyncPushRequest
from app.services.invoice_create import create_invoice_from_payload

router = APIRouter(tags=["sync", "notifications"])


def _op_priority(entity_type: str) -> int:
    order = {"client": 0, "product": 1, "invoice": 2}
    return order.get(entity_type, 9)


@router.post("/sync/push")
async def sync_push(
    body: SyncPushRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    results = []
    # Resolve local client_op_id → server UUID within this batch (+ prior ops).
    client_op_map: dict[str, str] = {}

    operations = sorted(body.operations, key=lambda op: _op_priority(op.entity_type))

    for op in operations:
        existing = await db.execute(
            select(SyncOperation).where(
                SyncOperation.business_id == business.id,
                SyncOperation.client_op_id == op.client_op_id,
            )
        )
        if existing.scalar_one_or_none():
            results.append({"client_op_id": op.client_op_id, "status": "duplicate"})
            continue

        entity_id = None
        status = "processed"
        error = None

        try:
            if op.entity_type == "client" and op.operation == "create":
                payload = op.payload
                client = Client(
                    business_id=business.id,
                    name=payload.get("name", ""),
                    phone=payload.get("phone"),
                    email=payload.get("email"),
                    address=payload.get("address"),
                    notes=payload.get("notes"),
                )
                db.add(client)
                await db.flush()
                entity_id = str(client.id)
                client_op_map[op.client_op_id] = entity_id

            elif op.entity_type == "product" and op.operation == "create":
                payload = op.payload
                product = Product(
                    business_id=business.id,
                    name=payload.get("name", ""),
                    price=payload.get("price") or 0,
                    quantity=int(payload.get("quantity") or 0),
                    low_stock_threshold=int(payload.get("low_stock_threshold") or 5),
                    category=payload.get("category"),
                )
                db.add(product)
                await db.flush()
                entity_id = str(product.id)

            elif op.entity_type == "invoice" and op.operation == "create":
                payload = dict(op.payload)
                resolved_client_id = None
                raw_client = payload.get("client_id")
                client_op_id = payload.get("client_op_id")

                if raw_client and not str(raw_client).startswith("local-"):
                    resolved_client_id = UUID(str(raw_client))
                elif client_op_id:
                    mapped = client_op_map.get(client_op_id)
                    if not mapped:
                        # Look up previously synced client create for this op id
                        prior = await db.execute(
                            select(SyncOperation).where(
                                SyncOperation.business_id == business.id,
                                SyncOperation.client_op_id == client_op_id,
                                SyncOperation.entity_type == "client",
                            )
                        )
                        prior_op = prior.scalar_one_or_none()
                        if prior_op and prior_op.payload.get("_server_id"):
                            mapped = prior_op.payload["_server_id"]
                        # Fallback: match by phone/name from that sync op payload
                        if not mapped and prior_op:
                            name = (prior_op.payload.get("name") or "").strip()
                            phone = prior_op.payload.get("phone")
                            q = select(Client).where(
                                Client.business_id == business.id,
                                Client.name == name,
                            )
                            if phone:
                                q = q.where(Client.phone == phone)
                            found = (await db.execute(q.limit(1))).scalar_one_or_none()
                            if found:
                                mapped = str(found.id)
                    if not mapped:
                        raise ValueError(f"Client local non synchronisé ({client_op_id})")
                    resolved_client_id = UUID(mapped)
                else:
                    raise ValueError("client_id ou client_op_id requis")

                invoice = await create_invoice_from_payload(
                    db,
                    business,
                    payload,
                    client_id=resolved_client_id,
                )
                entity_id = str(invoice.id)
            else:
                status = "ignored"
        except Exception as exc:  # noqa: BLE001 — surface per-op errors to client
            status = "error"
            error = str(exc)

        # Persist server id on payload for later invoice resolution after reboot
        stored_payload = dict(op.payload)
        if entity_id and op.entity_type == "client":
            stored_payload["_server_id"] = entity_id

        if status != "error":
            db.add(
                SyncOperation(
                    business_id=business.id,
                    client_op_id=op.client_op_id,
                    entity_type=op.entity_type,
                    operation=op.operation,
                    payload=stored_payload,
                    status=status,
                )
            )

        entry = {"client_op_id": op.client_op_id, "status": status, "entity_id": entity_id}
        if error:
            entry["error"] = error
        results.append(entry)

    return {"results": results}


@router.get("/sync/pull", response_model=SyncPullResponse)
async def sync_pull(
    since: datetime | None = None,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    from app.routers.clients import _enrich_client
    from app.routers.invoices import _invoice_response
    from app.routers.products import _to_response

    clients_q = select(Client).where(Client.business_id == business.id)
    products_q = select(Product).where(Product.business_id == business.id)
    invoices_q = (
        select(Invoice, Client.name)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.business_id == business.id)
        .options(selectinload(Invoice.items))
    )

    if since:
        clients_q = clients_q.where(Client.updated_at >= since)
        products_q = products_q.where(Product.updated_at >= since)
        invoices_q = invoices_q.where(Invoice.updated_at >= since)

    clients = (await db.execute(clients_q)).scalars().all()
    products = (await db.execute(products_q)).scalars().all()
    invoices = (await db.execute(invoices_q)).all()

    return SyncPullResponse(
        clients=[await _enrich_client(db, c) for c in clients],
        products=[_to_response(p) for p in products],
        invoices=[_invoice_response(inv, name) for inv, name in invoices],
        server_time=datetime.now(timezone.utc),
    )


@router.get("/notifications", response_model=list[NotificationResponse])
async def list_notifications(
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Notification)
        .where(Notification.business_id == business.id)
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    return [
        NotificationResponse(
            id=n.id,
            type=n.type.value,
            title=n.title,
            body=n.body,
            read=n.read,
            data=n.data,
            created_at=n.created_at,
        )
        for n in result.scalars().all()
    ]


@router.put("/notifications/{notification_id}/read")
async def mark_notification_read(
    notification_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.business_id == business.id,
        )
    )
    notif = result.scalar_one_or_none()
    if notif:
        notif.read = True
    return {"message": "ok"}


@router.post("/devices/fcm-token")
async def register_fcm_token(
    body: FcmTokenRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(
        select(DeviceToken).where(DeviceToken.user_id == user.id, DeviceToken.token == body.token)
    )
    if not existing.scalar_one_or_none():
        db.add(DeviceToken(user_id=user.id, token=body.token, platform=body.platform))
    return {"message": "Token enregistré"}
