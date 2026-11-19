"""Paiements.

Deux flux distincts, à ne JAMAIS mélanger :

1. ENCAISSEMENT (factures)  : le CLIENT paie le COMMERÇANT.
   -> clés Chariot du commerçant (Paramètres → Encaissement clients).
2. ABONNEMENT (Pro, ...)    : le COMMERÇANT paie AFRIOS.
   -> clés Chariot de la plateforme (variables d'environnement du serveur).
"""

from datetime import datetime, timedelta, timezone
from html import escape
from uuid import UUID

from fastapi import APIRouter, Depends, Form, HTTPException, Request
from fastapi.responses import HTMLResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.deps import get_current_business
from app.models import (
    Business,
    Client,
    Invoice,
    InvoiceStatus,
    Payment,
    PaymentStatus,
    User,
)
from app.schemas import (
    PaymentInitiateRequest,
    PaymentResponse,
    PaymentSettingsResponse,
    PaymentSettingsUpdate,
    PaymentVerifyRequest,
    SubscriptionCheckoutRequest,
)
from app.services.chariot_service import (
    PaymentConfigError,
    create_payment_link,
    create_subscription_payment_link,
    mock_allowed,
    payment_accepted,
    public_api_origin,
    transaction_metadata,
    verify_chariot_transaction,
)
from app.services.payment_service import complete_mobile_money_payment, ensure_pending_payment
from app.services.plans import PLANS, effective_plan, get_plan, plan_is_active, plan_to_dict

router = APIRouter(tags=["payments"])

SUBSCRIPTION_DAYS = 30


def _require_sandbox() -> None:
    """Les pages de simulation n'existent qu'en mode sandbox (jamais en production)."""
    if not mock_allowed():
        raise HTTPException(status_code=404, detail="Introuvable")


def _request_base(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-proto")
    host = request.headers.get("x-forwarded-host") or request.headers.get("host")
    if forwarded and host:
        return f"{forwarded}://{host}"
    return str(request.base_url)


def _payment_settings_response(business: Business) -> PaymentSettingsResponse:
    secret = (business.chariot_secret_key or business.fedapay_secret_key or "").strip()
    public = (business.chariot_public_key or business.fedapay_public_key or "").strip() or None
    has_business_keys = bool(secret)
    return PaymentSettingsResponse(
        provider="chariot",
        public_key=public,
        secret_key_set=has_business_keys,
        enabled=bool(business.chariot_enabled or business.fedapay_enabled) or has_business_keys,
        # Sans clés du commerçant, les paiements sont simulés (mode test) — jamais réels.
        sandbox_mode=settings.chariot_sandbox or not has_business_keys,
        ready=has_business_keys or mock_allowed(),
        using_platform_keys=False,
        callback_url=settings.chariot_callback_url,
        return_url=settings.chariot_return_url,
        site_id=public,
        api_key_set=has_business_keys,
        notify_url=settings.chariot_callback_url,
    )


def _apply_subscription(
    business: Business, plan_id: str, tx_ref: str | None, *, extend: bool = True
) -> None:
    """Active (ou prolonge) un plan payant pour 30 jours."""
    now = datetime.now(timezone.utc)
    start = now
    if extend and business.plan_id == plan_id and business.plan_expires_at:
        current = business.plan_expires_at
        if current.tzinfo is None:
            current = current.replace(tzinfo=timezone.utc)
        if current > now:
            start = current  # renouvellement anticipé : on ne perd pas les jours restants
    business.plan_id = plan_id
    business.plan_expires_at = start + timedelta(days=SUBSCRIPTION_DAYS)
    business.plan_payment_ref = tx_ref


@router.get("/payments", response_model=list[PaymentResponse])
async def list_payments(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Payment).where(Payment.business_id == business.id).order_by(Payment.created_at.desc())
    )
    payments = result.scalars().all()
    return [
        PaymentResponse(
            id=p.id,
            invoice_id=p.invoice_id,
            method=p.method.value,
            amount=p.amount,
            status=p.status.value,
            external_ref=p.external_ref,
            created_at=p.created_at,
        )
        for p in payments
    ]


@router.get("/payments/settings", response_model=PaymentSettingsResponse)
async def get_payment_settings(business: Business = Depends(get_current_business)):
    return _payment_settings_response(business)


@router.put("/payments/settings", response_model=PaymentSettingsResponse)
async def update_payment_settings(
    body: PaymentSettingsUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    public = body.public_key if body.public_key is not None else body.site_id
    secret = body.secret_key if body.secret_key is not None else body.api_key
    clear_secret = body.clear_secret_key or body.clear_api_key

    if public is not None:
        business.chariot_public_key = public.strip() or None
    if clear_secret:
        business.chariot_secret_key = None
    elif secret is not None and secret.strip():
        business.chariot_secret_key = secret.strip()
    if body.enabled is not None:
        business.chariot_enabled = body.enabled
    elif business.chariot_secret_key:
        business.chariot_enabled = True
    await db.flush()
    return _payment_settings_response(business)


# ── 1. ENCAISSEMENT : le client paie le commerçant ────────────────────────────


@router.post("/payments/initiate")
async def initiate_payment(
    body: PaymentInitiateRequest,
    request: Request,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    """Crée le lien de paiement que le CLIENT utilisera pour payer le commerçant."""
    result = await db.execute(
        select(Invoice, Client)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.id == body.invoice_id, Invoice.business_id == business.id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Facture introuvable")
    invoice, client = row

    if invoice.status == InvoiceStatus.paid:
        raise HTTPException(status_code=400, detail="Facture déjà payée")

    try:
        payment_link, ext_ref, is_mock = await create_payment_link(
            invoice,
            client.name,
            client.phone or "",
            business,
            public_origin=public_api_origin(_request_base(request)),
        )
    except PaymentConfigError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    invoice.payment_link = payment_link
    invoice.payment_external_ref = ext_ref
    payment = await ensure_pending_payment(db, invoice, business, ext_ref)

    return {
        "payment_link": payment_link,
        "transaction_id": ext_ref,
        "payment_id": str(payment.id),
        "sandbox_mock": is_mock,
        "provider": "chariot",
    }


@router.post("/payments/verify")
async def verify_payment(
    body: PaymentVerifyRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    """Vérifie si le CLIENT a payé (interroge Chariot)."""
    transaction_id = body.transaction_id
    invoice: Invoice | None = None

    if body.invoice_id:
        inv_result = await db.execute(
            select(Invoice).where(Invoice.id == body.invoice_id, Invoice.business_id == business.id)
        )
        invoice = inv_result.scalar_one_or_none()
        if not invoice:
            raise HTTPException(status_code=404, detail="Facture introuvable")
        transaction_id = transaction_id or invoice.payment_external_ref

    if not transaction_id:
        raise HTTPException(status_code=400, detail="transaction_id requis")

    pay_result = await db.execute(
        select(Payment).where(
            Payment.external_ref == transaction_id,
            Payment.business_id == business.id,
        )
    )
    payment = pay_result.scalar_one_or_none()
    if not payment:
        raise HTTPException(status_code=404, detail="Paiement introuvable")

    if invoice is None:
        inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
        invoice = inv_result.scalar_one()

    if payment.status == PaymentStatus.completed:
        return {
            "status": "already_paid",
            "invoice_id": str(invoice.id),
            "invoice_status": invoice.status.value,
        }

    verification = await verify_chariot_transaction(transaction_id, business, scope="invoice")
    if not payment_accepted(verification):
        return {
            "status": "pending",
            "invoice_id": str(invoice.id),
            "invoice_status": invoice.status.value,
            "verification": verification,
        }

    await complete_mobile_money_payment(db, payment, invoice)
    await db.flush()
    return {
        "status": "paid",
        "invoice_id": str(invoice.id),
        "invoice_status": invoice.status.value,
    }


@router.post("/webhooks/chariot")
@router.post("/webhooks/cinetpay")  # legacy alias
async def chariot_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    """Notification Chariot.

    Le contenu du webhook n'est JAMAIS cru tel quel (n'importe qui peut poster dessus) :
    on ne s'en sert que pour retrouver l'identifiant de transaction, puis on interroge
    Chariot avec nos clés pour connaître le vrai statut.
    """
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
    else:
        form = await request.form()
        body = dict(form)

    entity = body.get("entity") or body.get("v1/transaction") or body
    if isinstance(entity, dict):
        tx_id = entity.get("id") or body.get("id")
    else:
        tx_id = body.get("id") or body.get("transaction_id") or body.get("cpm_trans_id") or body.get("ref")

    if not tx_id:
        return {"status": "ignored"}

    refs = [str(tx_id), f"FEDA-{tx_id}"]
    payment = None
    for ref in refs:
        existing = await db.execute(select(Payment).where(Payment.external_ref == ref))
        payment = existing.scalar_one_or_none()
        if payment:
            break

    # Paiement d'une facture (le client a payé le commerçant)
    if payment:
        if payment.status == PaymentStatus.completed:
            return {"status": "already_processed"}
        biz_result = await db.execute(select(Business).where(Business.id == payment.business_id))
        business = biz_result.scalar_one()
        verification = await verify_chariot_transaction(
            payment.external_ref or str(tx_id), business, scope="invoice"
        )
        if payment_accepted(verification):
            inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
            invoice = inv_result.scalar_one()
            await complete_mobile_money_payment(db, payment, invoice)
            return {"status": "ok"}
        return {"status": "pending"}

    # Paiement d'un abonnement (le commerçant a payé AfriOS)
    tx_ref = f"FEDA-{tx_id}"
    verification = await verify_chariot_transaction(tx_ref, None, scope="subscription")
    if not payment_accepted(verification):
        return {"status": "ignored"}
    meta = transaction_metadata(verification)
    if meta.get("kind") != "subscription":
        return {"status": "not_found"}
    try:
        biz_id = UUID(str(meta.get("business_id")))
    except ValueError:
        return {"status": "ignored"}
    plan = PLANS.get(str(meta.get("plan_id") or "").lower())
    if not plan or plan.price_monthly <= 0 or not plan.available:
        return {"status": "ignored"}
    if _paid_amount(verification) < plan.price_monthly:
        return {"status": "ignored"}
    business = (await db.execute(select(Business).where(Business.id == biz_id))).scalar_one_or_none()
    if not business:
        return {"status": "ignored"}
    if business.plan_payment_ref == tx_ref:
        return {"status": "already_processed"}
    _apply_subscription(business, plan.id, tx_ref)
    await db.flush()
    return {"status": "subscription_ok", "plan_id": plan.id}


def _paid_amount(verification: dict) -> float:
    try:
        return float(verification.get("amount") or 0)
    except (TypeError, ValueError):
        return 0.0


# ── 2. ABONNEMENT : le commerçant paie AfriOS ─────────────────────────────────


@router.get("/billing/plans")
async def list_plans():
    return {"plans": [plan_to_dict(p) for p in PLANS.values()]}


@router.get("/billing/current")
async def current_subscription(business: Business = Depends(get_current_business)):
    stored = get_plan(business.plan_id)
    active = plan_is_active(business.plan_id, business.plan_expires_at)
    return {
        # Le plan réellement appliqué : un abonnement expiré retombe sur Gratuit.
        "plan": plan_to_dict(effective_plan(business)),
        "plan_id": effective_plan(business).id,
        "subscribed_plan_id": stored.id,
        "plan_expires_at": business.plan_expires_at,
        "is_active": active,
    }


@router.post("/billing/subscribe")
async def subscribe_plan(
    body: SubscriptionCheckoutRequest,
    request: Request,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    """Le COMMERÇANT paie son abonnement AfriOS (jamais l'argent de ses clients)."""
    plan = get_plan(body.plan_id)
    if plan.id == "free":
        business.plan_id = "free"
        business.plan_expires_at = None
        business.plan_payment_ref = None
        await db.flush()
        return {"status": "ok", "plan_id": "free", "payment_link": None}

    if not plan.available:
        raise HTTPException(status_code=400, detail=f"Le plan {plan.name} n'est pas encore disponible.")
    if plan.price_monthly <= 0:
        raise HTTPException(status_code=400, detail="Plan invalide")

    owner = (await db.execute(select(User).where(User.id == business.owner_id))).scalar_one()

    try:
        payment_link, ext_ref, is_mock = await create_subscription_payment_link(
            business=business,
            plan_id=plan.id,
            amount=plan.price_monthly,
            description=f"Abonnement AfriOS {plan.name} — 1 mois",
            customer_phone=owner.phone or "",
            customer_name=business.name,
            public_origin=public_api_origin(_request_base(request)),
        )
    except PaymentConfigError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    return {
        "status": "checkout",
        "plan_id": plan.id,
        "amount": plan.price_monthly,
        "payment_link": payment_link,
        "transaction_id": ext_ref,
        "sandbox_mock": is_mock,
        "provider": "chariot",
    }


@router.post("/billing/confirm")
async def confirm_subscription(
    body: PaymentVerifyRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    """Confirme un abonnement après paiement.

    L'identifiant de transaction vient du client : on ne lui fait pas confiance.
    On exige que Chariot confirme (1) le paiement, (2) qu'il concerne CE commerçant,
    (3) qu'il s'agit bien d'un abonnement et (4) que le montant couvre le plan.
    """
    transaction_id = body.transaction_id
    if not transaction_id:
        raise HTTPException(status_code=400, detail="transaction_id requis")

    verification = await verify_chariot_transaction(transaction_id, None, scope="subscription")

    if verification.get("mock"):
        # Mode sandbox : c'est la page de simulation qui active le plan. Ici on constate seulement.
        wanted = (body.plan_id or "").strip().lower()
        if not wanted and transaction_id.startswith("SUB-"):
            parts = transaction_id.split("-")
            wanted = parts[1].lower() if len(parts) >= 2 else ""
        if (
            wanted in PLANS
            and wanted != "free"
            and business.plan_id == wanted
            and plan_is_active(business.plan_id, business.plan_expires_at)
        ):
            return _confirmation_payload(business)
        return {"status": "pending", "plan_id": effective_plan(business).id}

    if not payment_accepted(verification):
        return {"status": "pending", "plan_id": effective_plan(business).id}

    meta = transaction_metadata(verification)
    if meta.get("kind") != "subscription" or str(meta.get("business_id")) != str(business.id):
        raise HTTPException(status_code=403, detail="Cette transaction ne correspond pas à ton abonnement.")

    plan = PLANS.get(str(meta.get("plan_id") or "").lower())
    if not plan or plan.price_monthly <= 0 or not plan.available:
        raise HTTPException(status_code=400, detail="Plan invalide")
    if _paid_amount(verification) < plan.price_monthly:
        raise HTTPException(status_code=400, detail="Montant payé insuffisant pour ce plan.")

    if business.plan_payment_ref != transaction_id:
        _apply_subscription(business, plan.id, transaction_id)
        await db.flush()
    return _confirmation_payload(business)


def _confirmation_payload(business: Business) -> dict:
    return {
        "status": "ok",
        "plan_id": business.plan_id,
        "plan_expires_at": business.plan_expires_at,
        "plan": plan_to_dict(get_plan(business.plan_id)),
    }


# ── Pages de simulation (mode sandbox uniquement) ─────────────────────────────

_SANDBOX_STYLE = """
    body { font-family: system-ui, sans-serif; background: #080D18; margin: 0; padding: 24px; color: #f8fafc; }
    .card { max-width: 420px; margin: 40px auto; background: #111A2B; border-radius: 20px; padding: 28px; border: 1px solid #1f2b40; }
    h1 { font-size: 1.3rem; margin: 0 0 8px; }
    .badge { display: inline-block; font-size: .72rem; font-weight: 700; letter-spacing: .06em; color: #D9A441; background: rgba(217,164,65,.12); border-radius: 999px; padding: 4px 10px; margin-bottom: 14px; }
    .amount { font-size: 2rem; font-weight: 800; color: #17C2AC; margin: 16px 0; }
    button { width: 100%; border: 0; border-radius: 14px; padding: 14px 16px; background: #0E9F8F; color: #fff; font-weight: 700; font-size: 1rem; cursor: pointer; }
    .meta { font-size: .9rem; color: #94a3b8; word-break: break-all; }
    .note { font-size: .92rem; color: #cbd5e1; line-height: 1.45; }
"""


def _sandbox_page(title: str, body_html: str) -> HTMLResponse:
    return HTMLResponse(
        f"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>AfriOS — {escape(title)}</title><style>{_SANDBOX_STYLE}</style></head>
<body><div class="card">{body_html}</div></body></html>"""
    )


@router.get("/payments/sandbox/checkout", response_class=HTMLResponse)
async def sandbox_checkout(
    ref: str,
    amount: str = "0",
    invoice: str = "",
    db: AsyncSession = Depends(get_db),
):
    _require_sandbox()
    pay_result = await db.execute(select(Payment).where(Payment.external_ref == ref))
    payment = pay_result.scalar_one_or_none()
    already_paid = payment is not None and payment.status == PaymentStatus.completed
    is_sub = ref.startswith("SUB-")

    if is_sub:
        title = "Abonnement AfriOS (simulation)"
        explanation = (
            "Tu es le <b>commerçant</b> : tu paies ici ton abonnement à <b>AfriOS</b>. "
            "Ce n'est pas l'argent de tes clients."
        )
    else:
        title = f"Facture {invoice} (simulation)"
        explanation = (
            "Tu joues ici le rôle de <b>ton client</b> : c'est lui qui paie la facture. "
            "L'argent va au commerçant. Ensuite, reviens dans AfriOS et appuie sur "
            "« Vérifier l'encaissement »."
        )

    if already_paid:
        status = "<p style='color:#17C2AC;font-weight:700'>Paiement déjà confirmé.</p>"
        action = ""
    else:
        status = ""
        action = f"""
        <form method="post" action="/v1/payments/sandbox/confirm">
          <input type="hidden" name="ref" value="{escape(ref)}" />
          <button type="submit">Confirmer le paiement (simulation)</button>
        </form>"""

    return _sandbox_page(
        title,
        f"""<span class="badge">MODE TEST — AUCUN ARGENT RÉEL</span>
    <h1>{escape(title)}</h1>
    <p class="note">{explanation}</p>
    {status}
    <div class="amount">{escape(amount)} FCFA</div>
    <p class="meta">Réf. {escape(ref)}</p>
    {action}""",
    )


@router.post("/payments/sandbox/confirm", response_class=HTMLResponse)
async def sandbox_confirm(ref: str = Form(...), db: AsyncSession = Depends(get_db)):
    _require_sandbox()

    # Abonnement simulé
    if ref.startswith("SUB-"):
        parts = ref.split("-")
        plan_id = parts[1].lower() if len(parts) >= 2 else "pro"
        biz_hex = parts[2] if len(parts) >= 3 else ""
        business = None
        if biz_hex:
            result = await db.execute(select(Business))
            for b in result.scalars().all():
                if b.id.hex[:10].upper() == biz_hex.upper():
                    business = b
                    break
        plan = PLANS.get(plan_id)
        if business and plan and plan.price_monthly > 0 and plan.available:
            _apply_subscription(business, plan_id, None, extend=False)
            await db.flush()
            return _sandbox_page(
                "Abonnement activé",
                f"""<span class="badge">MODE TEST</span>
    <h1 style="color:#17C2AC">Abonnement activé</h1>
    <p>Plan {escape(plan.name)} — {SUBSCRIPTION_DAYS} jours.</p>
    <p class="note">Reviens dans AfriOS.</p>""",
            )
        return HTMLResponse("<h1>Abonnement introuvable</h1>", status_code=404)

    # Paiement simulé d'une facture
    pay_result = await db.execute(select(Payment).where(Payment.external_ref == ref))
    payment = pay_result.scalar_one_or_none()
    if not payment:
        return HTMLResponse("<h1>Paiement introuvable</h1>", status_code=404)

    inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
    invoice = inv_result.scalar_one()
    await complete_mobile_money_payment(db, payment, invoice)
    await db.flush()

    return _sandbox_page(
        "Paiement confirmé",
        f"""<span class="badge">MODE TEST</span>
    <h1 style="color:#17C2AC">Paiement confirmé</h1>
    <p>Facture {escape(invoice.number)} marquée comme payée.</p>
    <p class="note">Reviens dans AfriOS : la facture apparaît comme encaissée.</p>""",
    )
