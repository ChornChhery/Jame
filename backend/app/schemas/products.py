from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class ProductCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    price: Decimal = Field(ge=0, max_digits=12, decimal_places=2)
    quantity: int = Field(default=0, ge=0)
    low_stock: int = Field(default=5, ge=0)
    code: str = Field(min_length=1, max_length=255)
    category: str | None = Field(default=None, max_length=255)
    unit: str = Field(default="pcs", min_length=1, max_length=50)
    image: str | None = None


class ProductUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    price: Decimal | None = Field(
        default=None, ge=0, max_digits=12, decimal_places=2
    )
    quantity: int | None = Field(default=None, ge=0)
    low_stock: int | None = Field(default=None, ge=0)
    code: str | None = Field(default=None, min_length=1, max_length=255)
    category: str | None = Field(default=None, max_length=255)
    unit: str | None = Field(default=None, min_length=1, max_length=50)
    image: str | None = None


class ProductResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    price: Decimal
    quantity: int
    low_stock: int
    code: str
    category: str | None
    unit: str
    image: str | None
    created_at: datetime
    updated_at: datetime
