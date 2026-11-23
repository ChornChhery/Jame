import os

import pytest
from fastapi.testclient import TestClient

os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+psycopg://jame:test@127.0.0.1:1/jame_test?connect_timeout=1",
)
os.environ.setdefault("SESSION_SECRET", "test-session-secret-that-is-long-enough")

from app.config import Settings
from app.main import create_app


@pytest.fixture
def settings() -> Settings:
    return Settings(
        database_url=(
            "postgresql+psycopg://jame:test@127.0.0.1:1/"
            "jame_test?connect_timeout=1"
        ),
        allowed_origins=["http://localhost:5000"],
        session_secret="test-session-secret-that-is-long-enough",
    )


@pytest.fixture
def client(settings: Settings) -> TestClient:
    with TestClient(create_app(settings)) as test_client:
        yield test_client
