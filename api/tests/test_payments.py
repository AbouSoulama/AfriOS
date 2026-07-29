"""Payment / CinetPay sandbox flow tests."""

import uuid

import pytest


async def _auth_headers(client, phone: str | None = None) -> dict[str, str]:
    phone = phone or f"+22177{uuid.uuid4().hex[:8]}"
    send = await client.post("/v1/auth/otp/send", json={"phone": phone})
    assert send.status_code == 200
    code = send.json().get("dev_code")
    assert code
    verify = await client.post(
        "/v1/auth/otp/verify",
        json={"phone": phone, "code": code},
    )
    assert verify.status_code == 200
    token = verify.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.mark.asyncio
async def test_sandbox_payment_marks_invoice_paid(client, monkeypatch):
    from app.config import settings

    monkeypatch.setattr(settings, "cinetpay_api_key", "")
    monkeypatch.setattr(settings, "cinetpay_site_id", "")

    headers = await _auth_headers(client)

    biz = await client.post(
        "/v1/business",
        headers=headers,
        json={"name": "Boutique Test", "sector": "commerce", "currency": "XOF"},
    )
    assert biz.status_code == 200

    await client.put(
        "/v1/payments/settings",
        headers=headers,
        json={"site_id": "", "clear_api_key": True, "enabled": False},
    )

    client_res = await client.post(
        "/v1/clients",
        headers=headers,
        json={"name": "Awa", "phone": "+221770000001"},
    )
    assert client_res.status_code == 200
    client_id = client_res.json()["id"]

    inv = await client.post(
        "/v1/invoices",
        headers=headers,
        json={
            "client_id": client_id,
            "items": [
                {
                    "description": "Riz 25kg",
                    "quantity": 1,
                    "unit_price": 15000,
                    "discount": 0,
                }
            ],
        },
    )
    assert inv.status_code == 200
    invoice_id = inv.json()["id"]

    pay = await client.post(
        "/v1/payments/initiate",
        headers=headers,
        json={"invoice_id": invoice_id},
    )
    assert pay.status_code == 200
    body = pay.json()
    assert body["sandbox_mock"] is True
    assert "/payments/sandbox/checkout" in body["payment_link"]
    transaction_id = body["transaction_id"]

    confirm = await client.post(
        "/v1/payments/sandbox/confirm",
        data={"ref": transaction_id},
    )
    assert confirm.status_code == 200

    detail = await client.get(f"/v1/invoices/{invoice_id}", headers=headers)
    assert detail.status_code == 200
    assert detail.json()["status"] == "paid"

    verify = await client.post(
        "/v1/payments/verify",
        headers=headers,
        json={"invoice_id": invoice_id},
    )
    assert verify.status_code == 200
    assert verify.json()["status"] == "already_paid"


@pytest.mark.asyncio
async def test_payment_settings_roundtrip(client):
    headers = await _auth_headers(client)
    await client.post(
        "/v1/business",
        headers=headers,
        json={"name": "MM Shop", "currency": "XOF"},
    )

    updated = await client.put(
        "/v1/payments/settings",
        headers=headers,
        json={"site_id": "123456", "api_key": "secret-key", "enabled": True},
    )
    assert updated.status_code == 200
    data = updated.json()
    assert data["site_id"] == "123456"
    assert data["api_key_set"] is True
    assert data["enabled"] is True

    got = await client.get("/v1/payments/settings", headers=headers)
    assert got.status_code == 200
    assert got.json()["site_id"] == "123456"
    assert "api_key" not in got.json()
