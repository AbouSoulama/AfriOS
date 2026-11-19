"""Compatibilité : réexporte Chariot sous les anciens noms FedaPay."""

from app.services.chariot_service import (  # noqa: F401
    PaymentConfigError,
    create_payment_link,
    create_subscription_payment_link,
    mock_allowed,
    payment_accepted,
    public_api_origin,
    resolve_credentials,
    sandbox_checkout_url,
    transaction_metadata,
    verify_chariot_transaction as verify_fedapay_transaction,
)
