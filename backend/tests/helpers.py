from fastapi.testclient import TestClient


def register(client: TestClient, email: str, username: str) -> dict:
    response = client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "JamePass123!",
            "first_name": "Test",
            "last_name": "Owner",
            "shop_name": f"{username} Shop",
        },
    )
    assert response.status_code == 201
    return response.json()


def add_product(client: TestClient, csrf_token: str, **overrides):
    payload = {
        "name": "Green Tea",
        "price": "4.50",
        "quantity": 8,
        "low_stock": 2,
        "code": "TEA-001",
        "category": "Drinks",
        "unit": "bottle",
        **overrides,
    }
    return client.post(
        "/api/v1/products",
        json=payload,
        headers={"X-CSRF-Token": csrf_token},
    )
