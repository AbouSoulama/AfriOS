"""FedaPay Mobile Money integration (invoice payments + subscriptions)."""

from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlparse, urlunparse

import httpx

from app.config import settings
from app.models import Business, Invoice


@dataclass
class FedaPayCredentials:
    secret_key: str
    public_key: str
    sandbox: bool
    callback_url: str
    return_url: str

    @property
    def configured(self) -> bool:
        return bool(self.secret_key.strip())

    @property
    def api_base(self) -> str:
        if self.sandbox:
            return "https://sandbox-api.fedapay.com/v1"
        return "https://api.fedapay.com/v1"


def resolve_credentials(business: Business | None = None) -> FedaPayCredentials:
    secret = ""
    public = ""
    if business is not None:
        secret = (getattr(business, "fedapay_secret_key", None) or "").strip()
        public = (getattr(business, "fedapay_public_key", None) or "").strip()
    if not secret:
        secret = (settings.fedapay_secret_key or "").strip()
    if not public:
        public = (settings.fedapay_public_key or "").strip()
    return FedaPayCredentials(
        secret_key=secret,
        public_key=public,
        sandbox=settings.fedapay_sandbox,
        callback_url=settings.fedapay_callback_url,
        return_url=settings.fedapay_return_url,
    )


def _origin_from_url(url: str) -> str | None:
    parsed = urlparse(url)
    if parsed.scheme and parsed.netloc:
        return urlunparse((parsed.scheme, parsed.netloc, "", "", "", ""))
    return None


def public_api_origin(request_base_url: str | None = None) -> str:
    request_origin = (
        _origin_from_url((request_base_url or "").rstrip("/") + "/") if request_base_url else None
    )
    configured = (
        _origin_from_url(settings.public_base_url.strip()) if settings.public_base_url.strip() else None
    )
    callback_origin = _origin_from_url(settings.fedapay_callback_url)

    if request_origin and "localhost" not in request_origin and "127.0.0.1" not in request_origin:
        return request_origin
    if configured:
        return configured
    if request_origin:
        return request_origin
    if callback_origin:
        return callback_origin
    return "http://localhost:8000"


def sandbox_checkout_url(
    transaction_id: str,
    amount: object,
    invoice_number: str,
    *,
    public_origin: str | None = None,
) -> str:
    origin = (public_origin or public_api_origin()).rstrip("/")
    return (
        f"{origin}/v1/payments/sandbox/checkout"
        f"?ref={transaction_id}&amount={amount}&invoice={invoice_number}"
    )


def _split_phone(phone: str, country_code: str = "SN") -> tuple[str, str]:
    digits = "".join(c for c in (phone or "") if c.isdigit())
    country = (country_code or "SN").upper()
    dial = {
        "SN": "221",
        "CI": "225",
        "BJ": "229",
        "TG": "228",
        "BF": "226",
        "ML": "223",
        "NE": "227",
        "GN": "224",
    }.get(country, "221")
    iso = {
        "SN": "sn",
        "CI": "ci",
        "BJ": "bj",
        "TG": "tg",
        "BF": "bf",
        "ML": "ml",
        "NE": "ne",
        "GN": "gn",
    }.get(country, "sn")
    if digits.startswith(dial) and len(digits) > len(dial):
        return digits[len(dial) :], iso
    if digits.startswith("0"):
        digits = digits[1:]
    return digits or "00000000", iso


def _auth_headers(creds: FedaPayCredentials) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {creds.secret_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }


async def create_payment_link(
    invoice: Invoice,
    customer_name: str,
    customer_phone: str,
    business: Business | None = None,
    *,
    public_origin: str | None = None,
) -> tuple[str, str, bool]:
    """Create FedaPay checkout (or AfriOS sandbox mock).

    Returns (payment_url, transaction_ref, is_sandbox_mock).
    """
    transaction_ref = f"AFRI-{invoice.id.hex[:12].upper()}"
    creds = resolve_credentials(business)

    if not creds.configured:
        mock_url = sandbox_checkout_url(
            transaction_ref,
            invoice.total,
            invoice.number,
            public_origin=public_origin,
        )
        return mock_url, transaction_ref, True

    first, *rest = (customer_name or "Client").strip().split(" ", 1)
    last = rest[0] if rest else first
    number, country = _split_phone(customer_phone, getattr(business, "country_code", "SN") if business else "SN")

    payload = {
        "description": f"Facture {invoice.number} — AfriOS",
        "amount": int(invoice.total),
        "currency": {"iso": "XOF"},
        "callback_url": creds.callback_url or settings.fedapay_return_url,
        "custom_metadata": {
            "invoice_id": str(invoice.id),
            "business_id": str(invoice.business_id),
            "afrios_ref": transaction_ref,
            "kind": "invoice",
        },
        "customer": {
            "firstname": first[:80],
            "lastname": last[:80],
            "phone_number": {"number": number, "country": country},
        },
    }

    async with httpx.AsyncClient(timeout=40) as client:
        create_res = await client.post(
            f"{creds.api_base}/transactions",
            headers=_auth_headers(creds),
            json=payload,
        )
        if create_res.status_code >= 400:
            raise ValueError(create_res.json().get("message") or create_res.text[:200])
        data = create_res.json()
        # FedaPay may wrap under "v1/transaction" or return flat
        tx = data.get("v1/transaction") or data.get("transaction") or data
        tx_id = tx.get("id")
        if not tx_id:
            raise ValueError("Réponse FedaPay invalide (id manquant)")

        token_res = await client.post(
            f"{creds.api_base}/transactions/{tx_id}/token",
            headers=_auth_headers(creds),
        )
        if token_res.status_code >= 400:
            raise ValueError(token_res.json().get("message") or token_res.text[:200])
        token_data = token_res.json()
        token_obj = token_data.get("token") or token_data
        payment_url = token_obj.get("url") or token_data.get("url")
        if not payment_url:
            raise ValueError("Lien de paiement FedaPay introuvable")

    return payment_url, f"FEDA-{tx_id}", False


async def create_subscription_payment_link(
    *,
    business: Business,
    plan_id: str,
    amount: int,
    description: str,
    customer_phone: str,
    customer_name: str,
    public_origin: str | None = None,
) -> tuple[str, str, bool]:
    transaction_ref = f"SUB-{plan_id.upper()}-{business.id.hex[:10].upper()}"
    creds = resolve_credentials(business)

    if not creds.configured:
        mock_url = sandbox_checkout_url(
            transaction_ref,
            amount,
            description,
            public_origin=public_origin,
        )
        return mock_url, transaction_ref, True

    first, *rest = (customer_name or business.name or "Marchand").strip().split(" ", 1)
    last = rest[0] if rest else first
    number, country = _split_phone(customer_phone, business.country_code)

    payload = {
        "description": description,
        "amount": int(amount),
        "currency": {"iso": "XOF"},
        "callback_url": creds.callback_url or settings.fedapay_return_url,
        "custom_metadata": {
            "business_id": str(business.id),
            "plan_id": plan_id,
            "afrios_ref": transaction_ref,
            "kind": "subscription",
        },
        "customer": {
            "firstname": first[:80],
            "lastname": last[:80],
            "phone_number": {"number": number, "country": country},
        },
    }

    async with httpx.AsyncClient(timeout=40) as client:
        create_res = await client.post(
            f"{creds.api_base}/transactions",
            headers=_auth_headers(creds),
            json=payload,
        )
        if create_res.status_code >= 400:
            raise ValueError(create_res.json().get("message") or create_res.text[:200])
        data = create_res.json()
        tx = data.get("v1/transaction") or data.get("transaction") or data
        tx_id = tx.get("id")
        if not tx_id:
            raise ValueError("Réponse FedaPay invalide (id manquant)")

        token_res = await client.post(
            f"{creds.api_base}/transactions/{tx_id}/token",
            headers=_auth_headers(creds),
        )
        if token_res.status_code >= 400:
            raise ValueError(token_res.json().get("message") or token_res.text[:200])
        token_data = token_res.json()
        token_obj = token_data.get("token") or token_data
        payment_url = token_obj.get("url") or token_data.get("url")
        if not payment_url:
            raise ValueError("Lien de paiement FedaPay introuvable")

    return payment_url, f"FEDA-{tx_id}", False


async def verify_fedapay_transaction(transaction_ref: str, business: Business | None = None) -> dict:
    creds = resolve_credentials(business)
    if not creds.configured:
        return {"status": "approved", "transaction_id": transaction_ref, "mock": True}

    # Ref format FEDA-{id}
    tx_id = transaction_ref.replace("FEDA-", "").strip()
    if not tx_id.isdigit():
        return {"status": "pending", "transaction_id": transaction_ref}

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{creds.api_base}/transactions/{tx_id}",
            headers=_auth_headers(creds),
        )
        if response.status_code >= 400:
            return {"status": "pending", "raw": response.text[:200]}
        data = response.json()
        tx = data.get("v1/transaction") or data.get("transaction") or data
        return {
            "status": (tx.get("status") or "").lower(),
            "transaction_id": str(tx.get("id") or transaction_ref),
            "amount": tx.get("amount"),
            "raw": tx,
        }


def payment_accepted(verification: dict) -> bool:
    status = (verification.get("status") or "").lower()
    return status in {
        "approved",
        "transferred",
        "accepted",
        "completed",
        "success",
        "paid",
        "00",
    }


# Backward-compatible aliases used by older imports during migration
create_cinetpay_payment_link = create_payment_link
verify_cinetpay_transaction = verify_fedapay_transaction
resolve_cinetpay_credentials = resolve_credentials
