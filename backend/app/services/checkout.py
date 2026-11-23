from decimal import Decimal
from uuid import uuid4

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CartItem, Inventory, Product, Sale, SaleItem, User, utc_now
from app.schemas.sales import CheckoutRequest


def _checkout_conflict(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail={"code": code, "message": message},
    )


def checkout(db: Session, user: User, payload: CheckoutRequest) -> Sale:
    cart_items = list(
        db.scalars(
            select(CartItem)
            .where(CartItem.user_id == user.id)
            .order_by(CartItem.product_id)
            .with_for_update()
        )
    )
    if not cart_items:
        db.rollback()
        raise _checkout_conflict("cart_empty", "The cart is empty.")

    product_ids = [item.product_id for item in cart_items]
    products = list(
        db.scalars(
            select(Product)
            .where(
                Product.id.in_(product_ids),
                Product.user_id == user.id,
            )
            .order_by(Product.id)
            .with_for_update()
        )
    )
    products_by_id = {product.id: product for product in products}
    if len(products_by_id) != len(cart_items):
        db.rollback()
        raise _checkout_conflict(
            "cart_product_unavailable", "A cart product is no longer available."
        )

    for item in cart_items:
        if products_by_id[item.product_id].quantity < item.quantity:
            db.rollback()
            raise _checkout_conflict(
                "insufficient_stock",
                "There is not enough stock to complete this checkout.",
            )

    total = sum(
        (
            products_by_id[item.product_id].price * item.quantity
            for item in cart_items
        ),
        start=Decimal("0.00"),
    )
    sale = Sale(
        user_id=user.id,
        total_amount=total,
        receipt_number=f"J-{uuid4().hex.upper()}",
        payment_method=payload.payment_method,
        description=payload.description,
        customer_name=payload.customer_name,
        customer_phone=payload.customer_phone,
    )
    db.add(sale)
    db.flush()

    for item in cart_items:
        product = products_by_id[item.product_id]
        stock_before = product.quantity
        stock_after = stock_before - item.quantity
        line_total = product.price * item.quantity
        db.add(
            SaleItem(
                sale_id=sale.id,
                product_id=product.id,
                quantity=item.quantity,
                unit_price=product.price,
                total_price=line_total,
            )
        )
        product.quantity = stock_after
        product.updated_at = utc_now()
        db.add(
            Inventory(
                user_id=user.id,
                product_id=product.id,
                change_type="SALE",
                stock_before=stock_before,
                stock_after=stock_after,
                reference_id=sale.id,
                notes=f"Sold {item.quantity} items of {product.name}",
            )
        )
        db.delete(item)

    db.commit()
    db.refresh(sale)
    return sale
