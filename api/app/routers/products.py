from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business
from app.models import Business, Product, StockMovement, StockMovementType
from app.schemas import ProductCreate, ProductResponse, ProductUpdate, StockMovementCreate

router = APIRouter(prefix="/products", tags=["products"])


def _to_response(p: Product) -> ProductResponse:
    return ProductResponse(
        id=p.id,
        name=p.name,
        price=p.price,
        quantity=p.quantity,
        low_stock_threshold=p.low_stock_threshold,
        category=p.category,
        is_low_stock=p.quantity <= p.low_stock_threshold,
    )


@router.get("", response_model=list[ProductResponse])
async def list_products(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Product).where(Product.business_id == business.id).order_by(Product.name))
    return [_to_response(p) for p in result.scalars().all()]


@router.get("/low-stock", response_model=list[ProductResponse])
async def low_stock(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Product).where(
            Product.business_id == business.id,
            Product.quantity <= Product.low_stock_threshold,
        )
    )
    return [_to_response(p) for p in result.scalars().all()]


@router.post("", response_model=ProductResponse)
async def create_product(
    body: ProductCreate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    product = Product(business_id=business.id, **body.model_dump())
    db.add(product)
    await db.flush()
    return _to_response(product)


@router.put("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: UUID,
    body: ProductUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    product = await _get_product(db, business.id, product_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(product, field, value)
    await db.flush()
    return _to_response(product)


@router.delete("/{product_id}")
async def delete_product(
    product_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    product = await _get_product(db, business.id, product_id)
    await db.delete(product)
    return {"message": "Produit supprimé"}


@router.post("/{product_id}/movements", response_model=ProductResponse)
async def add_movement(
    product_id: UUID,
    body: StockMovementCreate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    product = await _get_product(db, business.id, product_id)
    movement_type = StockMovementType.in_ if body.type == "in" else StockMovementType(body.type)
    if movement_type == StockMovementType.in_:
        product.quantity += body.quantity
    elif movement_type == StockMovementType.out:
        product.quantity = max(0, product.quantity - body.quantity)
    else:
        product.quantity = body.quantity

    db.add(StockMovement(
        product_id=product.id,
        business_id=business.id,
        type=movement_type,
        quantity=body.quantity,
        reason=body.reason,
    ))
    await db.flush()
    return _to_response(product)


async def _get_product(db, business_id, product_id) -> Product:
    result = await db.execute(
        select(Product).where(Product.id == product_id, Product.business_id == business_id)
    )
    product = result.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Produit introuvable")
    return product
