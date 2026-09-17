from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from pydantic import field_validator
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
    if url.startswith("sqlite"):
        return True
    host = (database_host(url) or "").lower()
    return host in {"localhost", "127.0.0.1", ""}


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
    redis_url: str = "redis://localhost:6379/0"
    # FedaPay (Mobile Money + abonnements)
    fedapay_secret_key: str = ""
    fedapay_public_key: str = ""
    fedapay_sandbox: bool = True
    fedapay_callback_url: str = "http://localhost:8000/v1/webhooks/fedapay"
    fedapay_return_url: str = "afrios://payment/success"
    # Legacy CinetPay (ignored if FedaPay is configured)
    cinetpay_api_key: str = ""
    cinetpay_site_id: str = ""
    cinetpay_notify_url: str = "http://localhost:8000/v1/webhooks/cinetpay"
    cinetpay_return_url: str = "afrios://payment/success"
    cinetpay_sandbox: bool = True
    public_base_url: str = ""
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    firebase_credentials_path: str = ""
    jobs_cron_secret: str = "dev-cron-secret"
    app_name: str = "AfriOS API"
    app_version: str = "1.0.0"
    cors_origins: list[str] = ["*"]
    api_prefix: str = "/v1"

    @field_validator("database_url", mode="before")
    @classmethod
    def coerce_database_url(cls, value: object) -> object:
        if not isinstance(value, str):
            return value
        return normalize_database_url(value)


settings = Settings()
