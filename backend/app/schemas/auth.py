from typing import Literal

from pydantic import BaseModel, Field, field_validator

from app.schemas.users import UserResponse


def normalize_email(value: str) -> str:
    email = value.strip().lower()
    if "@" not in email or email.startswith("@") or email.endswith("@"):
        raise ValueError("A valid email address is required")
    return email


class RegisterRequest(BaseModel):
    username: str = Field(min_length=3, max_length=128)
    email: str = Field(max_length=320)
    password: str = Field(min_length=8, max_length=256)
    first_name: str = Field(min_length=1, max_length=128)
    last_name: str = Field(min_length=1, max_length=128)
    shop_name: str = Field(min_length=1, max_length=255)
    shop_address: str | None = None
    shop_phone: str | None = Field(default=None, max_length=50)
    shop_email: str | None = Field(default=None, max_length=320)
    client_type: Literal["web", "native"] = "web"

    @field_validator("username")
    @classmethod
    def normalize_username(cls, value: str) -> str:
        return value.strip()

    @field_validator("email")
    @classmethod
    def validate_gmail(cls, value: str) -> str:
        email = normalize_email(value)
        if not email.endswith("@gmail.com"):
            raise ValueError("gmail_required")
        return email


class LoginRequest(BaseModel):
    email: str = Field(max_length=320)
    password: str = Field(min_length=1, max_length=256)
    client_type: Literal["web", "native"] = "web"

    @field_validator("email")
    @classmethod
    def validate_gmail(cls, value: str) -> str:
        email = normalize_email(value)
        if not email.endswith("@gmail.com"):
            raise ValueError("gmail_required")
        return email


class PasswordResetRequest(BaseModel):
    email: str = Field(max_length=320)

    @field_validator("email")
    @classmethod
    def normalize(cls, value: str) -> str:
        return normalize_email(value)


class PasswordResetConfirm(BaseModel):
    email: str = Field(max_length=320)
    code: str = Field(pattern=r"^\d{6}$")
    new_password: str = Field(min_length=8, max_length=256)

    @field_validator("email")
    @classmethod
    def normalize(cls, value: str) -> str:
        return normalize_email(value)


class AuthResponse(BaseModel):
    user: UserResponse
    csrf_token: str | None = None
    access_token: str | None = None
    token_type: str | None = None
    expires_in: int
