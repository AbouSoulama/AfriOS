from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business
from app.models import (
    Business,
    Client,
    DeviceToken,
    Invoice,
    InvoiceStatus,
    Notification,
    NotificationType,
    Payment,
    PaymentMethod,
    PaymentStatus,
)
from app.schemas import PaymentInitiateRequest, PaymentResponse
from app.services.cinetpay_service import create_payment_link, verify_cinetpay_transaction
from app.services.fcm_service import notify_business_payment

router = APIRouter(tags=["payments"])


@router.get("/payments", response_model=list[PaymentResponse])
async def list_payments(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Payment).where(Payment.business_id == business.id).order_by(Payment.created_at.desc())
    )
    payments = result.scalars().all()
    return [
        PaymentResponse(
            id=p.id,
            invoice_id=p.invoice_id,
            method=p.method.value,
            amount=p.amount,
            status=p.status.value,
            external_ref=p.external_ref,
            created_at=p.created_at,
        )
        for p in payments
    ]


@router.post("/payments/initiate")
async def initiate_payment(
    body: PaymentInitiateRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Invoice, Client)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.id == body.invoice_id, Invoice.business_id == business.id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Facture introuvable")
    invoice, client = row

    payment_link, ext_ref = await create_payment_link(invoice, client.name, client.phone or "")
    invoice.payment_link = payment_link
    invoice.payment_external_ref = ext_ref

    payment = Payment(
        invoice_id=invoice.id,
        business_id=business.id,
        method=PaymentMethod.other,
        amount=invoice.total,
        external_ref=ext_ref,
        status=PaymentStatus.pending,
    )
    db.add(payment)
    await db.flush()

    return {"payment_link": payment_link, "transaction_id": ext_ref, "payment_id": str(payment.id)}


@router.post("/webhooks/cinetpay")
async def cinetpay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    body = await request.json()
    transaction_id = body.get("cpm_trans_id") or body.get("transaction_id")
    if not transaction_id:
        return {"status": "ignored"}

    existing = await db.execute(select(Payment).where(Payment.external_ref == transaction_id))
    payment = existing.scalar_one_or_none()
    if not payment:
        return {"status": "not_found"}

    if payment.status == PaymentStatus.completed:
        return {"status": "already_processed"}

    verification = await verify_cinetpay_transaction(transaction_id)
    status = verification.get("data", {}).get("status") or verification.get("status")

    if status in ("ACCEPTED", "completed", "00"):
        payment.status = PaymentStatus.completed
        result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
        invoice = result.scalar_one()
        invoice.status = InvoiceStatus.paid
        invoice.paid_at = datetime.now(timezone.utc)

        db.add(Notification(
            business_id=payment.business_id,
            type=NotificationType.payment,
            title="Paiement reçu",
            body=f"Facture {invoice.number} — +{payment.amount:,.0f} FCFA",
            data={"invoice_id": str(invoice.id)},
        ))

        tokens_result = await db.execute(
            select(DeviceToken.token)
            .join(Invoice, Invoice.business_id == payment.business_id)
            .where(Invoice.id == payment.invoice_id)
        )
        # Notify business owner tokens
        from app.models import Business
        biz_result = await db.execute(select(Business).where(Business.id == payment.business_id))
        business = biz_result.scalar_one()
        tokens_result = await db.execute(select(DeviceToken).where(DeviceToken.user_id == business.owner_id))
        tokens = [t.token for t in tokens_result.scalars().all()]
        await notify_business_payment(tokens, f"{payment.amount:,.0f}", invoice.number)

    return {"status": "ok"}
