import asyncio
import logging

from sqlalchemy import inspect, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import is_local_database, settings

logger = logging.getLogger(__name__)


def _engine_kwargs() -> dict:
    kwargs: dict = {"echo": False, "pool_pre_ping": True}
    url = settings.database_url
    if "+asyncpg" in url or url.startswith("postgresql"):
        connect_args: dict = {"timeout": 60}
        # Render Postgres requires TLS. Local docker Postgres does not.
        if not is_local_database(url):
            connect_args["ssl"] = True
        kwargs["connect_args"] = connect_args
        kwargs["pool_size"] = 5
        kwargs["max_overflow"] = 5
    return kwargs


engine = create_async_engine(settings.database_url, **_engine_kwargs())
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


def _ensure_business_payment_columns(sync_conn) -> None:
    """Add columns on existing DBs (create_all won't alter tables)."""
    inspector = inspect(sync_conn)
    tables = inspector.get_table_names()
    dialect = sync_conn.dialect.name

    if "businesses" in tables:
        cols = {c["name"] for c in inspector.get_columns("businesses")}
        patches: list[tuple[str, str]] = [
            ("cinetpay_api_key", "TEXT"),
            ("cinetpay_site_id", "VARCHAR(100)"),
            (
                "cinetpay_enabled",
                "BOOLEAN DEFAULT 0" if dialect == "sqlite" else "BOOLEAN DEFAULT FALSE",
            ),
            ("fedapay_secret_key", "TEXT"),
            ("fedapay_public_key", "TEXT"),
            (
                "fedapay_enabled",
                "BOOLEAN DEFAULT 0" if dialect == "sqlite" else "BOOLEAN DEFAULT FALSE",
            ),
            ("plan_id", "VARCHAR(32) DEFAULT 'free'"),
            ("plan_expires_at", "TIMESTAMP" if dialect == "sqlite" else "TIMESTAMPTZ"),
        ]
        for name, typ in patches:
            if name not in cols:
                sync_conn.execute(text(f"ALTER TABLE businesses ADD COLUMN {name} {typ}"))

    if "reminders" in tables:
        cols = {c["name"] for c in inspector.get_columns("reminders")}
        if "trigger_days" not in cols:
            sync_conn.execute(text("ALTER TABLE reminders ADD COLUMN trigger_days INTEGER"))

    if "otp_codes" in tables:
        cols = {c["name"] for c in inspector.get_columns("otp_codes")}
        if "attempts" not in cols:
            sync_conn.execute(text("ALTER TABLE otp_codes ADD COLUMN attempts INTEGER DEFAULT 0"))


async def init_db() -> None:
    """Create tables if missing (SQLite local + first deploy Postgres)."""
    from app import models  # noqa: F401
    from app.config import database_host

    host = database_host(settings.database_url) or "(sqlite)"
    last_error: Exception | None = None
    for attempt in range(1, 9):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
                await conn.run_sync(_ensure_business_payment_columns)
            logger.info("Database ready (host=%s)", host)
            return
        except Exception as exc:  # noqa: BLE001 — retry DNS / cold start
            last_error = exc
            logger.warning(
                "Database connect failed (host=%s, attempt %s/8): %s",
                host,
                attempt,
                exc,
            )
            await asyncio.sleep(min(2 * attempt, 12))

    raise RuntimeError(
        f"Impossible de joindre PostgreSQL (host={host}). "
        "Sur Render : Dashboard → ton service Postgres → copie l'URL "
        "(External Database URL) dans DATABASE_URL du service web, puis Redeploy."
    ) from last_error


async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
