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

    asyncio.run(_process_auto_reminders())


@celery_app.task(name="app.worker.mark_overdue_invoices")
def mark_overdue_invoices():
    import asyncio

    asyncio.run(_mark_overdue())


async def _mark_overdue():
    from app.database import async_session
    from app.services.reminder_service import mark_overdue_invoices as mark_overdue

    async with async_session() as db:
        await mark_overdue(db)
        await db.commit()


async def _process_auto_reminders():
    from app.database import async_session
    from app.services.reminder_service import process_auto_reminders as run_reminders

    async with async_session() as db:
        await run_reminders(db)
        await db.commit()
