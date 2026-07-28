from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business
from app.models import Business, Client, Invoice, InvoiceStatus
from app.schemas import ClientCreate, ClientResponse, ClientUpdate

router = APIRouter(prefix="/clients", tags=["clients"])


async def _enrich_client(db: AsyncSession, client: Client) -> ClientResponse:
    invoiced = await db.execute(
        select(func.coalesce(func.sum(Invoice.total), 0)).where(Invoice.client_id == client.id)
    )
    due = await db.execute(
        select(func.coalesce(func.sum(Invoice.total), 0)).where(
            Invoice.client_id == client.id,
            Invoice.status.in_([InvoiceStatus.sent, InvoiceStatus.overdue]),
        )
    )
    return ClientResponse(
        id=client.id,
        name=client.name,
        phone=client.phone,
        email=client.email,
        address=client.address,
        notes=client.notes,
        created_at=client.created_at,
        total_invoiced=invoiced.scalar(),
        amount_due=due.scalar(),
    )


@router.get("", response_model=list[ClientResponse])
async def list_clients(
    q: str | None = Query(None),
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Client).where(Client.business_id == business.id)
    if q:
        stmt = stmt.where(or_(Client.name.ilike(f"%{q}%"), Client.phone.ilike(f"%{q}%")))
    stmt = stmt.order_by(Client.name)
    result = await db.execute(stmt)
    clients = result.scalars().all()
    return [await _enrich_client(db, c) for c in clients]


@router.post("", response_model=ClientResponse)
async def create_client(
    body: ClientCreate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    client = Client(business_id=business.id, **body.model_dump(exclude={"client_op_id"}))
    db.add(client)
    await db.flush()
    return await _enrich_client(db, client)


@router.get("/{client_id}", response_model=ClientResponse)
async def get_client(
    client_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    client = await _get_client(db, business.id, client_id)
    return await _enrich_client(db, client)


@router.put("/{client_id}", response_model=ClientResponse)
async def update_client(
    client_id: UUID,
    body: ClientUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    client = await _get_client(db, business.id, client_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(client, field, value)
    await db.flush()
    return await _enrich_client(db, client)


@router.delete("/{client_id}")
async def delete_client(
    client_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    client = await _get_client(db, business.id, client_id)
    await db.delete(client)
    return {"message": "Client supprimé"}


async def _get_client(db, business_id, client_id) -> Client:
    result = await db.execute(
        select(Client).where(Client.id == client_id, Client.business_id == business_id)
    )
    client = result.scalar_one_or_none()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")
    return client
