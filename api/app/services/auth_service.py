import logging
import random
import re
from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import Business, OtpCode, User

logger = logging.getLogger(__name__)

# Common West-Africa dial codes for local-number normalization.
_COUNTRY_DIAL = {
    "SN": "221",
    "CI": "225",
    "BF": "226",
    "ML": "223",
    "GN": "224",
    "TG": "228",
    "BJ": "229",
    "NE": "227",
    "GM": "220",
}


def normalize_phone(phone: str, default_country: str = "SN") -> str:
    """Normalize to E.164 (+221… / +225…)."""
    raw = phone.strip()
    digits = re.sub(r"\D", "", raw)
    if not digits:
        raise ValueError("Numéro de téléphone invalide")

    if raw.startswith("+") and len(digits) >= 8:
        return f"+{digits}"

    # Already includes country code without +
    for dial in _COUNTRY_DIAL.values():
        if digits.startswith(dial) and len(digits) >= len(dial) + 7:
            return f"+{digits}"

    dial = _COUNTRY_DIAL.get(default_country.upper(), "221")
    # Drop leading 0 from national numbers (77… / 07…)
    national = digits[1:] if digits.startswith("0") else digits
    if len(national) < 7:
        raise ValueError("Numéro de téléphone trop court")
    return f"+{dial}{national}"


def mask_phone(phone: str) -> str:
    if len(phone) < 6:
        return phone
    return f"{phone[:4]}•••{phone[-3:]}"


async def send_otp(
    db: AsyncSession,
    phone: str,
    *,
    default_country: str = "SN",
) -> tuple[str, str | None, str]:
    """Send OTP via Africa's Talking and/or return a dev code.

    Returns (message, dev_code, channel) where channel is sms | dev | sms+dev.
    """
    phone = normalize_phone(phone, default_country=default_country)
    now = datetime.now(timezone.utc)

    # Rate limit: max N sends / window
    window_start = now - timedelta(minutes=settings.otp_rate_limit_minutes)
    recent = await db.execute(
        select(OtpCode).where(OtpCode.phone == phone, OtpCode.created_at >= window_start)
    )
    if len(recent.scalars().all()) >= settings.otp_rate_limit_max:
        raise ValueError(
            f"Trop de demandes. Réessaie dans {settings.otp_rate_limit_minutes} minutes."
        )

    # Invalidate previous unused codes
    await db.execute(
        update(OtpCode)
        .where(OtpCode.phone == phone, OtpCode.used.is_(False))
        .values(used=True)
    )

    code = f"{random.randint(100000, 999999)}"
    expires = now + timedelta(minutes=settings.otp_expire_minutes)
    db.add(OtpCode(phone=phone, code=code, expires_at=expires, attempts=0))
    await db.flush()

    has_sms_creds = bool(
        settings.africas_talking_api_key.strip() and settings.africas_talking_username.strip()
    )
    sms_ok = False
    sms_error: str | None = None

    if has_sms_creds and not settings.otp_dev_mode:
        try:
            await _send_sms_africas_talking(phone, _otp_message(code))
            sms_ok = True
        except Exception as exc:  # noqa: BLE001
            logger.exception("SMS OTP failed for %s", mask_phone(phone))
            raise ValueError(f"Impossible d'envoyer le SMS : {exc}") from exc
    elif has_sms_creds and settings.otp_dev_mode:
        try:
            await _send_sms_africas_talking(phone, _otp_message(code))
            sms_ok = True
        except Exception as exc:  # noqa: BLE001
            sms_error = str(exc)
            logger.warning("SMS OTP failed (dev fallback): %s", sms_error)

    if not settings.otp_dev_mode and not has_sms_creds:
        raise ValueError(
            "OTP SMS non configuré. Définis AFRICAS_TALKING_API_KEY / USERNAME "
            "ou active OTP_DEV_MODE pour les tests."
        )

    if settings.otp_dev_mode:
        if sms_ok:
            channel = "sms+dev"
            message = f"Code envoyé par SMS à {mask_phone(phone)} (mode dev : code aussi affiché)."
        else:
            channel = "dev"
            hint = f" — SMS: {sms_error}" if sms_error else ""
            message = f"Mode développement : utilise le code affiché{hint}."
        return message, code, channel

    channel = "sms"
    message = f"Code OTP envoyé par SMS à {mask_phone(phone)}"
    return message, None, channel


def _otp_message(code: str) -> str:
    return (
        f"AfriOS : votre code est {code}. "
        f"Valable {settings.otp_expire_minutes} min. Ne le partagez pas."
    )


async def _send_sms_africas_talking(phone: str, message: str) -> None:
    url = "https://api.africastalking.com/version1/messaging"
    headers = {
        "apiKey": settings.africas_talking_api_key,
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    }
    data: dict[str, str] = {
        "username": settings.africas_talking_username,
        "to": phone,
        "message": message,
    }
    sender = settings.africas_talking_sender.strip()
    if sender:
        data["from"] = sender

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, headers=headers, data=data)

    if response.status_code >= 400:
        raise RuntimeError(f"Africa's Talking HTTP {response.status_code}: {response.text[:200]}")

    payload = response.json()
    # Typical shape: {"SMSMessageData": {"Recipients": [{"statusCode": 101, "status": "Success"}]}}
    recipients = (payload.get("SMSMessageData") or {}).get("Recipients") or []
    if recipients:
        status_code = recipients[0].get("statusCode")
        # 100–199 ≈ accepted/queued/sent
        if isinstance(status_code, int) and status_code >= 200:
            raise RuntimeError(recipients[0].get("status") or "Échec envoi SMS")
    elif "errorMessage" in payload:
        raise RuntimeError(payload["errorMessage"])


async def verify_otp(db: AsyncSession, phone: str, code: str, *, default_country: str = "SN") -> User:
    phone = normalize_phone(phone, default_country=default_country)
    now = datetime.now(timezone.utc)
    code = code.strip()

    result = await db.execute(
        select(OtpCode)
        .where(OtpCode.phone == phone, OtpCode.used.is_(False))
        .order_by(OtpCode.created_at.desc())
    )
    otp = result.scalars().first()
    if not otp:
        raise ValueError("Aucun code actif. Demande un nouveau code.")

    expires = otp.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < now:
        otp.used = True
        raise ValueError("Code OTP expiré. Demande un nouveau code.")

    if otp.attempts >= settings.otp_max_attempts:
        otp.used = True
        raise ValueError("Trop de tentatives. Demande un nouveau code.")

    if otp.code != code:
        otp.attempts += 1
        remaining = settings.otp_max_attempts - otp.attempts
        if remaining <= 0:
            otp.used = True
            raise ValueError("Code incorrect. Demande un nouveau code.")
        raise ValueError(f"Code incorrect. {remaining} tentative(s) restante(s).")

    otp.used = True

    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()
    if not user:
        user = User(phone=phone)
        db.add(user)
        await db.flush()

    return user


async def get_user_business(db: AsyncSession, user: User) -> Business | None:
    result = await db.execute(select(Business).where(Business.owner_id == user.id))
    return result.scalar_one_or_none()
