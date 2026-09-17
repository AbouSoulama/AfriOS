"""Re-export FedaPay helpers under legacy CinetPay names (migration)."""

from app.services.fedapay_service import (  # noqa: F401
    create_payment_link,
    payment_accepted,
    public_api_origin,
    resolve_credentials,
    sandbox_checkout_url,
    verify_fedapay_transaction as verify_cinetpay_transaction,
)
