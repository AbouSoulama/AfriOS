import base64
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.deps import get_current_business
from app.config import settings
from app.models import (
    Business,
    Client,
    Invoice,
    InvoiceItem,
    InvoiceStatus,
    Payment,
    PaymentMethod,
    PaymentStatus,
)
from app.schemas import (
    InvoiceCreate,
    InvoiceItemResponse,
    InvoiceResponse,
    InvoiceSendResponse,
    MarkPaidRequest,
)
from app.services.fedapay_service import create_payment_link, public_api_origin
from app.services.invoice_service import (
    build_whatsapp_message,
    generate_invoice_pdf,
    whatsapp_share_url,
)
from app.services.payment_service import ensure_pending_payment

router = APIRouter(prefix="/invoices", tags=["invoices"])


def _invoice_response(inv: Invoice, client_name: str | None = None) -> InvoiceResponse:
    return InvoiceResponse(
        id=inv.id,
        number=inv.number,
        status=inv.status.value,
        client_id=inv.client_id,
        client_name=client_name,
        subtotal=inv.subtotal,
        tax=inv.tax,
        total=inv.total,
        notes=inv.notes,
        due_date=inv.due_date,
        payment_link=inv.payment_link,
        created_at=inv.created_at,
        items=[
            InvoiceItemResponse(
                id=i.id,
                description=i.description,
                quantity=i.quantity,
                unit_price=i.unit_price,
                discount=i.discount,
                line_total=i.line_total,
                product_id=i.product_id,
            )
            for i in inv.items
        ],
    )


@router.get("", response_model=list[InvoiceResponse])
async def list_invoices(
    status: str | None = None,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    stmt = (
        select(Invoice, Client.name)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.business_id == business.id)
        .options(selectinload(Invoice.items))
        .order_by(Invoice.created_at.desc())
    )
    if status:
        stmt = stmt.where(Invoice.status == InvoiceStatus(status))
    result = await db.execute(stmt)
    return [_invoice_response(inv, name) for inv, name in result.all()]


@router.post("", response_model=InvoiceResponse)
async def create_invoice(
    body: InvoiceCreate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    from app.services.invoice_create import create_invoice_from_payload

    try:
        invoice = await create_invoice_from_payload(
            db,
            business,
            {
                "client_id": str(body.client_id),
                "notes": body.notes,
                "due_date": body.due_date.isoformat() if body.due_date else None,
                "items": [item.model_dump(mode="json") for item in body.items],
            },
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    client = await _get_client(db, business.id, invoice.client_id)
    await db.refresh(invoice, ["items"])
    return _invoice_response(invoice, client.name)


@router.get("/{invoice_id}", response_model=InvoiceResponse)
async def get_invoice(
    invoice_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    inv, client_name = await _get_invoice_with_client(db, business.id, invoice_id)
    return _invoice_response(inv, client_name)


@router.post("/{invoice_id}/send", response_model=InvoiceSendResponse)
async def send_invoice(
    invoice_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    inv, client_name = await _get_invoice_with_client(db, business.id, invoice_id)
    client = await _get_client(db, business.id, inv.client_id)

    try:
        payment_link, ext_ref, _is_mock = await create_payment_link(
            inv,
            client.name,
            client.phone or "",
            business,
            public_origin=public_api_origin(settings.public_base_url or None),
        )
        inv.payment_link = payment_link
        inv.payment_external_ref = ext_ref
        await ensure_pending_payment(db, inv, business, ext_ref)
    except Exception:
        payment_link = None

    inv.status = InvoiceStatus.sent
    inv.sent_at = datetime.now(timezone.utc)
    await db.flush()

    pdf_bytes = generate_invoice_pdf(inv, business, client, inv.items)
    pdf_b64 = base64.b64encode(pdf_bytes).decode()
    wa_message = build_whatsapp_message(inv, client, business, payment_link)

    return InvoiceSendResponse(
        invoice=_invoice_response(inv, client_name),
        pdf_url=f"data:application/pdf;base64,{pdf_b64}",
        payment_link=payment_link,
        whatsapp_message=wa_message,
    )


@router.get("/{invoice_id}/pdf")
async def get_invoice_pdf(
    invoice_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    inv, _ = await _get_invoice_with_client(db, business.id, invoice_id)
    client = await _get_client(db, business.id, inv.client_id)
    pdf_bytes = generate_invoice_pdf(inv, business, client, inv.items)
    return Response(content=pdf_bytes, media_type="application/pdf")


@router.post("/{invoice_id}/mark-paid", response_model=InvoiceResponse)
async def mark_paid(
    invoice_id: UUID,
    body: MarkPaidRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    inv, client_name = await _get_invoice_with_client(db, business.id, invoice_id)
    amount = body.amount or inv.total
    method = PaymentMethod(body.method) if body.method in PaymentMethod.__members__ else PaymentMethod.cash

    db.add(Payment(
        invoice_id=inv.id,
        business_id=business.id,
        method=method,
        amount=amount,
        status=PaymentStatus.completed,
    ))
    inv.status = InvoiceStatus.paid
    inv.paid_at = datetime.now(timezone.utc)
    await db.flush()
    return _invoice_response(inv, client_name)


async def _get_client(db, business_id, client_id) -> Client:
    result = await db.execute(select(Client).where(Client.id == client_id, Client.business_id == business_id))
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")
    return client


async def _get_invoice_with_client(db, business_id, invoice_id):
    result = await db.execute(
        select(Invoice, Client.name)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.id == invoice_id, Invoice.business_id == business_id)
        .options(selectinload(Invoice.items))
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Facture introuvable")
    return row[0], row[1]
