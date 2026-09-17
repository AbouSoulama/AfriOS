"""Subscription plans for AfriOS (freemium)."""

from __future__ import annotations

from dataclasses import dataclass


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


PLANS: dict[str, Plan] = {
    "free": Plan(
        id="free",
        name="Gratuit",
        price_monthly=0,
        tagline="Pour commencer et tester.",
        features=[
            "Jusqu'à 50 factures / mois",
            "Gestion stock basique",
            "CRM limité (25 clients)",
            "Mobile Money (FedaPay)",
            "Mode offline",
            "Support communautaire",
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
        price_monthly=15000,
        tagline="Pour les PME en croissance.",
        features=[
            "Factures illimitées",
            "Stock & mouvements complets",
            "CRM illimité",
            "Tous les Mobile Money (FedaPay)",
            "Relances automatiques",
            "Assistant IA business",
            "Notifications push",
            "Support prioritaire",
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
        price_monthly=50000,
        tagline="Pour les organisations.",
        features=[
            "Tout Pro +",
            "Multi-utilisateurs & rôles",
            "Paie des employés",
            "Comptabilité avancée",
            "Rapports fiscaux",
            "API & intégrations",
            "Account manager dédié",
        ],
        max_invoices_per_month=None,
        max_clients=None,
        ai_enabled=True,
        auto_reminders=True,
        multi_user=True,
    ),
}


def get_plan(plan_id: str | None) -> Plan:
    return PLANS.get((plan_id or "free").lower(), PLANS["free"])


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
    }
