from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, Client, Invoice, Reminder, ReminderChannel, ReminderRule
from app.services.invoice_service import build_whatsapp_message, whatsapp_share_url


async def get_or_create_reminder_rule(db: AsyncSession, business_id) -> ReminderRule:
    result = await db.execute(select(ReminderRule).where(ReminderRule.business_id == business_id))
    rule = result.scalar_one_or_none()
    if not rule:
        rule = ReminderRule(business_id=business_id)
        db.add(rule)
        await db.flush()
    return rule


async def send_manual_reminder(
    db: AsyncSession,
    business: Business,
    invoice: Invoice,
    client: Client,
    rule: ReminderRule | None = None,
) -> tuple[str, str | None]:
    rule = rule or await get_or_create_reminder_rule(db, business.id)
    message = rule.message_template.format(
        client_name=client.name,
        invoice_number=invoice.number,
        amount=f"{invoice.total:,.0f}",
    )

    db.add(Reminder(
        invoice_id=invoice.id,
        business_id=business.id,
        channel=ReminderChannel.whatsapp,
        message=message,
        sent_at=datetime.now(timezone.utc),
    ))

    wa_url = None
    if client.phone:
        wa_url = whatsapp_share_url(client.phone, message)

    return message, wa_url


async def get_overdue_invoices(db: AsyncSession, business_id):
    from app.models import InvoiceStatus
    result = await db.execute(
        select(Invoice, Client)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.business_id == business_id, Invoice.status == InvoiceStatus.overdue)
        .order_by(Invoice.due_date)
    )
    return result.all()
