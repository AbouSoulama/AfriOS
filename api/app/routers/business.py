from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business, get_current_user
from app.models import Business, User
from app.schemas import BusinessCreate, BusinessResponse, BusinessUpdate

router = APIRouter(prefix="/business", tags=["business"])


@router.get("", response_model=BusinessResponse)
async def get_business(business: Business = Depends(get_current_business)):
    return business


@router.post("", response_model=BusinessResponse)
async def create_business(
    body: BusinessCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Business).where(Business.owner_id == user.id))
    existing = result.scalar_one_or_none()
    if existing:
        existing.name = body.name
        existing.sector = body.sector
        existing.currency = body.currency
        existing.country_code = body.country_code
        existing.tax_rate = body.tax_rate
        await db.flush()
        return existing

    business = Business(
        owner_id=user.id,
        name=body.name,
        sector=body.sector,
        currency=body.currency,
        country_code=body.country_code,
        tax_rate=body.tax_rate,
    )
    db.add(business)
    await db.flush()
    return business


@router.put("", response_model=BusinessResponse)
async def update_business(
    body: BusinessUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(business, field, value)
    await db.flush()
    return business


@router.post("/onboarding/complete", response_model=BusinessResponse)
async def complete_onboarding(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    business.onboarding_completed = True
    await db.flush()
    return business
