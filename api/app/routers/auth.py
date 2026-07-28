from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import create_access_token
from app.schemas import OtpSendRequest, OtpSendResponse, OtpVerifyRequest, TokenResponse
from app.services.auth_service import get_user_business, send_otp, verify_otp

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/otp/send", response_model=OtpSendResponse)
async def otp_send(body: OtpSendRequest, db: AsyncSession = Depends(get_db)):
    message, dev_code = await send_otp(db, body.phone)
    return OtpSendResponse(message=message, dev_code=dev_code)


@router.post("/otp/verify", response_model=TokenResponse)
async def otp_verify(body: OtpVerifyRequest, db: AsyncSession = Depends(get_db)):
    try:
        user = await verify_otp(db, body.phone, body.code)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e

    business = await get_user_business(db, user)
    token = create_access_token(user.id, business.id if business else None)
    return TokenResponse(
        access_token=token,
        user_id=user.id,
        business_id=business.id if business else None,
        onboarding_completed=business.onboarding_completed if business else False,
    )


@router.delete("/logout")
async def logout():
    return {"message": "Déconnexion réussie"}
