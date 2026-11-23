import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from fastapi import HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.config import Settings
from app.models import AuthRateLimit, AuthSession, User


password_hasher = PasswordHasher()
SESSION_COOKIE = "jame_session"


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def keyed_hash(secret: str, value: str) -> str:
    return hmac.new(
        secret.encode("utf-8"), value.encode("utf-8"), hashlib.sha256
    ).hexdigest()


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password_hash: str, password: str) -> bool:
    try:
        return password_hasher.verify(password_hash, password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def create_session(
    db: Session,
    user: User,
    client_type: str,
    settings: Settings,
) -> tuple[AuthSession, str, str | None]:
    raw_token = secrets.token_urlsafe(32)
    csrf_token = secrets.token_urlsafe(32) if client_type == "web" else None
    auth_session = AuthSession(
        user_id=user.id,
        token_hash=hash_token(raw_token),
        csrf_token_hash=hash_token(csrf_token) if csrf_token else None,
        client_type=client_type,
        expires_at=utc_now() + timedelta(minutes=settings.session_ttl_minutes),
    )
    db.add(auth_session)
    return auth_session, raw_token, csrf_token


def rate_limit_key(settings: Settings, email: str, client_address: str) -> str:
    secret = settings.session_secret.get_secret_value()
    return keyed_hash(secret, f"{email.strip().lower()}:{client_address}")


def check_rate_limit(
    db: Session,
    key_hash: str,
    *,
    limit: int,
    window: timedelta,
) -> None:
    now = utc_now()
    record = db.scalar(
        select(AuthRateLimit)
        .where(AuthRateLimit.key_hash == key_hash)
        .with_for_update()
    )
    if record is None:
        db.add(
            AuthRateLimit(
                key_hash=key_hash,
                attempts=1,
                window_started_at=now,
            )
        )
        db.flush()
        return

    if record.blocked_until and record.blocked_until > now:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "rate_limited", "message": "Try again later."},
        )

    if now - record.window_started_at >= window:
        record.attempts = 0
        record.window_started_at = now
        record.blocked_until = None

    if record.attempts >= limit:
        record.blocked_until = now + window
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "rate_limited", "message": "Try again later."},
        )

    record.attempts += 1
    db.flush()


def client_address(request: Request) -> str:
    return request.client.host if request.client else "unknown"
