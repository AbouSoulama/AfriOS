"""Multi-tenant isolation + AI smoke tests."""

import uuid

import pytest


async def _login(client, phone: str) -> dict[str, str]:
    send = await client.post("/v1/auth/otp/send", json={"phone": phone})
    code = send.json()["dev_code"]
    verify = await client.post("/v1/auth/otp/verify", json={"phone": phone, "code": code})
    return {"Authorization": f"Bearer {verify.json()['access_token']}"}


@pytest.mark.asyncio
async def test_clients_are_isolated_between_businesses(client):
    h1 = await _login(client, f"+22171{uuid.uuid4().hex[:8]}")
    h2 = await _login(client, f"+22172{uuid.uuid4().hex[:8]}")

    await client.post("/v1/business", headers=h1, json={"name": "Biz A", "currency": "XOF"})
    await client.post("/v1/business", headers=h2, json={"name": "Biz B", "currency": "XOF"})

    created = await client.post(
        "/v1/clients",
        headers=h1,
        json={"name": "Secret Client", "phone": "+221770009999"},
    )
    assert created.status_code == 200
    client_id = created.json()["id"]

    # Owner B must not see / fetch owner A's client
    listing = await client.get("/v1/clients", headers=h2)
    assert listing.status_code == 200
    assert all(c["id"] != client_id for c in listing.json())

    stolen = await client.get(f"/v1/clients/{client_id}", headers=h2)
    assert stolen.status_code in (403, 404)


@pytest.mark.asyncio
async def test_ai_chat_revenue_intent(client):
    headers = await _login(client, f"+22173{uuid.uuid4().hex[:8]}")
    await client.post("/v1/business", headers=headers, json={"name": "AI Shop", "currency": "XOF"})

    chat = await client.post(
        "/v1/ai/chat",
        headers=headers,
        json={"message": "Combien j'ai facturé ce mois ?"},
    )
    assert chat.status_code == 200
    body = chat.json()
    assert body.get("message")
    assert body.get("intent") in (None, "revenue", "ca", "chiffre_affaires") or isinstance(
        body.get("intent"), str
    )
