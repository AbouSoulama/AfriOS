from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Business,
    DeviceToken,
    Invoice,
    InvoiceStatus,
    Notification,
    NotificationType,
    Payment,
    PaymentMethod,
    PaymentStatus,
)
from app.services.fcm_service import notify_business_payment


async def ensure_pending_payment(
    db: AsyncSession,
    invoice: Invoice,
    business: Business,
    ext_ref: str,
) -> Payment:
    existing = await db.execute(select(Payment).where(Payment.external_ref == ext_ref))
    payment = existing.scalar_one_or_none()
    if payment:
        return payment

    payment = Payment(
        invoice_id=invoice.id,
        business_id=business.id,
        method=PaymentMethod.other,
        amount=invoice.total,
        external_ref=ext_ref,
        status=PaymentStatus.pending,
        metadata_={"provider": "fedapay"},
    )
    db.add(payment)
    await db.flush()
    return payment


async def complete_mobile_money_payment(
    db: AsyncSession,
    payment: Payment,
    invoice: Invoice,
) -> None:
    if payment.status == PaymentStatus.completed:
        return

    payment.status = PaymentStatus.completed
    invoice.status = InvoiceStatus.paid
    invoice.paid_at = datetime.now(timezone.utc)

    db.add(
        Notification(
            business_id=payment.business_id,
            type=NotificationType.payment,
            title="Paiement reçu",
            body=f"Facture {invoice.number} — +{payment.amount:,.0f} FCFA",
            data={"invoice_id": str(invoice.id)},
        )
    )

    biz_result = await db.execute(select(Business).where(Business.id == payment.business_id))
    business = biz_result.scalar_one()
    tokens_result = await db.execute(select(DeviceToken).where(DeviceToken.user_id == business.owner_id))
    tokens = [t.token for t in tokens_result.scalars().all()]
    await notify_business_payment(tokens, f"{payment.amount:,.0f}", invoice.number)
