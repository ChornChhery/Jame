import pytest
from pydantic import ValidationError

from app.config import Settings


def test_health_returns_ok_without_database(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ready_requires_database(client):
    response = client.get("/ready")

    assert response.status_code == 503
    assert response.json() == {"detail": "database unavailable"}


def test_settings_require_server_database_configuration(monkeypatch):
    monkeypatch.delenv("DATABASE_URL", raising=False)

    with pytest.raises(ValidationError):
        Settings(_env_file=None)


def test_settings_do_not_load_repository_dotenv(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("DATABASE_URL", raising=False)
    monkeypatch.delenv("SESSION_SECRET", raising=False)
    (tmp_path / ".env").write_text(
        "DATABASE_URL=postgresql+psycopg://unused:unused@localhost/unused\n"
        "SESSION_SECRET=temporary-test-secret-that-is-long-enough\n"
    )

    with pytest.raises(ValidationError):
        Settings()


def test_cors_allows_only_configured_origins(settings):
    from fastapi.testclient import TestClient

    from app.main import create_app

    with TestClient(create_app(settings)) as client:
        allowed = client.options(
            "/health",
            headers={
                "Origin": "http://localhost:5000",
                "Access-Control-Request-Method": "POST",
            },
        )
        disallowed = client.options(
            "/health",
            headers={
                "Origin": "http://evil.example",
                "Access-Control-Request-Method": "POST",
            },
        )

    assert allowed.headers["access-control-allow-origin"] == "http://localhost:5000"
    assert allowed.headers["access-control-allow-credentials"] == "true"
    assert "access-control-allow-origin" not in disallowed.headers
