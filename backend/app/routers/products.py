from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import Inventory, Product, User, utc_now
from app.schemas.inventory import InventoryResponse
from app.schemas.products import ProductCreate, ProductResponse, ProductUpdate


router = APIRouter(prefix="/products", tags=["products"])


def _not_found() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail={"code": "product_not_found", "message": "Product not found."},
    )


def _code_conflict(error: IntegrityError) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_409_CONFLICT,
        detail={"code": "product_code_conflict", "message": "Product code already exists."},
    )


@router.get("", response_model=list[ProductResponse])
def list_products(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Product]:
    return list(
        db.scalars(
            select(Product).where(Product.user_id == user.id).order_by(Product.id)
        )
    )


@router.post("", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
def create_product(
    payload: ProductCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Product:
    product = Product(user_id=user.id, **payload.model_dump())
    db.add(product)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise _code_conflict(error) from error
    db.refresh(product)
    return product


@router.get("/by-code/{code}", response_model=ProductResponse)
def get_product_by_code(
    code: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Product:
    product = db.scalar(
        select(Product).where(Product.user_id == user.id, Product.code == code)
    )
    if product is None:
        raise _not_found()
    return product


@router.get("/{product_id}", response_model=ProductResponse)
def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Product:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == user.id,
        )
    )
    if product is None:
        raise _not_found()
    return product


@router.patch("/{product_id}", response_model=ProductResponse)
def update_product(
    product_id: int,
    payload: ProductUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Product:
    product = db.scalar(
        select(Product)
        .where(Product.id == product_id, Product.user_id == user.id)
        .with_for_update()
    )
    if product is None:
        raise _not_found()

    changes = payload.model_dump(exclude_unset=True)
    new_quantity = changes.pop("quantity", product.quantity)
    if new_quantity != product.quantity:
        db.add(
            Inventory(
                user_id=user.id,
                product_id=product.id,
                change_type="ADJUSTMENT",
                stock_before=product.quantity,
                stock_after=new_quantity,
                notes="Product quantity updated",
            )
        )
        product.quantity = new_quantity
    for field, value in changes.items():
        setattr(product, field, value)
    product.updated_at = utc_now()
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise _code_conflict(error) from error
    db.refresh(product)
    return product


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Response:
    product = db.scalar(
        select(Product).where(
            Product.id == product_id,
            Product.user_id == user.id,
        )
    )
    if product is None:
        raise _not_found()
    db.delete(product)
    try:
        db.commit()
    except IntegrityError as error:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "code": "product_has_sales",
                "message": "A product with recorded sales cannot be deleted.",
            },
        ) from error
    return Response(status_code=status.HTTP_204_NO_CONTENT)
