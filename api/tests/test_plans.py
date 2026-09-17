from app.services.plans import PLANS, get_plan


def test_plans_contain_business_tiers():
    assert set(PLANS) >= {"free", "pro", "enterprise"}
    assert get_plan("pro").price_monthly == 15000
    assert get_plan("free").max_invoices_per_month == 50
    assert get_plan("unknown").id == "free"
