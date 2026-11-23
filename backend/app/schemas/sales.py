from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class CheckoutRequest(BaseModel):
    payment_method: str = Field(min_length=1, max_length=50)
    customer_name: str | None = Field(default=None, max_length=255)
    customer_phone: str | None = Field(default=None, max_length=50)
    description: str | None = None


class SaleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    sale_date: datetime
    total_amount: Decimal
    payment_status: str
    receipt_number: str
    payment_method: str
    description: str | None
    customer_name: str | None
    customer_phone: str | None


class SaleItemResponse(BaseModel):
    id: int
    sale_id: int
    product_id: int
    quantity: int
    unit_price: Decimal
    total_price: Decimal
    product_name: str
    product_code: str
    category: str | None
    unit: str
    image: str | None
