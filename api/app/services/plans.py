"""Subscription plans for AfriOS (freemium).

Ces plans décrivent ce que le COMMERÇANT paie à AfriOS pour utiliser l'application.
Ils n'ont rien à voir avec l'argent que ses clients lui versent (Mobile Money / espèces).
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone


@dataclass(frozen=True)
class Plan:
    id: str
    name: str
    price_monthly: int  # FCFA
    tagline: str
    features: list[str]
    max_invoices_per_month: int | None  # None = unlimited
    max_clients: int | None
    ai_enabled: bool
    auto_reminders: bool
    multi_user: bool
    # False = affiché mais pas encore souscriptible (fonctions non livrées).
    available: bool = True


PLANS: dict[str, Plan] = {
    "free": Plan(
        id="free",
        name="Gratuit",
        price_monthly=0,
        tagline="Pour commencer et tester.",
        features=[
            "Jusqu'à 50 factures / mois",
            "Gestion de stock",
            "Jusqu'à 25 clients",
            "Encaissement Mobile Money (compte FedaPay)",
            "Relances manuelles par WhatsApp",
            "Mode hors ligne",
        ],
        max_invoices_per_month=50,
        max_clients=25,
        ai_enabled=False,
        auto_reminders=False,
        multi_user=False,
    ),
    "pro": Plan(
        id="pro",
        name="Pro",
        price_monthly=6000,
        tagline="Pour les PME en croissance.",
        features=[
            "Factures illimitées",
            "Clients illimités",
            "Assistant IA business",
            "Relances automatiques (J+3, J+7, J+14)",
            "Notifications push",
            "Tout le plan Gratuit",
        ],
        max_invoices_per_month=None,
        max_clients=None,
        ai_enabled=True,
        auto_reminders=True,
        multi_user=False,
    ),
    "enterprise": Plan(
        id="enterprise",
        name="Entreprise",
        price_monthly=15000,
        tagline="Pour les organisations — bientôt disponible.",
        features=[
            "Tout le plan Pro",
            "Multi-utilisateurs & rôles (bientôt)",
            "Comptabilité & rapports (bientôt)",
            "Paie des employés (bientôt)",
        ],
        max_invoices_per_month=None,
        max_clients=None,
        ai_enabled=True,
        auto_reminders=True,
        multi_user=True,
        available=False,
    ),
}


def get_plan(plan_id: str | None) -> Plan:
    return PLANS.get((plan_id or "free").lower(), PLANS["free"])


def plan_is_active(plan_id: str | None, expires_at: datetime | None) -> bool:
    """Un plan payant sans date d'expiration est considéré actif (ex. offert à la main)."""
    plan = get_plan(plan_id)
    if plan.id == "free" or expires_at is None:
        return True
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    return expires_at > datetime.now(timezone.utc)


def effective_plan(business) -> Plan:
    """Plan réellement applicable : un abonnement expiré retombe sur Gratuit."""
    if plan_is_active(business.plan_id, business.plan_expires_at):
        return get_plan(business.plan_id)
    return PLANS["free"]


def plan_to_dict(plan: Plan) -> dict:
    return {
        "id": plan.id,
        "name": plan.name,
        "price_monthly": plan.price_monthly,
        "currency": "XOF",
        "tagline": plan.tagline,
        "features": plan.features,
        "max_invoices_per_month": plan.max_invoices_per_month,
        "max_clients": plan.max_clients,
        "ai_enabled": plan.ai_enabled,
        "auto_reminders": plan.auto_reminders,
        "multi_user": plan.multi_user,
        "available": plan.available,
    }
