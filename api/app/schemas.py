from datetime import datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AfriModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# Auth
class OtpSendRequest(BaseModel):
    phone: str = Field(..., min_length=8, max_length=20)
    country_code: str | None = Field(default=None, max_length=2)


class OtpSendResponse(BaseModel):
    message: str
    dev_code: str | None = None
    channel: str = "dev"
    expires_in_seconds: int = 300
    phone_masked: str | None = None


class OtpVerifyRequest(BaseModel):
    phone: str
    code: str = Field(..., min_length=4, max_length=6)
    country_code: str | None = Field(default=None, max_length=2)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: UUID
    business_id: UUID | None = None
    onboarding_completed: bool = False


# Business
class BusinessCreate(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    sector: str | None = None
    currency: str = "XOF"
    country_code: str = "SN"
    tax_rate: Decimal = Decimal("0")


class BusinessUpdate(BaseModel):
    name: str | None = None
    sector: str | None = None
    currency: str | None = None
    country_code: str | None = None
    tax_rate: Decimal | None = None
    logo_url: str | None = None


class BusinessResponse(AfriModel):
    id: UUID
    name: str
    sector: str | None
    currency: str
    country_code: str
    tax_rate: Decimal
    logo_url: str | None
    onboarding_completed: bool


# Clients
class ClientCreate(BaseModel):
    name: str
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    notes: str | None = None
    client_op_id: str | None = None


class ClientUpdate(BaseModel):
    name: str | None = None
    phone: str | None = None
    email: str | None = None
    address: str | None = None
    notes: str | None = None


class ClientResponse(AfriModel):
    id: UUID
    name: str
    phone: str | None
    email: str | None
    address: str | None
    notes: str | None
    created_at: datetime
    total_invoiced: Decimal | None = None
    amount_due: Decimal | None = None


# Products
class ProductCreate(BaseModel):
    name: str
    price: Decimal = Decimal("0")
    quantity: int = 0
    low_stock_threshold: int = 5
    category: str | None = None


class ProductUpdate(BaseModel):
    name: str | None = None
    price: Decimal | None = None
    quantity: int | None = None
    low_stock_threshold: int | None = None
    category: str | None = None


class ProductResponse(AfriModel):
    id: UUID
    name: str
    price: Decimal
    quantity: int
    low_stock_threshold: int
    category: str | None
    is_low_stock: bool = False


class StockMovementCreate(BaseModel):
    type: str
    quantity: int
    reason: str | None = None


# Invoices
class InvoiceItemCreate(BaseModel):
    product_id: UUID | None = None
    description: str
    quantity: int = 1
    unit_price: Decimal
    discount: Decimal = Decimal("0")


class InvoiceCreate(BaseModel):
    client_id: UUID
    items: list[InvoiceItemCreate]
    notes: str | None = None
    due_date: datetime | None = None
    client_op_id: str | None = None


class InvoiceItemResponse(AfriModel):
    id: UUID
    description: str
    quantity: int
    unit_price: Decimal
    discount: Decimal
    line_total: Decimal
    product_id: UUID | None


class InvoiceResponse(AfriModel):
    id: UUID
    number: str
    status: str
    client_id: UUID
    client_name: str | None = None
    subtotal: Decimal
    tax: Decimal
    total: Decimal
    notes: str | None
    due_date: datetime | None
    payment_link: str | None
    created_at: datetime
    items: list[InvoiceItemResponse] = []


class InvoiceSendResponse(BaseModel):
    invoice: InvoiceResponse
    pdf_url: str | None
    payment_link: str | None
    whatsapp_message: str


# Payments
class PaymentInitiateRequest(BaseModel):
    invoice_id: UUID


class PaymentVerifyRequest(BaseModel):
    transaction_id: str | None = None
    invoice_id: UUID | None = None


class PaymentResponse(AfriModel):
    id: UUID
    invoice_id: UUID
    method: str
    amount: Decimal
    status: str
    external_ref: str | None
    created_at: datetime


class PaymentSettingsUpdate(BaseModel):
    site_id: str | None = None
    api_key: str | None = None
    enabled: bool | None = None
    clear_api_key: bool = False


class PaymentSettingsResponse(BaseModel):
    site_id: str | None
    api_key_set: bool
    enabled: bool
    sandbox_mode: bool
    using_platform_keys: bool
    notify_url: str
    return_url: str


class MarkPaidRequest(BaseModel):
    method: str = "cash"
    amount: Decimal | None = None


# Dashboard
class DashboardSummary(BaseModel):
    revenue_today: Decimal
    revenue_month: Decimal
    revenue_change_percent: float
    pending_invoices_count: int
    pending_invoices_total: Decimal
    low_stock_count: int
    overdue_count: int


# AI
class AiChatRequest(BaseModel):
    message: str
    conversation_id: UUID | None = None
    confirm_action: bool = False
    action_payload: dict[str, Any] | None = None


class AiChatResponse(BaseModel):
    conversation_id: UUID
    message: str
    intent: str | None = None
    suggestions: list[str] = []
    action: dict[str, Any] | None = None


# Reminders
class ReminderSendResponse(BaseModel):
    message: str
    whatsapp_url: str | None


class ReminderRuleUpdate(BaseModel):
    enabled: bool | None = None
    days_after_due: list[int] | None = None
    message_template: str | None = None


# Sync
class SyncOperationItem(BaseModel):
    client_op_id: str
    entity_type: str
    operation: str
    payload: dict[str, Any]


class SyncPushRequest(BaseModel):
    operations: list[SyncOperationItem]


class SyncPullResponse(BaseModel):
    clients: list[ClientResponse]
    products: list[ProductResponse]
    invoices: list[InvoiceResponse]
    server_time: datetime


# Notifications
class NotificationResponse(AfriModel):
    id: UUID
    type: str
    title: str
    body: str
    read: bool
    data: dict[str, Any]
    created_at: datetime


class FcmTokenRequest(BaseModel):
    token: str
    platform: str = "android"
