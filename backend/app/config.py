from functools import lru_cache

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
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
    smtp_from: str = "noreply@jame.local"
    environment: str = "development"
    cookie_secure: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
