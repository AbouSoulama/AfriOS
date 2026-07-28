from celery import Celery
from celery.schedules import crontab

from app.config import settings

celery_app = Celery("afrios", broker=settings.redis_url, backend=settings.redis_url)

celery_app.conf.beat_schedule = {
    "process-auto-reminders": {
        "task": "app.worker.process_auto_reminders",
        "schedule": crontab(hour=9, minute=0),
    },
    "mark-overdue-invoices": {
        "task": "app.worker.mark_overdue_invoices",
        "schedule": crontab(hour=0, minute=30),
    },
}


@celery_app.task(name="app.worker.process_auto_reminders")
def process_auto_reminders():
    """Process automatic reminders for overdue invoices (J+3, J+7, J+14)."""
    import asyncio
    asyncio.get_event_loop().run_until_complete(_process_auto_reminders())


@celery_app.task(name="app.worker.mark_overdue_invoices")
def mark_overdue_invoices():
    import asyncio
    asyncio.get_event_loop().run_until_complete(_mark_overdue())


async def _mark_overdue():
    from datetime import date
    from sqlalchemy import select, update
    from app.database import async_session
    from app.models import Invoice, InvoiceStatus

    async with async_session() as db:
        await db.execute(
            update(Invoice)
            .where(
                Invoice.status == InvoiceStatus.sent,
                Invoice.due_date < date.today(),
            )
            .values(status=InvoiceStatus.overdue)
        )
        await db.commit()


async def _process_auto_reminders():
    from datetime import date, timedelta
    from sqlalchemy import select
    from app.database import async_session
    from app.models import Business, Invoice, InvoiceStatus, ReminderRule

    async with async_session() as db:
        rules = (await db.execute(select(ReminderRule).where(ReminderRule.enabled == True))).scalars().all()  # noqa: E712
        for rule in rules:
            for days in rule.days_after_due:
                target_date = date.today() - timedelta(days=days)
                await db.execute(
                    select(Invoice).where(
                        Invoice.business_id == rule.business_id,
                        Invoice.status == InvoiceStatus.overdue,
                        Invoice.due_date == target_date,
                    )
                )
        await db.commit()
