"""Auto-reminders daily job tests."""

from datetime import date, timedelta

import pytest


async def _auth_headers(client, phone: str | None = None) -> dict[str, str]:
    import uuid

    phone = phone or f"+22176{uuid.uuid4().hex[:8]}"
    send = await client.post("/v1/auth/otp/send", json={"phone": phone})
    assert send.status_code == 200
    code = send.json()["dev_code"]
    verify = await client.post("/v1/auth/otp/verify", json={"phone": phone, "code": code})
    assert verify.status_code == 200
    return {"Authorization": f"Bearer {verify.json()['access_token']}"}


@pytest.mark.asyncio
async def test_daily_job_creates_auto_reminder(client):
    headers = await _auth_headers(client)
    await client.post(
        "/v1/business",
        headers=headers,
        json={"name": "Relance Shop", "currency": "XOF"},
    )
    await client.put(
        "/v1/reminders/rules",
        headers=headers,
        json={"enabled": True, "days_after_due": [3]},
    )

    client_res = await client.post(
        "/v1/clients",
        headers=headers,
        json={"name": "Ibra", "phone": "+221770000002"},
    )
    client_id = client_res.json()["id"]

    due = (date.today() - timedelta(days=3)).isoformat()
    inv = await client.post(
        "/v1/invoices",
        headers=headers,
        json={
            "client_id": client_id,
            "due_date": due,
            "items": [
                {
                    "description": "Service",
                    "quantity": 1,
                    "unit_price": 5000,
                    "discount": 0,
                }
            ],
        },
    )
    assert inv.status_code == 200
    invoice_id = inv.json()["id"]

    # Force overdue status via mark path: send then run job (job marks overdue + reminds)
    send = await client.post(f"/v1/invoices/{invoice_id}/send", headers=headers)
    assert send.status_code == 200

    unauthorized = await client.post("/v1/jobs/daily")
    assert unauthorized.status_code == 401

    job = await client.post(
        "/v1/jobs/daily",
        headers={"X-Cron-Secret": "dev-cron-secret"},
    )
    assert job.status_code == 200
    body = job.json()
    assert body["overdue_marked"] >= 1
    assert body["reminders_created"] >= 1

    # Idempotent — second run should skip
    job2 = await client.post(
        "/v1/jobs/daily",
        headers={"X-Cron-Secret": "dev-cron-secret"},
    )
    assert job2.status_code == 200
    assert job2.json()["reminders_created"] == 0
