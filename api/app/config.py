from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


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
    cinetpay_api_key: str = ""
    cinetpay_site_id: str = ""
    cinetpay_notify_url: str = "http://localhost:8000/v1/webhooks/cinetpay"
    cinetpay_return_url: str = "afrios://payment/success"
    cinetpay_sandbox: bool = True
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
    def normalize_database_url(cls, value: object) -> object:
        """Render/Heroku give postgres:// — SQLAlchemy async needs postgresql+asyncpg://."""
        if not isinstance(value, str):
            return value
        if value.startswith("postgres://"):
            return value.replace("postgres://", "postgresql+asyncpg://", 1)
        if value.startswith("postgresql://") and "+asyncpg" not in value:
            return value.replace("postgresql://", "postgresql+asyncpg://", 1)
        return value


settings = Settings()
