from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    username: str
    email: str
    first_name: str
    last_name: str
    shop_name: str
    shop_address: str | None
    shop_phone: str | None
    shop_email: str | None
    currency: str
    payment_qr: str | None
    profile_image: str | None
    created_at: datetime
    updated_at: datetime


class ProfileUpdate(BaseModel):
    first_name: str | None = Field(default=None, min_length=1, max_length=128)
    last_name: str | None = Field(default=None, min_length=1, max_length=128)
    shop_name: str | None = Field(default=None, min_length=1, max_length=255)
    shop_address: str | None = None
    shop_phone: str | None = Field(default=None, max_length=50)
    shop_email: str | None = Field(default=None, max_length=320)
    currency: str | None = Field(default=None, min_length=1, max_length=10)
    payment_qr: str | None = None
    profile_image: str | None = None
