from concurrent.futures import ThreadPoolExecutor

from sqlalchemy import text

from helpers import add_product, register


def _add_to_cart(client, csrf_token: str, product_id: int, quantity: int):
    return client.put(
        f"/api/v1/cart/items/{product_id}",
        json={"quantity": quantity},
        headers={"X-CSRF-Token": csrf_token},
    )


def _checkout(client, csrf_token: str):
    return client.post(
        "/api/v1/sales/checkout",
        json={
            "payment_method": "Cash",
            "customer_name": "Walk-in",
            "description": "Counter sale",
        },
        headers={"X-CSRF-Token": csrf_token},
    )


def test_checkout_rejects_insufficient_stock_without_partial_records(
    auth_client, auth_engine
):
    owner = register(auth_client, "checkout-stock@gmail.com", "checkout-stock")
    product = add_product(auth_client, owner["csrf_token"], quantity=1)
    product_id = product.json()["id"]
    added = _add_to_cart(auth_client, owner["csrf_token"], product_id, 2)
    assert added.status_code == 200

    response = _checkout(auth_client, owner["csrf_token"])

    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "insufficient_stock"
    with auth_engine.connect() as connection:
        stock = connection.execute(
            text("SELECT quantity FROM products WHERE id = :id"),
            {"id": product_id},
        ).scalar_one()
        cart_quantity = connection.execute(
            text("SELECT quantity FROM cart_items WHERE product_id = :id"),
            {"id": product_id},
        ).scalar_one()
        sales = connection.exec_driver_sql("SELECT count(*) FROM sales").scalar_one()
        sale_items = connection.exec_driver_sql(
            "SELECT count(*) FROM sale_items"
        ).scalar_one()
        movements = connection.exec_driver_sql(
            "SELECT count(*) FROM inventories"
        ).scalar_one()

    assert stock == 1
    assert cart_quantity == 2
    assert sales == sale_items == movements == 0


def test_checkout_uses_stored_prices_and_clears_cart_after_success(
    auth_client, auth_engine
):
    owner = register(auth_client, "checkout-success@gmail.com", "checkout-success")
    product = add_product(
        auth_client, owner["csrf_token"], price="4.50", quantity=5
    )
    product_id = product.json()["id"]
    added = _add_to_cart(auth_client, owner["csrf_token"], product_id, 2)
    assert added.status_code == 200

    response = _checkout(auth_client, owner["csrf_token"])

    assert response.status_code == 201
    sale = response.json()
    assert sale["total_amount"] == "9.00"
    assert sale["receipt_number"]
    assert sale["payment_method"] == "Cash"
    with auth_engine.connect() as connection:
        stock = connection.execute(
            text("SELECT quantity FROM products WHERE id = :id"),
            {"id": product_id},
        ).scalar_one()
        cart_count = connection.exec_driver_sql(
            "SELECT count(*) FROM cart_items"
        ).scalar_one()
        movement = connection.execute(
            text(
                "SELECT change_type, stock_before, stock_after, reference_id "
                "FROM inventories"
            )
        ).one()
        item = connection.execute(
            text(
                "SELECT quantity, unit_price, total_price FROM sale_items"
            )
        ).one()

    assert stock == 3
    assert cart_count == 0
    assert tuple(movement) == ("SALE", 5, 3, sale["id"])
    assert tuple(item) == (2, 4.50, 9.00)


def test_concurrent_checkout_never_oversells(auth_client, auth_engine):
    owner = register(auth_client, "checkout-race@gmail.com", "checkout-race")
    product = add_product(auth_client, owner["csrf_token"], quantity=1)
    product_id = product.json()["id"]
    added = _add_to_cart(auth_client, owner["csrf_token"], product_id, 1)
    assert added.status_code == 200

    with ThreadPoolExecutor(max_workers=2) as executor:
        results = list(
            executor.map(
                lambda _: _checkout(auth_client, owner["csrf_token"]),
                range(2),
            )
        )

    assert sorted(response.status_code for response in results) == [201, 409]
    with auth_engine.connect() as connection:
        stock = connection.execute(
            text("SELECT quantity FROM products WHERE id = :id"),
            {"id": product_id},
        ).scalar_one()
        sales = connection.exec_driver_sql("SELECT count(*) FROM sales").scalar_one()
        sale_items = connection.exec_driver_sql(
            "SELECT count(*) FROM sale_items"
        ).scalar_one()
        movements = connection.exec_driver_sql(
            "SELECT count(*) FROM inventories"
        ).scalar_one()

    assert stock == 0
    assert sales == sale_items == movements == 1


def test_sale_history_and_items_are_scoped_to_authenticated_user(
    auth_client, auth_client_factory
):
    owner = register(auth_client, "sale-history@gmail.com", "sale-history")
    product = add_product(auth_client, owner["csrf_token"], quantity=2)
    added = _add_to_cart(
        auth_client, owner["csrf_token"], product.json()["id"], 1
    )
    assert added.status_code == 200
    checkout = _checkout(auth_client, owner["csrf_token"])
    assert checkout.status_code == 201

    history = auth_client.get("/api/v1/sales")
    items = auth_client.get(
        f"/api/v1/sales/{checkout.json()['id']}/items"
    )
    assert history.status_code == 200
    assert len(history.json()) == 1
    assert items.status_code == 200
    assert items.json()[0]["product_name"] == "Green Tea"

    with auth_client_factory() as other_client:
        other = register(
            other_client, "sale-other@gmail.com", "sale-other"
        )
        assert other["user"]["id"] != owner["user"]["id"]
        assert other_client.get("/api/v1/sales").json() == []
        foreign_items = other_client.get(
            f"/api/v1/sales/{checkout.json()['id']}/items"
        )
        assert foreign_items.status_code == 404
