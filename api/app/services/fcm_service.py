from app.config import settings


async def send_push_notification(token: str, title: str, body: str, data: dict | None = None) -> bool:
    if not settings.firebase_credentials_path:
        return False

    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.firebase_credentials_path)
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            token=token,
        )
        messaging.send(message)
        return True
    except Exception:
        return False


async def notify_business_payment(user_tokens: list[str], amount: str, invoice_number: str) -> int:
    sent = 0
    title = "Paiement reçu"
    body = f"Facture {invoice_number} — +{amount} FCFA"
    for token in user_tokens:
        if await send_push_notification(token, title, body, {"type": "payment", "invoice": invoice_number}):
            sent += 1
    return sent
