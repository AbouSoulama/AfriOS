from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def normalize_database_url(value: str) -> str:
    """Make Render/Heroku Postgres URLs work with SQLAlchemy asyncpg.

    - postgres:// → postgresql+asyncpg://
    - drop sslmode (asyncpg does not understand it)
    - keep sqlite URLs unchanged
    """
    raw = value.strip().strip('"').strip("'")
    if not raw:
        return raw
    if raw.startswith("sqlite"):
        return raw

    if raw.startswith("postgres://"):
        raw = "postgresql+asyncpg://" + raw[len("postgres://") :]
    elif raw.startswith("postgresql://"):
        raw = "postgresql+asyncpg://" + raw[len("postgresql://") :]

    parsed = urlparse(raw)
    query = [(k, v) for k, v in parse_qsl(parsed.query, keep_blank_values=True) if k.lower() != "sslmode"]
    return urlunparse(parsed._replace(query=urlencode(query)))


def database_host(url: str) -> str:
    return urlparse(url).hostname or ""


def is_local_database(url: str) -> bool:
    """True for SQLite / local Docker / compose services (no TLS required)."""
    if url.startswith("sqlite"):
        return True
    host = (database_host(url) or "").lower()
    if host in {"localhost", "127.0.0.1", "", "postgres", "db", "database"}:
        return True
    # Explicit opt-out: ?ssl=disable or ?sslmode=disable
    query = (urlparse(url).query or "").lower()
    return "ssl=disable" in query or "sslmode=disable" in query or "ssl=false" in query


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "sqlite+aiosqlite:///./afrios_dev.db"
    jwt_secret: str = "dev-secret"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 10080
    otp_dev_mode: bool = True
    otp_expire_minutes: int = 5
    otp_rate_limit_minutes: int = 15
    otp_rate_limit_max: int = 5
    otp_max_attempts: int = 5
    africas_talking_api_key: str = ""
    africas_talking_username: str = ""
    africas_talking_sender: str = ""
    # true = api.sandbox.africastalking.com (username "sandbox")
    africas_talking_sandbox: bool = False
    redis_url: str = "redis://localhost:6379/0"
    # Chariot (Mobile Money + abonnements)
    chariot_secret_key: str = ""
    chariot_public_key: str = ""
    chariot_sandbox: bool = True
    chariot_callback_url: str = "http://localhost:8000/v1/webhooks/chariot"
    chariot_return_url: str = "afrios://payment/success"
    chariot_api_base: str = "https://api.chariot.pay/v1"
    # Legacy aliases (FedaPay / CinetPay) — lus si CHARIOT_* est vide
    fedapay_secret_key: str = ""
    fedapay_public_key: str = ""
    fedapay_sandbox: bool = True
    fedapay_callback_url: str = ""
    fedapay_return_url: str = ""
    cinetpay_api_key: str = ""
    cinetpay_site_id: str = ""
    cinetpay_notify_url: str = "http://localhost:8000/v1/webhooks/cinetpay"
    cinetpay_return_url: str = "afrios://payment/success"
    cinetpay_sandbox: bool = True
    public_base_url: str = ""
    # Appliquer les limites des plans Gratuit / Pro (factures, clients, IA, relances auto).
    # Mettre PLANS_ENFORCED=false pour ouvrir toutes les fonctions pendant la bêta.
    plans_enforced: bool = False
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    firebase_credentials_path: str = ""
    jobs_cron_secret: str = "dev-cron-secret"
    app_name: str = "AfriOS API"
    app_version: str = "1.0.0"
    # Version de l'APK Android publiée (mise à jour in-app + page web).
    mobile_version_name: str = "1.0.1"
    mobile_version_code: int = 2
    mobile_apk_url: str = "https://afrios.afrizone.tech/download/AfriOS.apk"
    mobile_release_notes: str = "Catégories produits, quantité sur facture, paiements Chariot."
    cors_origins: list[str] = ["*"]
    api_prefix: str = "/v1"

    @field_validator("database_url", mode="before")
    @classmethod
    def coerce_database_url(cls, value: object) -> object:
        if not isinstance(value, str):
            return value
        return normalize_database_url(value)

    @model_validator(mode="after")
    def merge_legacy_payment_env(self):
        """FEDAPAY_* reste accepté le temps de la migration vers CHARIOT_*."""
        if not self.chariot_secret_key and self.fedapay_secret_key:
            self.chariot_secret_key = self.fedapay_secret_key
        if not self.chariot_public_key and self.fedapay_public_key:
            self.chariot_public_key = self.fedapay_public_key
        if not self.chariot_callback_url and self.fedapay_callback_url:
            self.chariot_callback_url = self.fedapay_callback_url
        if not self.chariot_return_url and self.fedapay_return_url:
            self.chariot_return_url = self.fedapay_return_url
        # Si seul FEDAPAY_SANDBOX est défini via défaut True, chariot_sandbox
        # reste la source de vérité (déjà True par défaut).
        if not self.chariot_callback_url:
            self.chariot_callback_url = "http://localhost:8000/v1/webhooks/chariot"
        if not self.chariot_return_url:
            self.chariot_return_url = "afrios://payment/success"
        return self


settings = Settings()
