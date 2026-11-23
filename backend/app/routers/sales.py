from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import Product, Sale, SaleItem, User
from app.schemas.sales import CheckoutRequest, SaleItemResponse, SaleResponse
from app.services.checkout import checkout


router = APIRouter(prefix="/sales", tags=["sales"])


def _sale_not_found() -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail={"code": "sale_not_found", "message": "Sale not found."},
    )


@router.post(
    "/checkout",
    response_model=SaleResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_checkout(
    payload: CheckoutRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Sale:
    return checkout(db, user, payload)


@router.get("", response_model=list[SaleResponse])
def list_sales(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Sale]:
    return list(
        db.scalars(
            select(Sale)
            .where(Sale.user_id == user.id)
            .order_by(Sale.sale_date.desc(), Sale.id.desc())
        )
    )


@router.get(
    "/{sale_id}/items",
    response_model=list[SaleItemResponse],
)
def get_sale_items(
    sale_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[SaleItemResponse]:
    sale = db.scalar(
        select(Sale).where(Sale.id == sale_id, Sale.user_id == user.id)
    )
    if sale is None:
        raise _sale_not_found()

    rows = db.execute(
        select(SaleItem, Product)
        .join(Product, Product.id == SaleItem.product_id)
        .where(SaleItem.sale_id == sale.id, Product.user_id == user.id)
        .order_by(SaleItem.id)
    )
    return [
        SaleItemResponse(
            id=item.id,
            sale_id=item.sale_id,
            product_id=item.product_id,
            quantity=item.quantity,
            unit_price=item.unit_price,
            total_price=item.total_price,
            product_name=product.name,
            product_code=product.code,
            category=product.category,
            unit=product.unit,
            image=product.image,
        )
        for item, product in rows
    ]
