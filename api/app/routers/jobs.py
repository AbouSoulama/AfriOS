"""Scheduled jobs endpoint (Render Cron / external scheduler).

Prefer this over Celery on the free tier — hit once a day with X-Cron-Secret.
"""

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.services.reminder_service import mark_overdue_invoices, process_auto_reminders

router = APIRouter(prefix="/jobs", tags=["jobs"])


def _assert_cron_secret(x_cron_secret: str | None) -> None:
    expected = (settings.jobs_cron_secret or "").strip()
    if not expected or x_cron_secret != expected:
        raise HTTPException(status_code=401, detail="Invalid cron secret")


@router.post("/daily")
async def run_daily_jobs(
    db: AsyncSession = Depends(get_db),
    x_cron_secret: str | None = Header(default=None, alias="X-Cron-Secret"),
):
    _assert_cron_secret(x_cron_secret)
    overdue_count = await mark_overdue_invoices(db)
    reminders = await process_auto_reminders(db)
    return {
        "status": "ok",
        "overdue_marked": overdue_count,
        **reminders,
    }
