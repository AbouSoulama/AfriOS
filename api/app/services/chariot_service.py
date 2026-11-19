"""Chariot Mobile Money — encaissement clients + abonnements AfriOS.

Sans clés commerçant / plateforme, le mode sandbox AfriOS simule le paiement
(uniquement si CHARIOT_SANDBOX=true). Branche l'API live dès que les endpoints
Chariot sont connus (CHARIOT_API_BASE + clés).
"""

from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlencode, urlparse, urlunparse

import httpx

from app.config import settings
from app.models import Business, Invoice


@dataclass
class ChariotCredentials:
    secret_key: str
    public_key: str
    sandbox: bool
    callback_url: str
    return_url: str
    api_base: str

    @property
    def configured(self) -> bool:
        return bool(self.secret_key.strip())


class PaymentConfigError(ValueError):
    """Mobile Money non configuré (action requise côté commerçant / serveur)."""


def mock_allowed() -> bool:
    return bool(settings.chariot_sandbox)


def _business_secret(business: Business | None) -> str:
    if not business:
        return ""
    return (
        (getattr(business, "chariot_secret_key", None) or "").strip()
        or (getattr(business, "fedapay_secret_key", None) or "").strip()
    )


def _business_public(business: Business | None) -> str:
    if not business:
        return ""
    return (
        (getattr(business, "chariot_public_key", None) or "").strip()
        or (getattr(business, "fedapay_public_key", None) or "").strip()
    )


def resolve_credentials(
    business: Business | None = None, *, scope: str = "invoice"
) -> ChariotCredentials:
    """Choisit les clés Chariot selon QUI doit recevoir l'argent.

    - scope="invoice"      : le client paie le COMMERÇANT
    - scope="subscription" : le commerçant paie AFRIOS
    """
    if scope == "subscription":
        secret = (settings.chariot_secret_key or "").strip()
        public = (settings.chariot_public_key or "").strip()
    else:
        secret = _business_secret(business)
        public = _business_public(business)
    return ChariotCredentials(
        secret_key=secret,
        public_key=public,
        sandbox=settings.chariot_sandbox,
        callback_url=settings.chariot_callback_url,
        return_url=settings.chariot_return_url,
        api_base=(settings.chariot_api_base or "").rstrip("/")
        or "https://api.chariot.pay/v1",
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
    callback_origin = _origin_from_url(settings.chariot_callback_url)

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
    query = urlencode({"ref": transaction_id, "amount": amount, "invoice": invoice_number})
    return f"{origin}/v1/payments/sandbox/checkout?{query}"


def _split_phone(phone: str, country_code: str = "BF") -> tuple[str, str]:
    digits = "".join(c for c in (phone or "") if c.isdigit())
    country = (country_code or "BF").upper()
    dial = {
        "SN": "221",
        "CI": "225",
        "BJ": "229",
        "TG": "228",
        "BF": "226",
        "ML": "223",
        "NE": "227",
        "GN": "224",
        "GM": "220",
    }.get(country, "226")
    iso = country.lower()
    if digits.startswith(dial) and len(digits) > len(dial):
        return digits[len(dial) :], iso
    if digits.startswith("0"):
        digits = digits[1:]
    return digits or "00000000", iso


def _auth_headers(creds: ChariotCredentials) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {creds.secret_key}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-Public-Key": creds.public_key,
    }


async def _create_live_checkout(
    *,
    creds: ChariotCredentials,
    amount: int,
    description: str,
    customer_name: str,
    customer_phone: str,
    country_code: str,
    metadata: dict,
) -> tuple[str, str]:
    """Appel API Chariot live. Adapte CHARIOT_API_BASE / payload dès que la doc est dispo."""
    first, *rest = (customer_name or "Client").strip().split(" ", 1)
    last = rest[0] if rest else first
    number, country = _split_phone(customer_phone, country_code)

    payload = {
        "description": description,
        "amount": int(amount),
        "currency": "XOF",
        "callback_url": creds.callback_url or settings.chariot_return_url,
        "return_url": creds.return_url,
        "metadata": metadata,
        "customer": {
            "firstname": first[:80],
            "lastname": last[:80],
            "phone": number,
            "country": country,
        },
    }

    async with httpx.AsyncClient(timeout=40) as client:
        create_res = await client.post(
            f"{creds.api_base}/payments",
            headers=_auth_headers(creds),
            json=payload,
        )
        if create_res.status_code >= 400:
            detail = create_res.text[:200]
            try:
                detail = create_res.json().get("message") or create_res.json().get("error") or detail
            except Exception:  # noqa: BLE001
                pass
            raise ValueError(f"Chariot : {detail}")

        data = create_res.json()
        payment = data.get("payment") or data.get("data") or data
        payment_id = str(payment.get("id") or payment.get("reference") or "")
        payment_url = (
            payment.get("checkout_url")
            or payment.get("payment_url")
            or payment.get("url")
            or data.get("checkout_url")
            or data.get("url")
        )
        if not payment_id or not payment_url:
            raise ValueError(
                "Réponse Chariot inattendue (id ou lien manquant). "
                "Vérifie CHARIOT_API_BASE et le format de l'API."
            )
    return payment_url, f"CHARIOT-{payment_id}"


async def create_payment_link(
    invoice: Invoice,
    customer_name: str,
    customer_phone: str,
    business: Business | None = None,
    *,
    public_origin: str | None = None,
) -> tuple[str, str, bool]:
    """Crée un lien Chariot (ou page sandbox AfriOS).

    Returns (payment_url, transaction_ref, is_sandbox_mock).
    """
    transaction_ref = f"AFRI-{invoice.id.hex[:12].upper()}"
    creds = resolve_credentials(business, scope="invoice")

    if not creds.configured:
        if not mock_allowed():
            raise PaymentConfigError(
                "Mobile Money non configuré : ajoute tes clés Chariot dans "
                "Paramètres → Encaissement clients pour que tes clients puissent payer en ligne."
            )
        mock_url = sandbox_checkout_url(
            transaction_ref,
            invoice.total,
            invoice.number,
            public_origin=public_origin,
        )
        return mock_url, transaction_ref, True

    if creds.sandbox:
        # Clés présentes mais sandbox : on simule toujours (évite d'appeler une API inconnue).
        mock_url = sandbox_checkout_url(
            transaction_ref,
            invoice.total,
            invoice.number,
            public_origin=public_origin,
        )
        return mock_url, transaction_ref, True

    url, ref = await _create_live_checkout(
        creds=creds,
        amount=int(invoice.total),
        description=f"Facture {invoice.number} — AfriOS",
        customer_name=customer_name,
        customer_phone=customer_phone,
        country_code=getattr(business, "country_code", "BF") if business else "BF",
        metadata={
            "invoice_id": str(invoice.id),
            "business_id": str(invoice.business_id),
            "afrios_ref": transaction_ref,
            "kind": "invoice",
        },
    )
    return url, ref, False


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
    creds = resolve_credentials(business, scope="subscription")

    if not creds.configured or creds.sandbox:
        if not mock_allowed() and not creds.configured:
            raise PaymentConfigError(
                "Le paiement des abonnements AfriOS n'est pas encore activé. Réessaie plus tard."
            )
        mock_url = sandbox_checkout_url(
            transaction_ref,
            amount,
            description,
            public_origin=public_origin,
        )
        return mock_url, transaction_ref, True

    url, ref = await _create_live_checkout(
        creds=creds,
        amount=int(amount),
        description=description,
        customer_name=customer_name or business.name or "Marchand",
        customer_phone=customer_phone,
        country_code=business.country_code or "BF",
        metadata={
            "business_id": str(business.id),
            "plan_id": plan_id,
            "afrios_ref": transaction_ref,
            "kind": "subscription",
        },
    )
    return url, ref, False


async def verify_chariot_transaction(
    transaction_ref: str,
    business: Business | None = None,
    *,
    scope: str = "invoice",
) -> dict:
    creds = resolve_credentials(business, scope=scope)
    if not creds.configured or creds.sandbox:
        return {"status": "pending", "transaction_id": transaction_ref, "mock": True}

    payment_id = transaction_ref.replace("CHARIOT-", "").strip()
    if not payment_id:
        return {"status": "pending", "transaction_id": transaction_ref}

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{creds.api_base}/payments/{payment_id}",
            headers=_auth_headers(creds),
        )
        if response.status_code >= 400:
            return {"status": "pending", "raw": response.text[:200]}
        data = response.json()
        payment = data.get("payment") or data.get("data") or data
        return {
            "status": (payment.get("status") or "").lower(),
            "transaction_id": str(payment.get("id") or transaction_ref),
            "amount": payment.get("amount"),
            "raw": payment,
        }


def transaction_metadata(verification: dict) -> dict:
    raw = verification.get("raw") or {}
    meta = raw.get("metadata") or raw.get("custom_metadata") or {}
    return meta if isinstance(meta, dict) else {}


def payment_accepted(verification: dict) -> bool:
    if verification.get("mock"):
        return False
    status = (verification.get("status") or "").lower()
    return status in {
        "approved",
        "transferred",
        "accepted",
        "completed",
        "success",
        "paid",
        "successful",
        "00",
    }


# Alias de migration (anciens imports FedaPay / CinetPay)
verify_fedapay_transaction = verify_chariot_transaction
create_cinetpay_payment_link = create_payment_link
verify_cinetpay_transaction = verify_chariot_transaction
resolve_cinetpay_credentials = resolve_credentials
