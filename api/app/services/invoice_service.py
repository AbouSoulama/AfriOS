import io
import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models import Business, Client, Invoice, InvoiceItem


def generate_invoice_pdf(
    invoice: Invoice,
    business: Business,
    client: Client,
    items: list[InvoiceItem],
) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, rightMargin=2 * cm, leftMargin=2 * cm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("Title", parent=styles["Heading1"], textColor=colors.HexColor("#0D9488"))
    elements = []

    elements.append(Paragraph(f"FACTURE {invoice.number}", title_style))
    elements.append(Spacer(1, 12))
    elements.append(Paragraph(f"<b>{business.name}</b>", styles["Normal"]))
    if business.sector:
        elements.append(Paragraph(business.sector, styles["Normal"]))
    elements.append(Spacer(1, 20))
    elements.append(Paragraph(f"<b>Client :</b> {client.name}", styles["Normal"]))
    if client.phone:
        elements.append(Paragraph(f"Tél : {client.phone}", styles["Normal"]))
    elements.append(Spacer(1, 20))

    data = [["Description", "Qté", "Prix unit.", "Total"]]
    for item in items:
        data.append([
            item.description,
            str(item.quantity),
            f"{item.unit_price:,.0f}",
            f"{item.line_total:,.0f}",
        ])

    table = Table(data, colWidths=[8 * cm, 2 * cm, 3 * cm, 3 * cm])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0D9488")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ALIGN", (1, 1), (-1, -1), "RIGHT"),
    ]))
    elements.append(table)
    elements.append(Spacer(1, 20))

    currency = business.currency or "FCFA"
    elements.append(Paragraph(f"Sous-total : {invoice.subtotal:,.0f} {currency}", styles["Normal"]))
    if invoice.tax > 0:
        elements.append(Paragraph(f"TVA ({business.tax_rate}%) : {invoice.tax:,.0f} {currency}", styles["Normal"]))
    elements.append(Paragraph(f"<b>TOTAL : {invoice.total:,.0f} {currency}</b>", styles["Heading2"]))

    if invoice.notes:
        elements.append(Spacer(1, 12))
        elements.append(Paragraph(f"Notes : {invoice.notes}", styles["Italic"]))

    elements.append(Spacer(1, 30))
    elements.append(Paragraph("Généré par AfriOS — L'OS des PME africaines", styles["Normal"]))

    doc.build(elements)
    return buffer.getvalue()


def build_whatsapp_message(invoice: Invoice, client: Client, business: Business, payment_link: str | None) -> str:
    msg = (
        f"Bonjour {client.name},\n\n"
        f"Voici votre facture *{invoice.number}* de *{business.name}*.\n"
        f"Montant : *{invoice.total:,.0f} {business.currency}*\n"
    )
    if payment_link:
        msg += f"\nPayer en ligne : {payment_link}\n"
    msg += "\nMerci !"
    return msg


def whatsapp_share_url(phone: str, message: str) -> str:
    from urllib.parse import quote
    clean_phone = "".join(c for c in phone if c.isdigit())
    return f"https://wa.me/{clean_phone}?text={quote(message)}"


async def next_invoice_number(db, business_id: uuid.UUID) -> str:
    from sqlalchemy import select
    from app.models import InvoiceSequence

    result = await db.execute(select(InvoiceSequence).where(InvoiceSequence.business_id == business_id))
    seq = result.scalar_one_or_none()
    if not seq:
        seq = InvoiceSequence(business_id=business_id, last_number=0)
        db.add(seq)
        await db.flush()
    seq.last_number += 1
    return f"#{seq.last_number:03d}"


def calculate_invoice_totals(items: list[dict], tax_rate: Decimal) -> tuple[Decimal, Decimal, Decimal]:
    subtotal = Decimal("0")
    for item in items:
        qty = Decimal(str(item["quantity"]))
        price = Decimal(str(item["unit_price"]))
        discount = Decimal(str(item.get("discount", 0)))
        line = qty * price - discount
        subtotal += line
    tax = subtotal * tax_rate / Decimal("100")
    total = subtotal + tax
    return subtotal, tax, total
