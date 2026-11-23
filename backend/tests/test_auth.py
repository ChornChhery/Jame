import json
import re
from datetime import datetime, timedelta, timezone

import httpx
import pytest
from argon2 import PasswordHasher
from sqlalchemy import text


REGISTER_BODY = {
    "username": "shop-owner",
    "email": "owner@gmail.com",
    "password": "JamePass123!",
    "first_name": "Shop",
    "last_name": "Owner",
    "shop_name": "Jame Shop",
}


def register(client, **overrides):
    return client.post(
        "/api/v1/auth/register",
        json={**REGISTER_BODY, **overrides},
    )


def reset_code_from_mailpit() -> str:
    messages = httpx.get(
        "http://127.0.0.1:8025/api/v1/messages", timeout=2
    ).json()["messages"]
    assert messages, "Mailpit did not receive a recovery email"
    latest = messages[-1]
    details = httpx.get(
        f"http://127.0.0.1:8025/api/v1/message/{latest['ID']}",
        timeout=2,
    ).json()
    match = re.search(r"\b\d{6}\b", details.get("Text", ""))
    assert match, "Recovery email did not contain a six-digit code"
    return match.group()


def test_register_hashes_password_and_never_returns_hash(auth_client, auth_engine):
    response = register(auth_client)

    assert response.status_code == 201
    response_text = json.dumps(response.json()).lower()
    assert "password_hash" not in response_text
    assert REGISTER_BODY["password"] not in response_text
    assert response.cookies.get("jame_session")
    assert "httponly" in response.headers["set-cookie"].lower()
    assert "samesite=lax" in response.headers["set-cookie"].lower()

    with auth_engine.connect() as connection:
        user = connection.execute(
            text("SELECT password_hash FROM users WHERE email = :email"),
            {"email": REGISTER_BODY["email"]},
        ).one()
        session_count = connection.execute(
            text("SELECT count(*) FROM sessions")
        ).scalar_one()

    assert PasswordHasher().verify(user.password_hash, REGISTER_BODY["password"])
    assert session_count == 1


def test_register_rejects_non_gmail_email(auth_client):
    response = register(auth_client, email="owner@example.com")

    assert response.status_code == 422
    assert "gmail_required" in json.dumps(response.json())


def test_native_auth_returns_bearer_without_browser_cookie(auth_client):
    response = register(auth_client, client_type="native")

    assert response.status_code == 201
    assert response.json()["access_token"]
    assert response.json()["token_type"] == "Bearer"
    assert response.cookies.get("jame_session") is None


def test_session_restore_returns_user_and_rotated_csrf_token(auth_client):
    registration = register(auth_client)

    response = auth_client.get("/api/v1/auth/session")

    assert registration.status_code == 201
    assert response.status_code == 200
    assert response.json()["user"]["email"] == REGISTER_BODY["email"]
    assert response.json()["csrf_token"]


def test_cookie_mutation_requires_csrf_token(auth_client):
    registration = register(auth_client)
    assert registration.status_code == 201

    without_csrf = auth_client.patch(
        "/api/v1/profile",
        json={"shop_name": "Changed Shop"},
    )
    with_csrf = auth_client.patch(
        "/api/v1/profile",
        json={"shop_name": "Changed Shop"},
        headers={"X-CSRF-Token": registration.json()["csrf_token"]},
    )

    assert without_csrf.status_code == 403
    assert with_csrf.status_code == 200
    assert with_csrf.json()["shop_name"] == "Changed Shop"


def test_password_reset_is_generic_expiring_and_single_use(
    auth_client, auth_engine
):
    registration = register(auth_client)
    assert registration.status_code == 201

    known_email = auth_client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": REGISTER_BODY["email"]},
    )
    code = reset_code_from_mailpit()
    unknown_email = auth_client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "unknown@gmail.com"},
    )

    assert known_email.status_code == unknown_email.status_code == 202
    assert known_email.json() == unknown_email.json()
    assert not re.search(r"\b\d{6}\b", json.dumps(known_email.json()))

    confirmation = auth_client.post(
        "/api/v1/auth/password-reset/confirm",
        json={
            "email": REGISTER_BODY["email"],
            "code": code,
            "new_password": "NewJamePass456!",
        },
    )
    new_password_login = auth_client.post(
        "/api/v1/auth/login",
        json={
            "email": REGISTER_BODY["email"],
            "password": "NewJamePass456!",
        },
    )
    replay = auth_client.post(
        "/api/v1/auth/password-reset/confirm",
        json={
            "email": REGISTER_BODY["email"],
            "code": code,
            "new_password": "AnotherJamePass789!",
        },
    )

    assert confirmation.status_code == 200
    assert new_password_login.status_code == 200
    assert replay.status_code == 400

    auth_client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": REGISTER_BODY["email"]},
    )
    expired_code = reset_code_from_mailpit()
    with auth_engine.begin() as connection:
        connection.execute(
            text(
                "UPDATE password_reset_challenges "
                "SET expires_at = :expired "
                "WHERE used_at IS NULL AND user_id = "
                "(SELECT id FROM users WHERE email = :email)"
            ),
            {
                "expired": datetime.now(timezone.utc) - timedelta(minutes=1),
                "email": REGISTER_BODY["email"],
            },
        )

    expired = auth_client.post(
        "/api/v1/auth/password-reset/confirm",
        json={
            "email": REGISTER_BODY["email"],
            "code": expired_code,
            "new_password": "ExpiredJamePass456!",
        },
    )
    assert expired.status_code == 400


def test_smtp_failure_is_not_reported_as_delivered(
    auth_client, smtp_failure_client
):
    registration = register(auth_client)
    assert registration.status_code == 201

    known = smtp_failure_client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": REGISTER_BODY["email"]},
    )
    unknown = smtp_failure_client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "unknown@gmail.com"},
    )

    assert known.status_code == unknown.status_code == 503
    assert known.json() == unknown.json()
    assert "delivered" not in json.dumps(known.json()).lower()
