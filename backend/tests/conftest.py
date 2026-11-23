import os

import pytest
import httpx
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import make_url

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


@pytest.fixture
def auth_engine():
    database_url = os.getenv(
        "JAME_TEST_DATABASE_URL",
        "postgresql+psycopg://jame:jame_local_only@127.0.0.1:5435/jame_test",
    )
    parsed_url = make_url(database_url)
    if (
        parsed_url.host not in {"localhost", "127.0.0.1"}
        or parsed_url.database is None
        or not parsed_url.database.endswith("_test")
    ):
        pytest.fail("JAME_TEST_DATABASE_URL must target a local *_test database")

    engine = create_engine(database_url)
    try:
        yield engine
    finally:
        engine.dispose()


@pytest.fixture
def clean_auth_db(auth_engine):
    if "users" in inspect(auth_engine).get_table_names():
        with auth_engine.begin() as connection:
            connection.execute(
                text(
                    "TRUNCATE TABLE auth_rate_limits, password_reset_challenges, "
                    "sessions, users RESTART IDENTITY CASCADE"
                )
            )


@pytest.fixture
def auth_settings(auth_engine):
    return Settings(
        database_url=os.getenv(
            "JAME_TEST_DATABASE_URL",
            "postgresql+psycopg://jame:jame_local_only@127.0.0.1:5435/jame_test",
        ),
        session_secret="test-session-secret-that-is-long-enough",
        allowed_origins=["http://localhost:5000"],
        smtp_host="127.0.0.1",
        smtp_port=1025,
        smtp_from="noreply@jame.local",
    )


@pytest.fixture
def auth_client(auth_settings, clean_auth_db):
    with httpx.Client(base_url="http://127.0.0.1:8025", timeout=2) as mailpit:
        response = mailpit.delete("/api/v1/messages")
        response.raise_for_status()

    with TestClient(create_app(auth_settings)) as test_client:
        yield test_client


@pytest.fixture
def smtp_failure_client(auth_settings, clean_auth_db):
    failing_settings = auth_settings.model_copy(
        update={"smtp_port": 1}
    )
    with TestClient(create_app(failing_settings)) as test_client:
        yield test_client
