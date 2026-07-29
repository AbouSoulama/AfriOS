from sqlalchemy import inspect, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

engine = create_async_engine(settings.database_url, echo=False)
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

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_ensure_business_payment_columns)


async def get_db():
    async with async_session() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
