import uuid
from decimal import Decimal

import httpx

from app.config import settings
from app.models import Invoice


async def create_payment_link(invoice: Invoice, customer_name: str, customer_phone: str) -> tuple[str, str]:
    """Create CinetPay payment session. Returns (payment_url, transaction_id)."""
    transaction_id = f"AFRI-{invoice.id.hex[:12].upper()}"

    if not settings.cinetpay_api_key or not settings.cinetpay_site_id:
        # Sandbox/dev fallback
        mock_url = f"https://sandbox.cinetpay.com/pay/?ref={transaction_id}&amount={invoice.total}"
        return mock_url, transaction_id

    payload = {
        "apikey": settings.cinetpay_api_key,
        "site_id": settings.cinetpay_site_id,
        "transaction_id": transaction_id,
        "amount": int(invoice.total),
        "currency": "XOF",
        "description": f"Facture {invoice.number}",
        "notify_url": settings.cinetpay_notify_url,
        "return_url": settings.cinetpay_return_url,
        "channels": "ALL",
        "metadata": str(invoice.id),
        "customer_name": customer_name,
        "customer_surname": customer_name,
        "customer_phone_number": customer_phone,
    }

    base_url = "https://api-checkout.cinetpay.com/v2/payment" if not settings.cinetpay_sandbox else "https://api-checkout.cinetpay.com/v2/payment"

    async with httpx.AsyncClient() as client:
        response = await client.post(base_url, json=payload, timeout=30)
        data = response.json()

    if data.get("code") == "201":
        return data["data"]["payment_url"], transaction_id

    raise ValueError(data.get("message", "Erreur CinetPay"))


async def verify_cinetpay_transaction(transaction_id: str) -> dict:
    if not settings.cinetpay_api_key:
        return {"status": "ACCEPTED", "transaction_id": transaction_id}

    payload = {
        "apikey": settings.cinetpay_api_key,
        "site_id": settings.cinetpay_site_id,
        "transaction_id": transaction_id,
    }
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api-checkout.cinetpay.com/v2/payment/check",
            json=payload,
            timeout=30,
        )
        return response.json()
