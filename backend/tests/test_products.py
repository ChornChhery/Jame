from sqlalchemy import text

from helpers import add_product, register


def test_products_are_scoped_to_authenticated_user(
    auth_client, auth_client_factory, auth_engine
):
    owner = register(auth_client, "owner@gmail.com", "owner-one")
    owner_csrf = owner["csrf_token"]

    with auth_client_factory() as other_client:
        other = register(other_client, "other@gmail.com", "owner-two")
        created = add_product(
            auth_client,
            owner_csrf,
            user_id=other["user"]["id"],
        )
        assert created.status_code == 201
        product_id = created.json()["id"]

        owner_read = auth_client.get(f"/api/v1/products/{product_id}")
        owner_code_lookup = auth_client.get(
            "/api/v1/products/by-code/TEA-001"
        )
        forbidden_read = other_client.get(f"/api/v1/products/{product_id}")
        forged_update = other_client.patch(
            f"/api/v1/products/{product_id}",
            json={"name": "Stolen", "user_id": owner["user"]["id"]},
            headers={"X-CSRF-Token": other["csrf_token"]},
        )
        forged_adjustment = other_client.post(
            "/api/v1/inventory/adjustments",
            json={
                "product_id": product_id,
                "new_quantity": 99,
                "change_type": "ADJUSTMENT",
            },
            headers={"X-CSRF-Token": other["csrf_token"]},
        )
        other_products = other_client.get("/api/v1/products")

    assert owner_read.status_code == 200
    assert owner_code_lookup.status_code == 200
    assert forbidden_read.status_code == 404
    assert forged_update.status_code == 404
    assert forged_adjustment.status_code == 404
    assert other_products.json() == []
    with auth_engine.connect() as connection:
        product = connection.execute(
            text("SELECT user_id, name, quantity FROM products WHERE id = :id"),
            {"id": product_id},
        ).one()
    assert product.user_id == owner["user"]["id"]
    assert product.name == "Green Tea"
    assert product.quantity == 8


def test_duplicate_product_code_is_rejected_per_user(
    auth_client, auth_client_factory
):
    first_owner = register(auth_client, "first@gmail.com", "first-owner")
    first = add_product(auth_client, first_owner["csrf_token"])
    duplicate = add_product(auth_client, first_owner["csrf_token"])

    with auth_client_factory() as second_client:
        second_owner = register(second_client, "second@gmail.com", "second-owner")
        same_code_for_other_user = add_product(
            second_client, second_owner["csrf_token"]
        )

    assert first.status_code == 201
    assert duplicate.status_code == 409
    assert same_code_for_other_user.status_code == 201
