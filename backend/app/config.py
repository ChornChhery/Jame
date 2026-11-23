from functools import lru_cache

from pydantic import SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore",
        case_sensitive=False,
    )

    database_url: str
    session_secret: SecretStr
    allowed_origins: list[str] = [
        "http://localhost:5000",
        "http://localhost:8080",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8080",
    ]
    smtp_host: str = "localhost"
    smtp_port: int = 1025
    smtp_username: str | None = None
    smtp_password: SecretStr | None = None
    smtp_use_tls: bool = False
    smtp_from: str = "noreply@jame.local"
    environment: str = "development"
    cookie_secure: bool = False
    session_ttl_minutes: int = 720

    @field_validator("session_secret")
    @classmethod
    def require_long_session_secret(cls, value: SecretStr) -> SecretStr:
        if len(value.get_secret_value()) < 32:
            raise ValueError("SESSION_SECRET must contain at least 32 characters")
        return value

    @model_validator(mode="after")
    def require_production_email_security(self) -> "Settings":
        if self.environment == "production":
            if not self.smtp_host or not self.smtp_username or not self.smtp_password:
                raise ValueError("Production SMTP settings are required")
            if not self.smtp_use_tls or not self.cookie_secure:
                raise ValueError("Production requires SMTP TLS and secure cookies")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
