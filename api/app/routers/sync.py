from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business, get_current_user
from app.models import Business, Client, DeviceToken, Notification, Product, SyncOperation, User
from app.schemas import ClientCreate, FcmTokenRequest, NotificationResponse, SyncPullResponse, SyncPushRequest

router = APIRouter(tags=["sync", "notifications"])


@router.post("/sync/push")
async def sync_push(
    body: SyncPushRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    results = []
    for op in body.operations:
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
        if op.entity_type == "client" and op.operation == "create":
            payload = op.payload
            client = Client(
                business_id=business.id,
                name=payload.get("name", ""),
                phone=payload.get("phone"),
                email=payload.get("email"),
                notes=payload.get("notes"),
            )
            db.add(client)
            await db.flush()
            entity_id = str(client.id)

        db.add(SyncOperation(
            business_id=business.id,
            client_op_id=op.client_op_id,
            entity_type=op.entity_type,
            operation=op.operation,
            payload=op.payload,
            status="processed",
        ))
        results.append({"client_op_id": op.client_op_id, "status": "processed", "entity_id": entity_id})

    return {"results": results}


@router.get("/sync/pull", response_model=SyncPullResponse)
async def sync_pull(
    since: datetime | None = None,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    from app.routers.clients import _enrich_client
    from app.routers.products import _to_response
    from app.routers.invoices import _invoice_response
    from app.models import Invoice
    from sqlalchemy.orm import selectinload

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
        select(Notification).where(Notification.id == notification_id, Notification.business_id == business.id)
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
