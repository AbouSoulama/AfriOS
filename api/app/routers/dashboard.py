from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business
from app.models import Business, Invoice, InvoiceStatus, Product
from app.schemas import DashboardSummary

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
async def dashboard_summary(
    period: str = "month",
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    prev_month_start = (month_start - timedelta(days=1)).replace(day=1)

    revenue_today = await _sum_revenue(db, business.id, today_start, now)
    revenue_month = await _sum_revenue(db, business.id, month_start, now)
    revenue_prev = await _sum_revenue(db, business.id, prev_month_start, month_start)

    change = 0.0
    if revenue_prev > 0:
        change = float((revenue_month - revenue_prev) / revenue_prev * 100)

    pending = await db.execute(
        select(func.count(), func.coalesce(func.sum(Invoice.total), 0)).where(
            Invoice.business_id == business.id,
            Invoice.status.in_([InvoiceStatus.sent, InvoiceStatus.overdue]),
        )
    )
    pending_count, pending_total = pending.one()

    low_stock = await db.execute(
        select(func.count()).where(
            Product.business_id == business.id,
            Product.quantity <= Product.low_stock_threshold,
        )
    )

    overdue = await db.execute(
        select(func.count()).where(
            Invoice.business_id == business.id,
            Invoice.status == InvoiceStatus.overdue,
        )
    )

    return DashboardSummary(
        revenue_today=revenue_today,
        revenue_month=revenue_month,
        revenue_change_percent=round(change, 1),
        pending_invoices_count=pending_count or 0,
        pending_invoices_total=pending_total or 0,
        low_stock_count=low_stock.scalar() or 0,
        overdue_count=overdue.scalar() or 0,
    )


async def _sum_revenue(db, business_id, start, end):
    result = await db.execute(
        select(func.coalesce(func.sum(Invoice.total), 0)).where(
            Invoice.business_id == business_id,
            Invoice.status == InvoiceStatus.paid,
            Invoice.paid_at >= start,
            Invoice.paid_at < end,
        )
    )
    return result.scalar() or 0
