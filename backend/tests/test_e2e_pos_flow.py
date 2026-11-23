from helpers import add_product, register


def test_register_login_create_product_checkout_and_verify_history(auth_client):
    registration = register(
        auth_client,
        "pos-e2e@gmail.com",
        "pos-e2e",
    )
    login = auth_client.post(
        "/api/v1/auth/login",
        json={
            "email": "pos-e2e@gmail.com",
            "password": "JamePass123!",
        },
    )
    assert login.status_code == 200
    csrf_token = login.json()["csrf_token"]

    created = add_product(auth_client, csrf_token, quantity=5)
    assert created.status_code == 201
    product_id = created.json()["id"]
    added_to_cart = auth_client.put(
        f"/api/v1/cart/items/{product_id}",
        json={"quantity": 2},
        headers={"X-CSRF-Token": csrf_token},
    )
    assert added_to_cart.status_code == 200

    checkout = auth_client.post(
        "/api/v1/sales/checkout",
        json={"payment_method": "Cash"},
        headers={"X-CSRF-Token": csrf_token},
    )

    assert registration["user"]["email"] == "pos-e2e@gmail.com"
    assert checkout.status_code == 201
    sale = checkout.json()
    product = auth_client.get(f"/api/v1/products/{product_id}")
    history = auth_client.get("/api/v1/sales")
    items = auth_client.get(f"/api/v1/sales/{sale['id']}/items")

    assert product.status_code == 200
    assert product.json()["quantity"] == 3
    assert history.status_code == 200
    assert [row["id"] for row in history.json()] == [sale["id"]]
    assert items.status_code == 200
    assert items.json()[0]["quantity"] == 2
