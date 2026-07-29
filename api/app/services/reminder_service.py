from datetime import date, datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    Business,
    Client,
    DeviceToken,
    Invoice,
    InvoiceStatus,
    Notification,
    NotificationType,
    Reminder,
    ReminderChannel,
    ReminderRule,
)
from app.services.fcm_service import send_push_notification
from app.services.invoice_service import whatsapp_share_url


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

    db.add(
        Reminder(
            invoice_id=invoice.id,
            business_id=business.id,
            channel=ReminderChannel.whatsapp,
            message=message,
            trigger_days=None,
            sent_at=datetime.now(timezone.utc),
        )
    )

    wa_url = None
    if client.phone:
        wa_url = whatsapp_share_url(client.phone, message)

    return message, wa_url


async def get_overdue_invoices(db: AsyncSession, business_id):
    result = await db.execute(
        select(Invoice, Client)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.business_id == business_id, Invoice.status == InvoiceStatus.overdue)
        .order_by(Invoice.due_date)
    )
    return result.all()


async def mark_overdue_invoices(db: AsyncSession) -> int:
    result = await db.execute(
        select(Invoice).where(
            Invoice.status == InvoiceStatus.sent,
            Invoice.due_date.is_not(None),
            Invoice.due_date < date.today(),
        )
    )
    invoices = result.scalars().all()
    for inv in invoices:
        inv.status = InvoiceStatus.overdue
    await db.flush()
    return len(invoices)


async def process_auto_reminders(db: AsyncSession) -> dict:
    """Create auto reminders for overdue invoices at configured day offsets.

    Without WhatsApp Business API we:
    - record the Reminder
    - notify the merchant (in-app + FCM) with a ready-to-send WhatsApp deep link
    """
    created = 0
    skipped = 0
    rules = (
        await db.execute(select(ReminderRule).where(ReminderRule.enabled.is_(True)))
    ).scalars().all()

    for rule in rules:
        biz_result = await db.execute(select(Business).where(Business.id == rule.business_id))
        business = biz_result.scalar_one_or_none()
        if not business:
            continue

        tokens_result = await db.execute(
            select(DeviceToken).where(DeviceToken.user_id == business.owner_id)
        )
        tokens = [t.token for t in tokens_result.scalars().all()]

        for days in rule.days_after_due or []:
            target_date = date.today() - timedelta(days=int(days))
            inv_result = await db.execute(
                select(Invoice, Client)
                .join(Client, Invoice.client_id == Client.id)
                .where(
                    Invoice.business_id == rule.business_id,
                    Invoice.status == InvoiceStatus.overdue,
                    Invoice.due_date == target_date,
                )
            )
            for invoice, client in inv_result.all():
                already = await db.execute(
                    select(Reminder).where(
                        Reminder.invoice_id == invoice.id,
                        Reminder.trigger_days == int(days),
                    )
                )
                if already.scalar_one_or_none():
                    skipped += 1
                    continue

                message = rule.message_template.format(
                    client_name=client.name,
                    invoice_number=invoice.number,
                    amount=f"{invoice.total:,.0f}",
                )
                db.add(
                    Reminder(
                        invoice_id=invoice.id,
                        business_id=business.id,
                        channel=ReminderChannel.whatsapp,
                        message=message,
                        trigger_days=int(days),
                        sent_at=datetime.now(timezone.utc),
                    )
                )

                wa_url = whatsapp_share_url(client.phone, message) if client.phone else None
                db.add(
                    Notification(
                        business_id=business.id,
                        type=NotificationType.reminder,
                        title=f"Relance J+{days} à envoyer",
                        body=f"{client.name} — facture {invoice.number}",
                        data={
                            "invoice_id": str(invoice.id),
                            "whatsapp_url": wa_url,
                            "trigger_days": int(days),
                        },
                    )
                )

                for token in tokens:
                    await send_push_notification(
                        token,
                        f"Relance J+{days}",
                        f"Envoie WhatsApp à {client.name} ({invoice.number})",
                        {"type": "reminder", "invoice_id": str(invoice.id)},
                    )
                created += 1

    await db.flush()
    return {"reminders_created": created, "skipped": skipped}
