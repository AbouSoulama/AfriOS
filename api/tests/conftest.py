import os
from pathlib import Path

# Environnement de test HERMÉTIQUE : positionné avant tout import de `app`, il prime sur `.env`.
# Les tests n'écrivent donc jamais dans la base de développement et ne dépendent pas des clés réelles.
_TEST_DB = Path(__file__).resolve().parent.parent / "afrios_test.db"
if _TEST_DB.exists():
    _TEST_DB.unlink()
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_TEST_DB.as_posix()}"
os.environ["OTP_DEV_MODE"] = "true"
os.environ["CHARIOT_SANDBOX"] = "true"
os.environ["CHARIOT_SECRET_KEY"] = ""
os.environ["CHARIOT_PUBLIC_KEY"] = ""
os.environ["OPENAI_API_KEY"] = ""
os.environ["PLANS_ENFORCED"] = "true"

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402

from app.database import init_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest_asyncio.fixture
async def client():
    await init_db()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def account(client):
    """Fabrique un compte commerçant (téléphone unique + entreprise) et renvoie ses en-têtes.

    `await account(plan="pro")` donne directement un abonnement Pro actif.
    """
    import uuid
    from datetime import datetime, timedelta, timezone
    from uuid import UUID

    from sqlalchemy import select

    from app.database import async_session
    from app.models import Business

    async def make(plan: str = "free", name: str = "Boutique Test") -> dict[str, str]:
        phone = f"+22177{uuid.uuid4().hex[:8]}"
        send = await client.post("/v1/auth/otp/send", json={"phone": phone})
        verify = await client.post(
            "/v1/auth/otp/verify", json={"phone": phone, "code": send.json()["dev_code"]}
        )
        headers = {"Authorization": f"Bearer {verify.json()['access_token']}"}
        created = await client.post(
            "/v1/business", headers=headers, json={"name": name, "currency": "XOF"}
        )
        assert created.status_code == 200
        if plan != "free":
            async with async_session() as session:
                biz = (
                    await session.execute(
                        select(Business).where(Business.id == UUID(created.json()["id"]))
                    )
                ).scalar_one()
                biz.plan_id = plan
                biz.plan_expires_at = datetime.now(timezone.utc) + timedelta(days=30)
                await session.commit()
        return headers

    return make
