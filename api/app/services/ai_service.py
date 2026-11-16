import re
from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import (
    AiConversation,
    AiMessage,
    AiMessageRole,
    Business,
    Client,
    Invoice,
    InvoiceStatus,
    Product,
)
from app.services.invoice_service import build_whatsapp_message, whatsapp_share_url


# L'ORDRE COMPTE : le premier intent dont un motif correspond l'emporte.
# Les intents précis passent avant « revenue_period », dont le motif « factur » est très large
# (sinon « Factures impayées ? » répondait avec le chiffre d'affaires).
INTENT_PATTERNS: dict[str, list[str]] = {
    "low_stock": [r"stock faible", r"rupture", r"presque fini", r"stock bas", r"stock"],
    "invoice_count": [r"combien de facture", r"nombre de facture"],
    "unpaid_invoices": [r"impay", r"attente", r"non pay", r"en cours"],
    "overdue_clients": [r"relanc", r"retard", r"en retard", r"qui dois"],
    "revenue_period": [
        r"chiffre", r"\bca\b", r"factur", r"revenu", r"encaiss", r"combien.*mois", r"combien.*aujourd",
    ],
}


def detect_intent(message: str) -> str | None:
    msg = message.lower()
    for intent, patterns in INTENT_PATTERNS.items():
        for pattern in patterns:
            if re.search(pattern, msg):
                return intent
    return None


async def handle_intent(
    db: AsyncSession,
    business: Business,
    intent: str,
    message: str,
) -> tuple[str, dict | None]:
    now = datetime.now(timezone.utc)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    if intent == "revenue_period":
        # Facturé = factures émises ce mois (hors brouillons / annulées).
        invoiced = await db.execute(
            select(func.coalesce(func.sum(Invoice.total), 0)).where(
                Invoice.business_id == business.id,
                Invoice.status.in_([InvoiceStatus.paid, InvoiceStatus.sent, InvoiceStatus.overdue]),
                Invoice.created_at >= month_start,
            )
        )
        invoiced_total = invoiced.scalar() or Decimal("0")

        # Encaissé = factures réellement payées ce mois (même définition que le tableau de bord).
        collected = await db.execute(
            select(func.coalesce(func.sum(Invoice.total), 0)).where(
                Invoice.business_id == business.id,
                Invoice.status == InvoiceStatus.paid,
                Invoice.paid_at >= month_start,
            )
        )
        collected_total = collected.scalar() or Decimal("0")

        pending = await db.execute(
            select(func.count(), func.coalesce(func.sum(Invoice.total), 0)).where(
                Invoice.business_id == business.id,
                Invoice.status.in_([InvoiceStatus.sent, InvoiceStatus.overdue]),
            )
        )
        count, pending_total = pending.one()
        return (
            f"Ce mois-ci : {invoiced_total:,.0f} {business.currency} facturé, "
            f"{collected_total:,.0f} {business.currency} encaissé.\n"
            f"{count or 0} facture(s) en attente de paiement ({pending_total or 0:,.0f} {business.currency}).",
            None,
        )

    if intent == "unpaid_invoices":
        result = await db.execute(
            select(Invoice).where(
                Invoice.business_id == business.id,
                Invoice.status.in_([InvoiceStatus.sent, InvoiceStatus.overdue]),
            ).limit(10)
        )
        invoices = result.scalars().all()
        if not invoices:
            return "Aucune facture impayée. Bravo !", None
        lines = [f"• {inv.number} : {inv.total:,.0f} {business.currency}" for inv in invoices]
        return f"{len(invoices)} facture(s) impayée(s) :\n" + "\n".join(lines), None

    if intent == "low_stock":
        result = await db.execute(
            select(Product).where(
                Product.business_id == business.id,
                Product.quantity <= Product.low_stock_threshold,
            )
        )
        products = result.scalars().all()
        if not products:
            return "Tous tes produits ont un stock suffisant.", None
        lines = [f"• {p.name} : {p.quantity} restant(s)" for p in products]
        return f"{len(products)} produit(s) en stock faible :\n" + "\n".join(lines), None

    if intent == "overdue_clients":
        result = await db.execute(
            select(Invoice, Client)
            .join(Client, Invoice.client_id == Client.id)
            .where(Invoice.business_id == business.id, Invoice.status == InvoiceStatus.overdue)
            .limit(10)
        )
        rows = result.all()
        if not rows:
            return "Aucun client en retard de paiement.", None
        lines = [f"• {c.name} — {inv.number} ({inv.total:,.0f} {business.currency})" for inv, c in rows]
        return f"{len(rows)} client(s) à relancer :\n" + "\n".join(lines), {
            "type": "suggest_bulk_reminder",
            "count": len(rows),
        }

    if intent == "invoice_count":
        result = await db.execute(
            select(func.count()).where(Invoice.business_id == business.id)
        )
        count = result.scalar() or 0
        return f"Tu as {count} facture(s) au total.", None

    if intent == "send_reminder":
        return (
            "Pour envoyer une relance, va dans Factures ou Clients et utilise le bouton « Relancer ». "
            "Je peux aussi te lister les clients en retard — demande « Qui dois-je relancer ? »",
            None,
        )

    return "", None


async def chat_with_ai(
    db: AsyncSession,
    business: Business,
    user_message: str,
    conversation_id=None,
    openai_client=None,
) -> tuple[AiConversation, str, str | None, list[str], dict | None]:
    if conversation_id:
        result = await db.execute(
            select(AiConversation).where(
                AiConversation.id == conversation_id,
                AiConversation.business_id == business.id,
            )
        )
        conversation = result.scalar_one_or_none()
        if not conversation:
            conversation = AiConversation(business_id=business.id)
            db.add(conversation)
            await db.flush()
    else:
        conversation = AiConversation(business_id=business.id)
        db.add(conversation)
        await db.flush()

    db.add(AiMessage(conversation_id=conversation.id, role=AiMessageRole.user, content=user_message))

    intent = detect_intent(user_message)
    action = None
    suggestions = [
        "Combien j'ai facturé ce mois ?",
        "Factures impayées ?",
        "Stock faible ?",
        "Qui dois-je relancer ?",
    ]

    if intent:
        response, action = await handle_intent(db, business, intent, user_message)
        db.add(AiMessage(
            conversation_id=conversation.id,
            role=AiMessageRole.assistant,
            content=response,
            intent=intent,
        ))
        return conversation, response, intent, suggestions, action

    # Fallback LLM
    if openai_client:
        from app.config import settings
        system_prompt = (
            f"Tu es l'assistant AfriOS pour {business.name}, PME en {business.country_code}. "
            f"Réponds en français simple et court. Montants en {business.currency}. "
            "Ne invente pas de chiffres. Pas de conseils fiscaux."
        )
        completion = await openai_client.chat.completions.create(
            model=settings.openai_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message},
            ],
            max_tokens=300,
        )
        response = completion.choices[0].message.content or "Je n'ai pas pu répondre."
    else:
        response = (
            "Je peux t'aider avec ton chiffre d'affaires, tes factures impayées, "
            "ton stock faible ou tes relances. Essaie une de ces questions !"
        )

    db.add(AiMessage(conversation_id=conversation.id, role=AiMessageRole.assistant, content=response))
    return conversation, response, None, suggestions, action
