"""Application des limites des plans (Gratuit / Pro).

Avant ce module, les plans n'existaient que sur le papier : un commerçant qui payait
le plan Pro n'obtenait rien de plus que le plan Gratuit.
"""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import Business, Client, Invoice
from app.services.plans import effective_plan


class PlanLimitError(Exception):
    """Limite du plan atteinte ou fonction réservée à un plan supérieur (HTTP 402)."""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


async def ensure_can_create_invoice(db: AsyncSession, business: Business) -> None:
    if not settings.plans_enforced:
        return
    plan = effective_plan(business)
    if plan.max_invoices_per_month is None:
        return
    month_start = datetime.now(timezone.utc).replace(
        day=1, hour=0, minute=0, second=0, microsecond=0
    )
    count = (
        await db.execute(
            select(func.count())
            .select_from(Invoice)
            .where(Invoice.business_id == business.id, Invoice.created_at >= month_start)
        )
    ).scalar() or 0
    if count >= plan.max_invoices_per_month:
        raise PlanLimitError(
            f"Limite du plan {plan.name} atteinte ({plan.max_invoices_per_month} factures par mois). "
            "Passe au plan Pro dans Paramètres → Abonnement pour facturer sans limite."
        )


async def ensure_can_create_client(db: AsyncSession, business: Business) -> None:
    if not settings.plans_enforced:
        return
    plan = effective_plan(business)
    if plan.max_clients is None:
        return
    count = (
        await db.execute(
            select(func.count()).select_from(Client).where(Client.business_id == business.id)
        )
    ).scalar() or 0
    if count >= plan.max_clients:
        raise PlanLimitError(
            f"Limite du plan {plan.name} atteinte ({plan.max_clients} clients). "
            "Passe au plan Pro dans Paramètres → Abonnement pour ajouter plus de clients."
        )


def ensure_ai_enabled(business: Business) -> None:
    if not settings.plans_enforced:
        return
    plan = effective_plan(business)
    if not plan.ai_enabled:
        raise PlanLimitError(
            "L'assistant IA est inclus dans le plan Pro. "
            "Active-le dans Paramètres → Abonnement."
        )


def auto_reminders_allowed(business: Business) -> bool:
    if not settings.plans_enforced:
        return True
    return effective_plan(business).auto_reminders
