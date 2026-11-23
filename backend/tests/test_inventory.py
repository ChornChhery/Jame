from sqlalchemy import text

from helpers import add_product, register


def test_stock_adjustment_records_before_and_after(auth_client, auth_engine):
    owner = register(auth_client, "inventory@gmail.com", "inventory-owner")
    created = add_product(auth_client, owner["csrf_token"], quantity=5)
    assert created.status_code == 201

    response = auth_client.post(
        "/api/v1/inventory/adjustments",
        json={
            "product_id": created.json()["id"],
            "new_quantity": 11,
            "change_type": "STOCK_IN",
            "notes": "Restocked",
        },
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )

    assert response.status_code == 200
    assert response.json()["stock_before"] == 5
    assert response.json()["stock_after"] == 11
    with auth_engine.connect() as connection:
        movement = connection.execute(
            text(
                "SELECT user_id, product_id, change_type, stock_before, "
                "stock_after, notes FROM inventories"
            )
        ).one()
    assert movement.user_id == owner["user"]["id"]
    assert movement.product_id == created.json()["id"]
    assert movement.change_type == "STOCK_IN"
    assert movement.stock_before == 5
    assert movement.stock_after == 11
    assert movement.notes == "Restocked"


def test_product_quantity_edit_records_inventory_movement(
    auth_client, auth_engine
):
    owner = register(auth_client, "edit-stock@gmail.com", "edit-stock-owner")
    created = add_product(auth_client, owner["csrf_token"], quantity=5)

    updated = auth_client.patch(
        f"/api/v1/products/{created.json()['id']}",
        json={"quantity": 3},
        headers={"X-CSRF-Token": owner["csrf_token"]},
    )

    assert updated.status_code == 200
    assert updated.json()["quantity"] == 3
    with auth_engine.connect() as connection:
        movement = connection.execute(
            text(
                "SELECT change_type, stock_before, stock_after "
                "FROM inventories ORDER BY id DESC LIMIT 1"
            )
        ).one()
    assert movement.change_type == "ADJUSTMENT"
    assert movement.stock_before == 5
    assert movement.stock_after == 3
