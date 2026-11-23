from decimal import Decimal

from pydantic import BaseModel, Field


class CartItemUpdate(BaseModel):
    quantity: int = Field(gt=0)


class CartItemResponse(BaseModel):
    product_id: int
    name: str
    code: str
    quantity: int
    unit_price: Decimal
    total_price: Decimal
    available_quantity: int
    category: str | None
    unit: str
    image: str | None
