from helpers import add_product, register


def test_cart_rejects_products_owned_by_another_user(
    auth_client, auth_engine, auth_client_factory
):
    owner = register(auth_client, "cart-owner@gmail.com", "cart-owner")
    product = add_product(auth_client, owner["csrf_token"])
    assert product.status_code == 201
    own_product_added = auth_client.put(
        f"/api/v1/cart/items/{product.json()['id']}",
        json={"quantity": 1},
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )
    assert own_product_added.status_code == 200

    with auth_client_factory() as other_client:
        other = register(other_client, "cart-other@gmail.com", "cart-other")
        response = other_client.put(
            f"/api/v1/cart/items/{product.json()['id']}",
            json={"quantity": 1},
            headers={"X-CSRF-Token": other["csrf_token"]},
        )

        assert response.status_code == 404

    with auth_engine.connect() as connection:
        cart_count = connection.exec_driver_sql(
            "SELECT count(*) FROM cart_items"
        ).scalar_one()
    assert cart_count == 1


def test_cart_persists_quantities_and_returns_database_prices(auth_client):
    owner = register(auth_client, "cart-quantity@gmail.com", "cart-quantity")
    product = add_product(
        auth_client, owner["csrf_token"], price="6.25", quantity=8
    )
    product_id = product.json()["id"]

    added = auth_client.put(
        f"/api/v1/cart/items/{product_id}",
        json={"quantity": 3},
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )
    cart = auth_client.get("/api/v1/cart")

    assert added.status_code == 200
    assert cart.status_code == 200
    assert len(cart.json()) == 1
    assert cart.json()[0] == {
        "product_id": product_id,
        "name": "Green Tea",
        "code": "TEA-001",
        "quantity": 3,
        "unit_price": "6.25",
        "total_price": "18.75",
        "available_quantity": 8,
        "category": "Drinks",
        "unit": "bottle",
        "image": None,
    }


def test_cart_item_and_cart_can_be_removed(auth_client):
    owner = register(auth_client, "cart-remove@gmail.com", "cart-remove")
    first = add_product(auth_client, owner["csrf_token"], code="TEA-001")
    second = add_product(
        auth_client, owner["csrf_token"], code="TEA-002", name="Black Tea"
    )
    assert first.status_code == second.status_code == 201

    for product in (first, second):
        response = auth_client.put(
            f"/api/v1/cart/items/{product.json()['id']}",
            json={"quantity": 1},
            headers={"X-CSRF-Token": owner["csrf_token"]},
        )
        assert response.status_code == 200

    removed = auth_client.delete(
        f"/api/v1/cart/items/{first.json()['id']}",
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )
    remaining = auth_client.get("/api/v1/cart")
    assert removed.status_code == 204
    assert [item["product_id"] for item in remaining.json()] == [
        second.json()["id"]
    ]

    cleared = auth_client.delete(
        "/api/v1/cart",
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )
    assert cleared.status_code == 204
    assert auth_client.get("/api/v1/cart").json() == []
