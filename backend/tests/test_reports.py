from datetime import datetime, timezone

from sqlalchemy import text

from helpers import add_product, register


def _sell_product(client, csrf_token: str, product_id: int, customer_phone=None):
    added = client.put(
        f"/api/v1/cart/items/{product_id}",
        json={"quantity": 1},
        headers={"X-CSRF-Token": csrf_token},
    )
    assert added.status_code == 200
    response = client.post(
        "/api/v1/sales/checkout",
        json={
            "payment_method": "Cash",
            "customer_name": "Report Customer",
            "customer_phone": customer_phone,
        },
        headers={"X-CSRF-Token": csrf_token},
    )
    assert response.status_code == 201
    return response.json()


def test_daily_report_uses_bangkok_day_boundary(auth_client, auth_engine):
    owner = register(auth_client, "report-midnight@gmail.com", "report-midnight")
    product = add_product(auth_client, owner["csrf_token"], quantity=3)
    first = _sell_product(
        auth_client, owner["csrf_token"], product.json()["id"]
    )
    second = _sell_product(
        auth_client, owner["csrf_token"], product.json()["id"]
    )
    with auth_engine.begin() as connection:
        connection.execute(
            text("UPDATE sales SET sale_date = :date WHERE id = :id"),
            {
                "date": datetime(2026, 1, 1, 16, 59, 59, tzinfo=timezone.utc),
                "id": first["id"],
            },
        )
        connection.execute(
            text("UPDATE sales SET sale_date = :date WHERE id = :id"),
            {
                "date": datetime(2026, 1, 1, 17, 0, 0, tzinfo=timezone.utc),
                "id": second["id"],
            },
        )

    response = auth_client.get(
        "/api/v1/reports/sales/daily",
        params={
            "start": "2026-01-01T16:00:00Z",
            "end": "2026-01-01T18:00:00Z",
        },
    )

    assert response.status_code == 200
    daily = response.json()["dailyData"]
    assert [row["sale_day"] for row in daily] == ["2026-01-01", "2026-01-02"]
    assert [row["total_revenue"] for row in daily] == [4.5, 4.5]


def test_report_cannot_read_other_users_sales(auth_client, auth_client_factory):
    owner = register(auth_client, "report-owner@gmail.com", "report-owner")
    product = add_product(auth_client, owner["csrf_token"], quantity=2)
    _sell_product(auth_client, owner["csrf_token"], product.json()["id"])

    with auth_client_factory() as other_client:
        register(other_client, "report-other@gmail.com", "report-other")
        response = other_client.get(
            "/api/v1/reports/sales",
            params={
                "start": "2000-01-01T00:00:00Z",
                "end": "2100-01-01T00:00:00Z",
            },
        )

    assert response.status_code == 200
    assert response.json() == []


def test_dashboard_report_returns_today_totals_top_products_and_low_stock(
    auth_client,
):
    owner = register(auth_client, "report-dashboard@gmail.com", "report-dashboard")
    product = add_product(
        auth_client, owner["csrf_token"], price="4.50", quantity=5, low_stock=4
    )
    _sell_product(auth_client, owner["csrf_token"], product.json()["id"])

    response = auth_client.get("/api/v1/reports/dashboard")

    assert response.status_code == 200
    dashboard = response.json()
    assert dashboard["today_total"] == 4.5
    assert dashboard["today_count"] == 1
    assert dashboard["sales"][0]["id"]
    assert dashboard["top_products"][0]["name"] == "Green Tea"
    assert dashboard["low_stock"][0]["id"] == product.json()["id"]


def test_report_series_preserves_consumer_response_keys(auth_client):
    owner = register(auth_client, "report-keys@gmail.com", "report-keys")
    product = add_product(auth_client, owner["csrf_token"], quantity=2)
    _sell_product(auth_client, owner["csrf_token"], product.json()["id"])
    date_range = {
        "start": "2000-01-01T00:00:00Z",
        "end": "2100-01-01T00:00:00Z",
    }

    hourly = auth_client.get(
        "/api/v1/reports/sales/hourly", params=date_range
    )
    daily = auth_client.get(
        "/api/v1/reports/sales/daily", params=date_range
    )
    inventory = auth_client.get(
        "/api/v1/reports/inventory/movement", params=date_range
    )

    assert hourly.status_code == daily.status_code == inventory.status_code == 200
    assert "hourlyData" in hourly.json()
    assert "dailyData" in daily.json()
    assert "inventoryData" in inventory.json()
    assert hourly.json()["hourlyData"][0]["total_revenue"] == 4.5
    assert daily.json()["dailyData"][0]["total_revenue"] == 4.5
    assert inventory.json()["inventoryData"][0]["sold_quantity"] == 1


def test_all_report_routes_keep_legacy_result_shapes(auth_client):
    owner = register(auth_client, "report-contract@gmail.com", "report-contract")
    product = add_product(auth_client, owner["csrf_token"], quantity=2)
    _sell_product(
        auth_client,
        owner["csrf_token"],
        product.json()["id"],
        customer_phone="0123456789",
    )
    date_range = "start=2000-01-01T00%3A00%3A00Z&end=2100-01-01T00%3A00%3A00Z"
    endpoints = [
        "/api/v1/reports/products/top?limit=10&" + date_range,
        "/api/v1/reports/customers/purchase-history?limit=50",
        "/api/v1/reports/inventory/reorder-suggestions",
        "/api/v1/reports/products/performance?limit=20&" + date_range,
        "/api/v1/reports/customers/segmentation?limit=100",
        "/api/v1/reports/revenue-projection?" + date_range,
        "/api/v1/reports/payment-methods?" + date_range,
        "/api/v1/reports/categories?" + date_range,
        "/api/v1/reports/domestic-export-sales?" + date_range,
        "/api/v1/reports/sales/trends?" + date_range,
    ]

    responses = [auth_client.get(endpoint) for endpoint in endpoints]

    assert all(response.status_code == 200 for response in responses)
    assert isinstance(responses[0].json(), list)
    assert isinstance(responses[1].json(), list)
    assert isinstance(responses[2].json(), list)
    assert isinstance(responses[3].json(), list)
    assert {"segments", "totalCustomers", "averageSpentPerCustomer", "totalRevenue"} <= (
        responses[4].json().keys()
    )
    assert {"historicalData", "projectionAverage"} <= responses[5].json().keys()
    assert isinstance(responses[6].json(), list)
    assert isinstance(responses[7].json(), list)
    assert "dailyData" in responses[8].json()
    assert responses[8].json()["dailyData"][0]["domestic_count"] == 1
    assert responses[7].json()[0]["category"] == "Drinks"
    assert {
        "currentPeriodData",
        "previousPeriodData",
        "currentRevenue",
        "previousRevenue",
        "growthRate",
    } <= responses[9].json().keys()
    invalid_limit = auth_client.get(
        "/api/v1/reports/products/top?limit=101&" + date_range
    )
    assert invalid_limit.status_code == 422
