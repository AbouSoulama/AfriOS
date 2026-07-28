import random
import re
from datetime import datetime, timedelta, timezone

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import Business, OtpCode, User


def normalize_phone(phone: str) -> str:
    return re.sub(r"[^\d+]", "", phone.strip())


async def send_otp(db: AsyncSession, phone: str) -> tuple[str, str | None]:
    phone = normalize_phone(phone)
    code = f"{random.randint(100000, 999999)}"
    expires = datetime.now(timezone.utc) + timedelta(minutes=settings.otp_expire_minutes)

    db.add(OtpCode(phone=phone, code=code, expires_at=expires))
    await db.flush()

    dev_code = None
    if settings.otp_dev_mode:
        dev_code = code
    elif settings.africas_talking_api_key:
        await _send_sms_africas_talking(phone, f"Votre code AfriOS : {code}")

    return "Code OTP envoyé", dev_code


async def _send_sms_africas_talking(phone: str, message: str) -> None:
    url = "https://api.africastalking.com/version1/messaging"
    headers = {"apiKey": settings.africas_talking_api_key, "Accept": "application/json"}
    data = {"username": settings.africas_talking_username, "to": phone, "message": message}
    async with httpx.AsyncClient() as client:
        await client.post(url, headers=headers, data=data)


async def verify_otp(db: AsyncSession, phone: str, code: str) -> User:
    phone = normalize_phone(phone)
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(OtpCode)
        .where(OtpCode.phone == phone, OtpCode.code == code, OtpCode.used == False)  # noqa: E712
        .order_by(OtpCode.created_at.desc())
    )
    otp = result.scalar_one_or_none()
    if not otp or otp.expires_at.replace(tzinfo=timezone.utc) < now:
        raise ValueError("Code OTP invalide ou expiré")

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
