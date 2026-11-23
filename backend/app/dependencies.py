

import hmac

from fastapi import Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_db
from app.models import AuthSession, User
from app.security import SESSION_COOKIE, hash_token, utc_now


def get_current_session(
    request: Request,
    db: Session = Depends(get_db),
) -> AuthSession:
    authorization = request.headers.get("Authorization")
    token: str | None = None
    from_cookie = False

    if authorization:
        scheme, _, credential = authorization.partition(" ")
        if scheme.lower() != "bearer" or not credential:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={"code": "unauthorized", "message": "Authentication required."},
            )
        token = credential
    else:
        token = request.cookies.get(SESSION_COOKIE)
        from_cookie = token is not None

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "unauthorized", "message": "Authentication required."},
        )

    auth_session = db.scalar(
        select(AuthSession)
        .where(
            AuthSession.token_hash == hash_token(token),
            AuthSession.revoked_at.is_(None),
            AuthSession.expires_at > utc_now(),
        )
    )
    if auth_session is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "unauthorized", "message": "Authentication required."},
        )

    request.state.auth_session = auth_session
    request.state.auth_from_cookie = from_cookie
    return auth_session


def get_current_user(
    request: Request,
    auth_session: AuthSession = Depends(get_current_session),
    db: Session = Depends(get_db),
) -> User:
    if (
        getattr(request.state, "auth_from_cookie", False)
        and request.method in {"POST", "PUT", "PATCH", "DELETE"}
    ):
        supplied = request.headers.get("X-CSRF-Token", "")
        expected = auth_session.csrf_token_hash or ""
        if not supplied or not hmac.compare_digest(
            hash_token(supplied), expected
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={"code": "csrf_invalid", "message": "CSRF token is invalid."},
            )

    user = db.get(User, auth_session.user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "unauthorized", "message": "Authentication required."},
        )
    return user
