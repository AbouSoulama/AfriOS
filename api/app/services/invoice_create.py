from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, Client, Invoice, InvoiceItem, InvoiceStatus, Product
from app.services.invoice_service import calculate_invoice_totals, next_invoice_number


async def create_invoice_from_payload(
    db: AsyncSession,
    business: Business,
    payload: dict,
    *,
    client_id: UUID | None = None,
) -> Invoice:
    """Shared invoice creation for HTTP create + offline sync push."""
    resolved_client_id = client_id
    if resolved_client_id is None:
        raw = payload.get("client_id")
        if not raw:
            raise ValueError("client_id requis")
        resolved_client_id = UUID(str(raw))

    client_result = await db.execute(
        select(Client).where(Client.id == resolved_client_id, Client.business_id == business.id)
    )
    client = client_result.scalar_one_or_none()
    if not client:
        raise ValueError("Client introuvable")

    items_raw = payload.get("items") or []
    if not items_raw:
        raise ValueError("Au moins une ligne requise")

    items_data = []
    for item in items_raw:
        items_data.append(
            {
                "description": item.get("description") or "Article",
                "quantity": int(item.get("quantity") or 1),
                "unit_price": Decimal(str(item.get("unit_price") or 0)),
                "discount": Decimal(str(item.get("discount") or 0)),
                "product_id": item.get("product_id"),
            }
        )

    subtotal, tax, total = calculate_invoice_totals(items_data, business.tax_rate)
    number = await next_invoice_number(db, business.id)

    due_raw = payload.get("due_date")
    due_date = None
    if due_raw:
        if isinstance(due_raw, str):
            due_date = datetime.fromisoformat(due_raw.replace("Z", "+00:00")).date()
        else:
            due_date = due_raw

    invoice = Invoice(
        business_id=business.id,
        client_id=client.id,
        number=number,
        status=InvoiceStatus.draft,
        subtotal=subtotal,
        tax=tax,
        total=total,
        notes=payload.get("notes"),
        due_date=due_date,
    )
    db.add(invoice)
    await db.flush()

    for item in items_data:
        product_id = item.get("product_id")
        parsed_product_id = None
        if product_id and not str(product_id).startswith("local-"):
            try:
                parsed_product_id = UUID(str(product_id))
            except ValueError:
                parsed_product_id = None

        qty = item["quantity"]
        line_total = qty * item["unit_price"] - item["discount"]
        db.add(
            InvoiceItem(
                invoice_id=invoice.id,
                product_id=parsed_product_id,
                description=item["description"],
                quantity=qty,
                unit_price=item["unit_price"],
                discount=item["discount"],
                line_total=line_total,
            )
        )

        if parsed_product_id:
            prod_result = await db.execute(
                select(Product).where(Product.id == parsed_product_id, Product.business_id == business.id)
            )
            product = prod_result.scalar_one_or_none()
            if product:
                product.quantity = max(0, product.quantity - qty)

    await db.flush()
    return invoice
