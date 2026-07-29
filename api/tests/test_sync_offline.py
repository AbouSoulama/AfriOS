"""Offline sync push — clients + invoices."""

import uuid

import pytest


async def _auth_headers(client) -> dict[str, str]:
    phone = f"+22175{uuid.uuid4().hex[:8]}"
    send = await client.post("/v1/auth/otp/send", json={"phone": phone})
    code = send.json()["dev_code"]
    verify = await client.post("/v1/auth/otp/verify", json={"phone": phone, "code": code})
    return {"Authorization": f"Bearer {verify.json()['access_token']}"}


@pytest.mark.asyncio
async def test_sync_push_client_then_invoice(client):
    headers = await _auth_headers(client)
    await client.post(
        "/v1/business",
        headers=headers,
        json={"name": "Offline Shop", "currency": "XOF"},
    )

    client_op = str(uuid.uuid4())
    invoice_op = str(uuid.uuid4())

    push = await client.post(
        "/v1/sync/push",
        headers=headers,
        json={
            "operations": [
                {
                    "client_op_id": invoice_op,
                    "entity_type": "invoice",
                    "operation": "create",
                    "payload": {
                        "client_op_id": client_op,
                        "notes": "offline",
                        "items": [
                            {
                                "description": "Pain",
                                "quantity": 2,
                                "unit_price": 500,
                                "discount": 0,
                            }
                        ],
                    },
                },
                {
                    "client_op_id": client_op,
                    "entity_type": "client",
                    "operation": "create",
                    "payload": {"name": "Moussa", "phone": "+221770001111"},
                },
            ]
        },
    )
    assert push.status_code == 200
    results = {r["client_op_id"]: r for r in push.json()["results"]}
    assert results[client_op]["status"] == "processed"
    assert results[invoice_op]["status"] == "processed"
    assert results[invoice_op]["entity_id"]

    invoices = await client.get("/v1/invoices", headers=headers)
    assert invoices.status_code == 200
    assert len(invoices.json()) >= 1
    assert any(i["total"] in (1000, "1000", "1000.00") or float(i["total"]) == 1000 for i in invoices.json())
