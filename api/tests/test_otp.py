"""OTP auth hardening tests."""

import uuid

import pytest

from app.services.auth_service import mask_phone, normalize_phone


def test_normalize_phone_senegal():
    assert normalize_phone("77 123 45 67", default_country="SN") == "+221771234567"
    assert normalize_phone("+221771234567") == "+221771234567"
    assert normalize_phone("221771234567") == "+221771234567"


def test_normalize_phone_ivory_coast():
    assert normalize_phone("0700000000", default_country="CI") == "+225700000000"


def test_mask_phone():
    assert "•••" in mask_phone("+221771234567")


@pytest.mark.asyncio
async def test_otp_send_and_verify_dev_mode(client):
    phone = f"+22177{uuid.uuid4().hex[:8]}"
    send = await client.post("/v1/auth/otp/send", json={"phone": phone, "country_code": "SN"})
    assert send.status_code == 200
    body = send.json()
    assert body["dev_code"]
    assert body["channel"] in ("dev", "sms+dev")
    assert body["phone_masked"]

    bad = await client.post(
        "/v1/auth/otp/verify",
        json={"phone": phone, "code": "000000"},
    )
    assert bad.status_code == 400

    ok = await client.post(
        "/v1/auth/otp/verify",
        json={"phone": phone, "code": body["dev_code"]},
    )
    assert ok.status_code == 200
    assert "access_token" in ok.json()


@pytest.mark.asyncio
async def test_otp_rejects_when_prod_without_sms(client, monkeypatch):
    from app.config import settings

    monkeypatch.setattr(settings, "otp_dev_mode", False)
    monkeypatch.setattr(settings, "africas_talking_api_key", "")
    monkeypatch.setattr(settings, "africas_talking_username", "")

    phone = f"+22176{uuid.uuid4().hex[:8]}"
    send = await client.post("/v1/auth/otp/send", json={"phone": phone})
    assert send.status_code == 400
    assert "SMS" in send.json()["detail"] or "OTP" in send.json()["detail"]
