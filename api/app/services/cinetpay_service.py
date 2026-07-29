from dataclasses import dataclass
from urllib.parse import urlparse, urlunparse

import httpx

from app.config import settings
from app.models import Business, Invoice


@dataclass
class CinetPayCredentials:
    api_key: str
    site_id: str
    notify_url: str
    return_url: str
    sandbox: bool

    @property
    def configured(self) -> bool:
        return bool(self.api_key and self.site_id)


def resolve_credentials(business: Business | None = None) -> CinetPayCredentials:
    """Prefer per-business keys, fall back to platform env."""
    api_key = ""
    site_id = ""
    if business is not None:
        api_key = (business.cinetpay_api_key or "").strip()
        site_id = (business.cinetpay_site_id or "").strip()
    if not api_key:
        api_key = settings.cinetpay_api_key.strip()
    if not site_id:
        site_id = settings.cinetpay_site_id.strip()
    return CinetPayCredentials(
        api_key=api_key,
        site_id=site_id,
        notify_url=settings.cinetpay_notify_url,
        return_url=settings.cinetpay_return_url,
        sandbox=settings.cinetpay_sandbox,
    )


def public_api_origin() -> str:
    """Derive public API origin from notify_url (e.g. https://afrios-api.onrender.com)."""
    parsed = urlparse(settings.cinetpay_notify_url)
    if parsed.scheme and parsed.netloc:
        return urlunparse((parsed.scheme, parsed.netloc, "", "", "", ""))
    return "http://localhost:8000"


def sandbox_checkout_url(transaction_id: str, amount: object, invoice_number: str) -> str:
    origin = public_api_origin()
    return (
        f"{origin}/v1/payments/sandbox/checkout"
        f"?ref={transaction_id}&amount={amount}&invoice={invoice_number}"
    )


async def create_payment_link(
    invoice: Invoice,
    customer_name: str,
    customer_phone: str,
    business: Business | None = None,
) -> tuple[str, str, bool]:
    """Create CinetPay (or AfriOS sandbox) session.

    Returns (payment_url, transaction_id, is_sandbox_mock).
    """
    transaction_id = f"AFRI-{invoice.id.hex[:12].upper()}"
    creds = resolve_credentials(business)

    if not creds.configured:
        mock_url = sandbox_checkout_url(transaction_id, invoice.total, invoice.number)
        return mock_url, transaction_id, True

    payload = {
        "apikey": creds.api_key,
        "site_id": creds.site_id,
        "transaction_id": transaction_id,
        "amount": int(invoice.total),
        "currency": "XOF",
        "description": f"Facture {invoice.number}",
        "notify_url": creds.notify_url,
        "return_url": creds.return_url,
        "channels": "ALL",
        "metadata": str(invoice.id),
        "customer_name": customer_name,
        "customer_surname": customer_name,
        "customer_phone_number": customer_phone,
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api-checkout.cinetpay.com/v2/payment",
            json=payload,
            timeout=30,
        )
        data = response.json()

    if data.get("code") == "201":
        return data["data"]["payment_url"], transaction_id, False

    raise ValueError(data.get("message", "Erreur CinetPay"))


async def verify_cinetpay_transaction(
    transaction_id: str,
    business: Business | None = None,
) -> dict:
    creds = resolve_credentials(business)
    if not creds.configured:
        # Dev / sandbox mock: treat unknown checks as accepted so webhook + verify work.
        return {"status": "ACCEPTED", "transaction_id": transaction_id, "mock": True}

    payload = {
        "apikey": creds.api_key,
        "site_id": creds.site_id,
        "transaction_id": transaction_id,
    }
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "https://api-checkout.cinetpay.com/v2/payment/check",
            json=payload,
            timeout=30,
        )
        return response.json()


def payment_accepted(verification: dict) -> bool:
    status = verification.get("data", {}).get("status") or verification.get("status")
    return status in ("ACCEPTED", "completed", "00", "SUCCESS")
