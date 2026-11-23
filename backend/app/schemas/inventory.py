from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class StockAdjustment(BaseModel):
    product_id: int = Field(gt=0)
    new_quantity: int = Field(ge=0)
    change_type: Literal["STOCK_IN", "ADJUSTMENT"]
    reference_id: int | None = Field(default=None, gt=0)
    notes: str | None = None


class InventoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    product_id: int
    change_type: str
    stock_before: int
    stock_after: int
    reference_id: int | None
    notes: str | None
    created_at: datetime
