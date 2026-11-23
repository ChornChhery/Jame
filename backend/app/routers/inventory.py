from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import Inventory, Product, User, utc_now
from app.schemas.inventory import InventoryResponse, StockAdjustment
from app.schemas.products import ProductResponse


router = APIRouter(prefix="/inventory", tags=["inventory"])


@router.get("/low-stock", response_model=list[ProductResponse])
def low_stock_products(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Product]:
    return list(
        db.scalars(
            select(Product)
            .where(
                Product.user_id == user.id,
                Product.quantity <= Product.low_stock,
            )
            .order_by(Product.quantity, Product.name)
        )
    )


@router.post(
    "/adjustments",
    response_model=InventoryResponse,
    status_code=status.HTTP_200_OK,
)
def adjust_inventory(
    payload: StockAdjustment,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Inventory:
    product = db.scalar(
        select(Product)
        .where(
            Product.id == payload.product_id,
            Product.user_id == user.id,
        )
        .with_for_update()
    )
    if product is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "product_not_found", "message": "Product not found."},
        )

    movement = Inventory(
        user_id=user.id,
        product_id=product.id,
        change_type=payload.change_type,
        stock_before=product.quantity,
        stock_after=payload.new_quantity,
        reference_id=payload.reference_id,
        notes=payload.notes,
    )
    product.quantity = payload.new_quantity
    product.updated_at = utc_now()
    db.add(movement)
    db.commit()
    db.refresh(movement)
    return movement
