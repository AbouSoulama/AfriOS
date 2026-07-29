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
)
from app.services.cinetpay_service import (
    create_payment_link,
    payment_accepted,
    resolve_credentials,
    verify_cinetpay_transaction,
)
from app.services.payment_service import complete_mobile_money_payment, ensure_pending_payment

router = APIRouter(tags=["payments"])


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
    has_business_keys = bool((business.cinetpay_api_key or "").strip() and (business.cinetpay_site_id or "").strip())
    platform = resolve_credentials(None)
    return PaymentSettingsResponse(
        site_id=(business.cinetpay_site_id or platform.site_id or None) or None,
        api_key_set=has_business_keys or platform.configured,
        enabled=bool(business.cinetpay_enabled) or has_business_keys or platform.configured,
        sandbox_mode=settings.cinetpay_sandbox or not (has_business_keys or platform.configured),
        using_platform_keys=platform.configured and not has_business_keys,
        notify_url=settings.cinetpay_notify_url,
        return_url=settings.cinetpay_return_url,
    )


@router.put("/payments/settings", response_model=PaymentSettingsResponse)
async def update_payment_settings(
    body: PaymentSettingsUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    if body.site_id is not None:
        business.cinetpay_site_id = body.site_id.strip() or None
    if body.clear_api_key:
        business.cinetpay_api_key = None
    elif body.api_key is not None and body.api_key.strip():
        business.cinetpay_api_key = body.api_key.strip()
    if body.enabled is not None:
        business.cinetpay_enabled = body.enabled
    elif business.cinetpay_api_key and business.cinetpay_site_id:
        business.cinetpay_enabled = True
    await db.flush()
    return await get_payment_settings(business)


@router.post("/payments/initiate")
async def initiate_payment(
    body: PaymentInitiateRequest,
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

    try:
        payment_link, ext_ref, is_mock = await create_payment_link(
            invoice, client.name, client.phone or "", business
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

    verification = await verify_cinetpay_transaction(transaction_id, business)
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


@router.post("/webhooks/cinetpay")
async def cinetpay_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
    else:
        form = await request.form()
        body = dict(form)

    transaction_id = body.get("cpm_trans_id") or body.get("transaction_id") or body.get("ref")
    if not transaction_id:
        return {"status": "ignored"}

    existing = await db.execute(select(Payment).where(Payment.external_ref == transaction_id))
    payment = existing.scalar_one_or_none()
    if not payment:
        return {"status": "not_found"}

    if payment.status == PaymentStatus.completed:
        return {"status": "already_processed"}

    biz_result = await db.execute(select(Business).where(Business.id == payment.business_id))
    business = biz_result.scalar_one()
    verification = await verify_cinetpay_transaction(transaction_id, business)

    if payment_accepted(verification):
        inv_result = await db.execute(select(Invoice).where(Invoice.id == payment.invoice_id))
        invoice = inv_result.scalar_one()
        await complete_mobile_money_payment(db, payment, invoice)

    return {"status": "ok"}


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

    status_banner = (
        "<p style='color:#0f766e;font-weight:700'>Paiement déjà confirmé.</p>"
        if already_paid
        else "<p style='color:#64748b'>Mode sandbox AfriOS — aucune clé CinetPay requise.</p>"
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
    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>AfriOS — Paiement sandbox</title>
  <style>
    body {{ font-family: system-ui, sans-serif; background: #f4f7f5; margin: 0; padding: 24px; color: #0f172a; }}
    .card {{ max-width: 420px; margin: 40px auto; background: #fff; border-radius: 20px; padding: 28px; box-shadow: 0 12px 40px rgba(15,23,42,.08); }}
    h1 {{ font-size: 1.35rem; margin: 0 0 8px; }}
    .amount {{ font-size: 2rem; font-weight: 800; color: #0d9488; margin: 16px 0; }}
    button {{ width: 100%; border: 0; border-radius: 14px; padding: 14px 16px; background: #0d9488; color: #fff; font-weight: 700; font-size: 1rem; cursor: pointer; }}
    .meta {{ font-size: .9rem; color: #64748b; word-break: break-all; }}
  </style>
</head>
<body>
  <div class="card">
    <h1>Payer la facture {invoice or ""}</h1>
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
<style>body{{font-family:system-ui,sans-serif;background:#f4f7f5;padding:24px}}
.card{{max-width:420px;margin:40px auto;background:#fff;border-radius:20px;padding:28px;text-align:center}}
h1{{color:#0d9488}}</style></head>
<body><div class="card">
  <h1>Paiement confirmé</h1>
  <p>Facture {invoice.number} marquée comme payée.</p>
  <p>Tu peux revenir dans AfriOS et appuyer sur « Vérifier le paiement ».</p>
</div></body></html>"""
    )
