from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_business
from app.models import Business, Client, Invoice
from app.schemas import ReminderRuleUpdate, ReminderSendResponse
from app.services.reminder_service import get_or_create_reminder_rule, get_overdue_invoices, send_manual_reminder

router = APIRouter(prefix="/reminders", tags=["reminders"])


@router.get("/overdue")
async def overdue_list(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    rows = await get_overdue_invoices(db, business.id)
    return [
        {
            "invoice_id": str(inv.id),
            "invoice_number": inv.number,
            "client_name": client.name,
            "client_phone": client.phone,
            "total": float(inv.total),
            "due_date": str(inv.due_date) if inv.due_date else None,
        }
        for inv, client in rows
    ]


@router.post("/{invoice_id}/send", response_model=ReminderSendResponse)
async def send_reminder(
    invoice_id: UUID,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Invoice, Client)
        .join(Client, Invoice.client_id == Client.id)
        .where(Invoice.id == invoice_id, Invoice.business_id == business.id)
    )
    row = result.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Facture introuvable")
    invoice, client = row

    message, wa_url = await send_manual_reminder(db, business, invoice, client)
    return ReminderSendResponse(message=message, whatsapp_url=wa_url)


@router.get("/rules")
async def get_rules(business: Business = Depends(get_current_business), db: AsyncSession = Depends(get_db)):
    rule = await get_or_create_reminder_rule(db, business.id)
    return {
        "enabled": rule.enabled,
        "days_after_due": rule.days_after_due,
        "message_template": rule.message_template,
    }


@router.put("/rules")
async def update_rules(
    body: ReminderRuleUpdate,
    business: Business = Depends(get_current_business),
    db: AsyncSession = Depends(get_db),
):
    rule = await get_or_create_reminder_rule(db, business.id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(rule, field, value)
    await db.flush()
    return {
        "enabled": rule.enabled,
        "days_after_due": rule.days_after_due,
        "message_template": rule.message_template,
    }
