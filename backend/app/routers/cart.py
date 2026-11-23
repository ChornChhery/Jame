from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import delete, select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import CartItem, Product, User, utc_now
from app.schemas.cart import CartItemResponse, CartItemUpdate


router = APIRouter(prefix="/cart", tags=["cart"])


def _cart_response(
    item: CartItem, product: Product
) -> CartItemResponse:
    return CartItemResponse(
        product_id=product.id,
        name=product.name,
        code=product.code,
        quantity=item.quantity,
        unit_price=product.price,
        total_price=product.price * item.quantity,
        available_quantity=product.quantity,
        category=product.category,
        unit=product.unit,
        image=product.image,
    )


@router.get("", response_model=list[CartItemResponse])
def get_cart(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[CartItemResponse]:
    rows = db.execute(
        select(CartItem, Product)
        .join(Product, Product.id == CartItem.product_id)
        .where(
            CartItem.user_id == user.id,
            Product.user_id == user.id,
        )
        .order_by(Product.name, Product.id)
    )
    return [_cart_response(item, product) for item, product in rows]


@router.put(
    "/items/{product_id}",
    response_model=CartItemResponse,
)
def set_cart_item(
    product_id: int,
    payload: CartItemUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> CartItemResponse:
    product = db.scalar(
        select(Product)
        .where(Product.id == product_id, Product.user_id == user.id)
        .with_for_update()
    )
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found."},
        )

    db.execute(
        insert(CartItem)
        .values(
            user_id=user.id,
            product_id=product.id,
            quantity=payload.quantity,
        )
        .on_conflict_do_update(
            constraint="uq_cart_user_product",
            set_={"quantity": payload.quantity, "updated_at": utc_now()},
        )
    )
    db.commit()
    item = db.scalar(
        select(CartItem).where(
            CartItem.user_id == user.id,
            CartItem.product_id == product.id,
        )
    )
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={"code": "cart_update_failed", "message": "Cart update failed."},
        )
    return _cart_response(item, product)


@router.delete(
    "/items/{product_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
def remove_cart_item(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Response:
    db.execute(
        delete(CartItem).where(
            CartItem.user_id == user.id,
            CartItem.product_id == product_id,
        )
    )
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def clear_cart(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Response:
    db.execute(delete(CartItem).where(CartItem.user_id == user.id))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
