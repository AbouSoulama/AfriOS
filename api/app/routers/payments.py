from datetime import datetime, timedelta, timezone
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
)
from app.schemas import (
    PaymentInitiateRequest,
    PaymentResponse,
    PaymentSettingsResponse,
    PaymentSettingsUpdate,
    PaymentVerifyRequest,
    SubscriptionCheckoutRequest,
)
from app.services.fedapay_service import (
    create_payment_link,
    create_subscription_payment_link,
    payment_accepted,
    public_api_origin,
    resolve_credentials,
    verify_fedapay_transaction,
)
from app.services.payment_service import complete_mobile_money_payment, ensure_pending_payment
from app.services.plans import PLANS, get_plan, plan_to_dict

router = APIRouter(tags=["payments"])


def _payment_settings_response(business: Business) -> PaymentSettingsResponse:
    has_business_keys = bool((business.fedapay_secret_key or "").strip())
    platform = resolve_credentials(None)
    public = (business.fedapay_public_key or "").strip() or (platform.public_key or None) or None
    return PaymentSettingsResponse(
        provider="fedapay",
        public_key=public,
        secret_key_set=has_business_keys or platform.configured,
        enabled=bool(business.fedapay_enabled) or has_business_keys or platform.configured,
        sandbox_mode=settings.fedapay_sandbox or not (has_business_keys or platform.configured),
        using_platform_keys=platform.configured and not has_business_keys,
        callback_url=settings.fedapay_callback_url,
        return_url=settings.fedapay_return_url,
        site_id=public,
        api_key_set=has_business_keys or platform.configured,
        notify_url=settings.fedapay_callback_url,
    )


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
        business.fedapay_public_key = public.strip() or None
    if clear_secret:
        business.fedapay_secret_key = None
    elif secret is not None and secret.strip():
        business.fedapay_secret_key = secret.strip()
    if body.enabled is not None:
        business.fedapay_enabled = body.enabled
    elif business.fedapay_secret_key:
        business.fedapay_enabled = True
    await db.flush()
    return _payment_settings_response(business)


@router.post("/payments/initiate")
async def initiate_payment(
    body: PaymentInitiateRequest,
    request: Request,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
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

    forwarded = request.headers.get("x-forwarded-proto")
    host = request.headers.get("x-forwarded-host") or request.headers.get("host")
    if forwarded and host:
        request_base = f"{forwarded}://{host}"
    else:
        request_base = str(request.base_url)

    try:
        payment_link, ext_ref, is_mock = await create_payment_link(
            invoice,
            client.name,
            client.phone or "",
            business,
            public_origin=public_api_origin(request_base),
        )
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
        "provider": "fedapay",
    }


@router.post("/payments/verify")
async def verify_payment(
    body: PaymentVerifyRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
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

    verification = await verify_fedapay_transaction(transaction_id, business)
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


@router.post("/webhooks/fedapay")
@router.post("/webhooks/cinetpay")  # legacy alias
async def fedapay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
    else:
        form = await request.form()
        body = dict(form)

    # FedaPay callback often includes id + status in query/body
    entity = body.get("entity") or body.get("v1/transaction") or body
    if isinstance(entity, dict):
        tx_id = entity.get("id") or body.get("id")
        status = (entity.get("status") or body.get("status") or "").lower()
    else:
        tx_id = body.get("id") or body.get("transaction_id") or body.get("cpm_trans_id") or body.get("ref")
        status = (body.get("status") or "").lower()

    if not tx_id:
        return {"status": "ignored"}

    refs = [str(tx_id), f"FEDA-{tx_id}"]
    payment = None
    for ref in refs:
        existing = await db.execute(select(Payment).where(Payment.external_ref == ref))
        payment = existing.scalar_one_or_none()
        if payment:
            break

    # Subscription payments (no invoice Payment row) — handled via metadata on verify/checkout
    if not payment:
        # Try approve subscription if metadata present
        meta = entity.get("custom_metadata") if isinstance(entity, dict) else None
        if isinstance(meta, dict) and meta.get("kind") == "subscription" and status in {
            "approved",
            "transferred",
        }:
            biz_id = meta.get("business_id")
            plan_id = meta.get("plan_id")
            if biz_id and plan_id:
                biz_result = await db.execute(select(Business).where(Business.id == UUID(str(biz_id))))
                business = biz_result.scalar_one_or_none()
                if business and plan_id in PLANS:
                    business.plan_id = plan_id
                    business.plan_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
                    await db.flush()
                    return {"status": "subscription_ok", "plan_id": plan_id}
        return {"status": "not_found"}

    if payment.status == PaymentStatus.completed:
        return {"status": "already_processed"}

    biz_result = await db.execute(select(Business).where(Business.id == payment.business_id))
    business = biz_result.scalar_one()
    verification = await verify_fedapay_transaction(payment.external_ref or str(tx_id), business)
    if status in {"approved", "transferred"} or payment_accepted(verification):
        inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
        invoice = inv_result.scalar_one()
        await complete_mobile_money_payment(db, payment, invoice)

    return {"status": "ok"}


@router.get("/billing/plans")
async def list_plans():
    return {"plans": [plan_to_dict(p) for p in PLANS.values()]}


@router.get("/billing/current")
async def current_subscription(business: Business = Depends(get_current_business)):
    plan = get_plan(business.plan_id)
    return {
        "plan": plan_to_dict(plan),
        "plan_id": plan.id,
        "plan_expires_at": business.plan_expires_at,
        "is_active": True
        if plan.id == "free"
        else (
            business.plan_expires_at is None
            or business.plan_expires_at.replace(tzinfo=timezone.utc)
            > datetime.now(timezone.utc)
        ),
    }


@router.post("/billing/subscribe")
async def subscribe_plan(
    body: SubscriptionCheckoutRequest,
    request: Request,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    plan = get_plan(body.plan_id)
    if plan.id == "free":
        business.plan_id = "free"
        business.plan_expires_at = None
        await db.flush()
        return {"status": "ok", "plan_id": "free", "payment_link": None}

    if plan.price_monthly <= 0:
        raise HTTPException(status_code=400, detail="Plan invalide")

    forwarded = request.headers.get("x-forwarded-proto")
    host = request.headers.get("x-forwarded-host") or request.headers.get("host")
    request_base = f"{forwarded}://{host}" if forwarded and host else str(request.base_url)

    from app.models import User

    owner = (
        await db.execute(select(User).where(User.id == business.owner_id))
    ).scalar_one()

    try:
        payment_link, ext_ref, is_mock = await create_subscription_payment_link(
            business=business,
            plan_id=plan.id,
            amount=plan.price_monthly,
            description=f"Abonnement AfriOS {plan.name} — 1 mois",
            customer_phone=owner.phone or "",
            customer_name=business.name,
            public_origin=public_api_origin(request_base),
        )
    except ValueError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    # Store pending ref on business metadata via payment_external style — use plan_expires placeholder
    business.fedapay_enabled = business.fedapay_enabled or True
    await db.flush()

    return {
        "status": "checkout",
        "plan_id": plan.id,
        "amount": plan.price_monthly,
        "payment_link": payment_link,
        "transaction_id": ext_ref,
        "sandbox_mock": is_mock,
        "provider": "fedapay",
    }


@router.post("/billing/confirm")
async def confirm_subscription(
    body: PaymentVerifyRequest,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    """Confirm subscription after FedaPay / sandbox payment."""
    transaction_id = body.transaction_id
    if not transaction_id:
        raise HTTPException(status_code=400, detail="transaction_id requis")

    # Prefer explicit plan_id from client; else parse sandbox SUB-{PLAN}-...
    plan_id = (body.plan_id or "").strip().lower()
    if not plan_id and transaction_id.startswith("SUB-"):
        parts = transaction_id.split("-")
        if len(parts) >= 2:
            plan_id = parts[1].lower()

    verification = await verify_fedapay_transaction(transaction_id, business)
    # Live FedaPay: recover plan_id from custom_metadata when missing
    if not plan_id:
        raw = verification.get("raw") or {}
        meta = raw.get("custom_metadata") or raw.get("metadata") or {}
        if isinstance(meta, dict):
            plan_id = str(meta.get("plan_id") or "").strip().lower()

    # Always accept sandbox mock; for live require approved
    if not payment_accepted(verification) and not verification.get("mock"):
        return {"status": "pending", "plan_id": business.plan_id}

    if plan_id not in PLANS or plan_id == "free":
        plan_id = "pro"

    business.plan_id = plan_id
    business.plan_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
    await db.flush()
    return {
        "status": "ok",
        "plan_id": business.plan_id,
        "plan_expires_at": business.plan_expires_at,
        "plan": plan_to_dict(get_plan(business.plan_id)),
    }


@router.get("/payments/sandbox/checkout", response_class=HTMLResponse)
async def sandbox_checkout(
    ref: str,
    amount: str = "0",
    invoice: str = "",
    db: AsyncSession = Depends(get_db),
):
    pay_result = await db.execute(select(Payment).where(Payment.external_ref == ref))
    payment = pay_result.scalar_one_or_none()
    already_paid = payment is not None and payment.status == PaymentStatus.completed
    is_sub = ref.startswith("SUB-")

    status_banner = (
        "<p style='color:#0f766e;font-weight:700'>Paiement déjà confirmé.</p>"
        if already_paid
        else "<p style='color:#64748b'>Mode sandbox AfriOS / FedaPay — aucune clé requise.</p>"
    )
    action = (
        ""
        if already_paid
        else f"""
        <form method="post" action="/v1/payments/sandbox/confirm">
          <input type="hidden" name="ref" value="{ref}" />
          <button type="submit">Confirmer le paiement sandbox</button>
        </form>
        """
    )
    title = "Abonnement" if is_sub else f"Payer la facture {invoice or ''}"
    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>AfriOS — Paiement sandbox</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background: #0a0a0a; margin: 0; padding: 24px; color: #f8fafc; }}
    .card {{ max-width: 420px; margin: 40px auto; background: #111; border-radius: 20px; padding: 28px; border: 1px solid #222; }}
    h1 {{ font-size: 1.35rem; margin: 0 0 8px; }}
    .amount {{ font-size: 2rem; font-weight: 800; color: #22c55e; margin: 16px 0; }}
    button {{ width: 100%; border: 0; border-radius: 14px; padding: 14px 16px; background: #16a34a; color: #fff; font-weight: 700; font-size: 1rem; cursor: pointer; }}
    .meta {{ font-size: .9rem; color: #94a3b8; word-break: break-all; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>{title}</h1>
    {status_banner}
    <div class="amount">{amount} FCFA</div>
    <p class="meta">Réf. {ref}</p>
    {action}
  </div>
</body>
</html>"""
    return HTMLResponse(html)


@router.post("/payments/sandbox/confirm", response_class=HTMLResponse)
async def sandbox_confirm(ref: str = Form(...), db: AsyncSession = Depends(get_db)):
    # Subscription sandbox
    if ref.startswith("SUB-"):
        parts = ref.split("-")
        plan_id = parts[1].lower() if len(parts) >= 2 else "pro"
        # Find business via pending — we can't from ref alone easily; encode business in ref SUB-PRO-{hex}
        biz_hex = parts[2] if len(parts) >= 3 else ""
        business = None
        if biz_hex:
            result = await db.execute(select(Business))
            for b in result.scalars().all():
                if b.id.hex[:10].upper() == biz_hex.upper():
                    business = b
                    break
        if business and plan_id in PLANS:
            business.plan_id = plan_id
            business.plan_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
            await db.flush()
            return HTMLResponse(
                f"""<!DOCTYPE html><html lang="fr"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Abonnement OK</title>
<style>body{{font-family:system-ui;background:#0a0a0a;color:#fff;padding:24px}}
.card{{max-width:420px;margin:40px auto;background:#111;border-radius:20px;padding:28px;text-align:center}}
h1{{color:#22c55e}}</style></head>
<body><div class="card"><h1>Abonnement activé</h1>
<p>Plan {plan_id.upper()} — 30 jours.</p>
<p>Reviens dans AfriOS.</p></div></body></html>"""
            )
        return HTMLResponse("<h1>Abonnement introuvable</h1>", status_code=404)

    pay_result = await db.execute(select(Payment).where(Payment.external_ref == ref))
    payment = pay_result.scalar_one_or_none()
    if not payment:
        return HTMLResponse("<h1>Paiement introuvable</h1>", status_code=404)

    inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
    invoice = inv_result.scalar_one()
    await complete_mobile_money_payment(db, payment, invoice)
    await db.flush()

    return HTMLResponse(
        f"""<!DOCTYPE html>
<html lang="fr"><head><meta charset="utf-8"/><meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>Paiement OK</title>
<style>body{{font-family:system-ui,sans-serif;background:#0a0a0a;padding:24px;color:#fff}}
.card{{max-width:420px;margin:40px auto;background:#111;border-radius:20px;padding:28px;text-align:center}}
h1{{color:#22c55e}}</style></head>
<body><div class="card">
  <h1>Paiement confirmé</h1>
  <p>Facture {invoice.number} marquée comme payée.</p>
  <p>Reviens dans AfriOS et appuie sur « Vérifier le paiement ».</p>
</div></body></html>"""
    )
