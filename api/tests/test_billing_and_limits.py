"""Plans, abonnement (le commerçant paie AfriOS) et encaissement (le client paie le commerçant)."""

import pytest

from app.config import settings
from app.services.ai_service import detect_intent


async def _client_and_invoice(client, headers, total=15000):
    created = await client.post(
        "/v1/clients", headers=headers, json={"name": "Awa", "phone": "+221770000001"}
    )
    assert created.status_code == 200, created.text
    client_id = created.json()["id"]
    invoice = await client.post(
        "/v1/invoices",
        headers=headers,
        json={
            "client_id": client_id,
            "items": [{"description": "Riz 25kg", "quantity": 1, "unit_price": total, "discount": 0}],
        },
    )
    assert invoice.status_code == 200, invoice.text
    return client_id, invoice.json()["id"]


# ── Limites des plans ─────────────────────────────────────────────────────────


async def test_free_plan_blocks_ai_but_pro_allows_it(client, account):
    free = await account()
    blocked = await client.post("/v1/ai/chat", headers=free, json={"message": "Stock faible ?"})
    assert blocked.status_code == 402
    assert "Pro" in blocked.json()["detail"]

    pro = await account(plan="pro")
    allowed = await client.post("/v1/ai/chat", headers=pro, json={"message": "Stock faible ?"})
    assert allowed.status_code == 200


async def test_free_plan_client_limit(client, account):
    headers = await account()
    for i in range(25):
        res = await client.post("/v1/clients", headers=headers, json={"name": f"Client {i}"})
        assert res.status_code == 200, res.text
    over = await client.post("/v1/clients", headers=headers, json={"name": "Client de trop"})
    assert over.status_code == 402
    assert "25 clients" in over.json()["detail"]


async def test_pro_plan_has_no_client_limit(client, account):
    headers = await account(plan="pro")
    for i in range(27):
        res = await client.post("/v1/clients", headers=headers, json={"name": f"Client {i}"})
        assert res.status_code == 200


async def test_limits_can_be_disabled_for_beta(client, account, monkeypatch):
    monkeypatch.setattr(settings, "plans_enforced", False)
    headers = await account()
    res = await client.post("/v1/ai/chat", headers=headers, json={"message": "Stock faible ?"})
    assert res.status_code == 200


async def test_expired_pro_falls_back_to_free(client, account):
    from datetime import datetime, timedelta, timezone

    from sqlalchemy import select

    from app.database import async_session
    from app.models import Business

    headers = await account(plan="pro")
    biz_id = (await client.get("/v1/business", headers=headers)).json()["id"]
    from uuid import UUID

    async with async_session() as session:
        biz = (await session.execute(select(Business).where(Business.id == UUID(biz_id)))).scalar_one()
        biz.plan_expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        await session.commit()

    current = (await client.get("/v1/billing/current", headers=headers)).json()
    assert current["plan_id"] == "free"
    assert current["is_active"] is False
    blocked = await client.post("/v1/ai/chat", headers=headers, json={"message": "Stock faible ?"})
    assert blocked.status_code == 402


# ── Abonnement : le commerçant paie AfriOS ────────────────────────────────────


async def test_subscription_sandbox_flow(client, account):
    headers = await account()

    sub = await client.post("/v1/billing/subscribe", headers=headers, json={"plan_id": "pro"})
    assert sub.status_code == 200, sub.text
    body = sub.json()
    assert body["sandbox_mock"] is True
    assert " " not in body["payment_link"]  # l'URL doit être encodée
    ref = body["transaction_id"]

    # Sans avoir payé, la confirmation ne doit PAS activer le plan.
    early = await client.post(
        "/v1/billing/confirm", headers=headers, json={"transaction_id": ref, "plan_id": "pro"}
    )
    assert early.json()["status"] == "pending"
    assert (await client.get("/v1/billing/current", headers=headers)).json()["plan_id"] == "free"

    # La page de simulation « paie » l'abonnement.
    page = await client.get(body["payment_link"].replace("http://test", ""))
    assert page.status_code == 200
    assert "commerçant" in page.text
    paid = await client.post("/v1/payments/sandbox/confirm", data={"ref": ref})
    assert paid.status_code == 200

    done = await client.post(
        "/v1/billing/confirm", headers=headers, json={"transaction_id": ref, "plan_id": "pro"}
    )
    assert done.json()["status"] == "ok"
    assert (await client.get("/v1/billing/current", headers=headers)).json()["plan_id"] == "pro"


async def test_cannot_get_pro_for_free_with_forged_confirmation(client, account):
    headers = await account()
    forged = await client.post(
        "/v1/billing/confirm",
        headers=headers,
        json={"transaction_id": "SUB-PRO-FORGED", "plan_id": "pro"},
    )
    assert forged.json()["status"] == "pending"
    assert (await client.get("/v1/billing/current", headers=headers)).json()["plan_id"] == "free"


async def test_enterprise_plan_is_not_purchasable_yet(client, account):
    headers = await account()
    res = await client.post("/v1/billing/subscribe", headers=headers, json={"plan_id": "enterprise"})
    assert res.status_code == 400
    plans = (await client.get("/v1/billing/plans")).json()["plans"]
    assert {p["id"]: p["available"] for p in plans} == {"free": True, "pro": True, "enterprise": False}


async def test_forged_webhook_cannot_upgrade_or_mark_paid(client, account):
    headers = await account()
    _client_id, invoice_id = await _client_and_invoice(client, headers)
    pay = await client.post("/v1/payments/initiate", headers=headers, json={"invoice_id": invoice_id})
    ref = pay.json()["transaction_id"]

    forged_invoice = await client.post(
        "/v1/webhooks/fedapay", json={"id": ref, "status": "approved"}
    )
    assert forged_invoice.json()["status"] == "pending"
    detail = await client.get(f"/v1/invoices/{invoice_id}", headers=headers)
    assert detail.json()["status"] != "paid"

    forged_sub = await client.post(
        "/v1/webhooks/fedapay",
        json={
            "id": 999,
            "status": "approved",
            "custom_metadata": {"kind": "subscription", "plan_id": "pro", "business_id": "x"},
        },
    )
    assert forged_sub.json()["status"] == "ignored"
    assert (await client.get("/v1/billing/current", headers=headers)).json()["plan_id"] == "free"


# ── Encaissement : le client paie le commerçant ───────────────────────────────


async def test_verify_does_not_pay_invoice_without_client_payment(client, account):
    headers = await account()
    _cid, invoice_id = await _client_and_invoice(client, headers)
    await client.post("/v1/payments/initiate", headers=headers, json={"invoice_id": invoice_id})

    verify = await client.post("/v1/payments/verify", headers=headers, json={"invoice_id": invoice_id})
    assert verify.json()["status"] == "pending"
    detail = await client.get(f"/v1/invoices/{invoice_id}", headers=headers)
    assert detail.json()["status"] != "paid"


async def test_production_without_merchant_keys_refuses_instead_of_faking(client, account, monkeypatch):
    monkeypatch.setattr(settings, "fedapay_sandbox", False)
    monkeypatch.setattr(settings, "fedapay_secret_key", "sk_platform_must_not_be_used")
    headers = await account()
    _cid, invoice_id = await _client_and_invoice(client, headers)

    # Les clés de la plateforme ne doivent JAMAIS servir à encaisser les clients d'un commerçant.
    pay = await client.post("/v1/payments/initiate", headers=headers, json={"invoice_id": invoice_id})
    assert pay.status_code == 400
    assert "FedaPay" in pay.json()["detail"]

    settings_res = (await client.get("/v1/payments/settings", headers=headers)).json()
    assert settings_res["ready"] is False
    assert settings_res["using_platform_keys"] is False

    # Les pages de simulation n'existent pas en production.
    page = await client.get("/v1/payments/sandbox/checkout", params={"ref": "AFRI-X", "amount": "1"})
    assert page.status_code == 404
    confirm = await client.post("/v1/payments/sandbox/confirm", data={"ref": "AFRI-X"})
    assert confirm.status_code == 404


async def test_mark_paid_is_idempotent(client, account):
    headers = await account()
    _cid, invoice_id = await _client_and_invoice(client, headers)
    for _ in range(2):
        res = await client.post(
            f"/v1/invoices/{invoice_id}/mark-paid", headers=headers, json={"method": "cash"}
        )
        assert res.status_code == 200
    payments = (await client.get("/v1/payments", headers=headers)).json()
    assert len(payments) == 1


async def test_sandbox_page_escapes_user_input(client):
    page = await client.get(
        "/v1/payments/sandbox/checkout",
        params={"ref": '"><script>alert(1)</script>', "amount": "1", "invoice": "<b>x</b>"},
    )
    assert page.status_code == 200
    assert "<script>alert(1)</script>" not in page.text


# ── Assistant IA ──────────────────────────────────────────────────────────────


@pytest.mark.parametrize(
    "message,expected",
    [
        ("Factures impayées ?", "unpaid_invoices"),
        ("Combien de factures ?", "invoice_count"),
        ("Combien j'ai facturé ce mois ?", "revenue_period"),
        ("Stock faible ?", "low_stock"),
        ("Qui dois-je relancer ?", "overdue_clients"),
        ("Relance les clients en retard", "overdue_clients"),
        ("Quel est mon CA ?", "revenue_period"),
        ("Raconte-moi une blague", None),
    ],
)
def test_ai_intent_detection(message, expected):
    assert detect_intent(message) == expected
