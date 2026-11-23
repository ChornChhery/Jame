import hmac
import secrets
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.config import Settings
from app.db import get_db
from app.dependencies import get_current_session, get_current_user
from app.models import AuthSession, PasswordResetChallenge, User
from app.schemas.auth import (
    AuthResponse,
    LoginRequest,
    PasswordResetConfirm,
    PasswordResetRequest,
    RegisterRequest,
)
from app.schemas.users import UserResponse
from app.security import (
    SESSION_COOKIE,
    check_rate_limit,
    client_address,
    create_session,
    hash_password,
    hash_token,
    keyed_hash,
    rate_limit_key,
    utc_now,
    verify_password,
)
from app.services.email import EmailDeliveryError, EmailService


router = APIRouter(prefix="/auth", tags=["authentication"])
RESET_RESPONSE = {
    "message": "If the account exists, a verification code will be sent."
}
RESET_FAILURE = {
    "code": "recovery_unavailable",
    "message": "Password recovery is temporarily unavailable.",
}
RESET_CODE_TTL = timedelta(minutes=15)
RESET_MAX_ATTEMPTS = 5


def _settings(request: Request) -> Settings:
    return request.app.state.settings


def _set_session_cookie(
    response: Response,
    token: str,
    settings: Settings,
) -> None:
    response.set_cookie(
        key=SESSION_COOKIE,
        value=token,
        httponly=True,
        secure=settings.cookie_secure or settings.environment == "production",
        samesite="lax",
        max_age=settings.session_ttl_minutes * 60,
        path="/",
    )


def _create_auth_response(
    db: Session,
    user: User,
    client_type: str,
    settings: Settings,
    response: Response,
) -> AuthResponse:
    auth_session, raw_token, csrf_token = create_session(
        db, user, client_type, settings
    )
    db.commit()
    db.refresh(auth_session)
    db.refresh(user)
    if client_type == "web":
        _set_session_cookie(response, raw_token, settings)
        access_token = None
    else:
        access_token = raw_token
    return AuthResponse(
        user=UserResponse.model_validate(user),
        csrf_token=csrf_token,
        access_token=access_token,
        token_type="Bearer" if access_token else None,
        expires_in=max(0, int((auth_session.expires_at - utc_now()).total_seconds())),
    )


def _validation_error(code: str, message: str, status_code: int) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={"code": code, "message": message},
    )


@router.post("/register", response_model=AuthResponse, status_code=201)
def register(
    payload: RegisterRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
) -> AuthResponse:
    user = User(
        username=payload.username,
        email=payload.email,
        password_hash=hash_password(payload.password),
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
        shop_name=payload.shop_name.strip(),
        shop_address=payload.shop_address,
        shop_phone=payload.shop_phone,
        shop_email=payload.shop_email.lower() if payload.shop_email else None,
    )
    db.add(user)
    try:
        db.flush()
    except IntegrityError as error:
        db.rollback()
        raise _validation_error(
            "account_conflict",
            "That email or username is already registered.",
            status.HTTP_409_CONFLICT,
        ) from error
    return _create_auth_response(
        db,
        user,
        payload.client_type,
        _settings(request),
        response,
    )


@router.post("/login", response_model=AuthResponse)
def login(
    payload: LoginRequest,
    request: Request,
    response: Response,
    db: Session = Depends(get_db),
) -> AuthResponse:
    settings = _settings(request)
    key = rate_limit_key(settings, payload.email, client_address(request))
    check_rate_limit(db, key, limit=10, window=timedelta(minutes=15))
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not verify_password(user.password_hash, payload.password):
        db.commit()
        raise _validation_error(
            "invalid_credentials",
            "Email or password is incorrect.",
            status.HTTP_401_UNAUTHORIZED,
        )
    db.commit()
    return _create_auth_response(db, user, payload.client_type, settings, response)


@router.get("/session")
def restore_session(
    request: Request,
    auth_session: AuthSession = Depends(get_current_session),
    db: Session = Depends(get_db),
) -> dict[str, object]:
    user = db.get(User, auth_session.user_id)
    if user is None:
        raise _validation_error(
            "unauthorized", "Authentication required.", status.HTTP_401_UNAUTHORIZED
        )

    csrf_token = None
    if getattr(request.state, "auth_from_cookie", False):
        csrf_token = secrets.token_urlsafe(32)
        auth_session.csrf_token_hash = hash_token(csrf_token)
        db.commit()

    return {"user": UserResponse.model_validate(user), "csrf_token": csrf_token}


@router.post("/refresh", response_model=AuthResponse)
def refresh_session(
    request: Request,
    response: Response,
    auth_session: AuthSession = Depends(get_current_session),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AuthResponse:
    settings = _settings(request)
    auth_session.revoked_at = utc_now()
    return _create_auth_response(
        db, user, auth_session.client_type, settings, response
    )


@router.post("/logout", status_code=204)
def logout(
    response: Response,
    auth_session: AuthSession = Depends(get_current_session),
    _: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Response:
    auth_session.revoked_at = utc_now()
    db.commit()
    response.delete_cookie(
        key=SESSION_COOKIE,
        httponly=True,
        samesite="lax",
        path="/",
    )
    response.status_code = status.HTTP_204_NO_CONTENT
    return response


@router.post("/password-reset/request", status_code=202)
def request_password_reset(
    payload: PasswordResetRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> dict[str, str]:
    settings = _settings(request)
    key = rate_limit_key(settings, payload.email, client_address(request))
    check_rate_limit(db, key, limit=5, window=timedelta(hours=1))
    db.commit()

    email_service = EmailService(settings)
    try:
        email_service.check_delivery_ready()
    except EmailDeliveryError as error:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=RESET_FAILURE,
        ) from error

    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None:
        return RESET_RESPONSE

    now = utc_now()
    db.query(PasswordResetChallenge).filter(
        PasswordResetChallenge.user_id == user.id,
        PasswordResetChallenge.used_at.is_(None),
    ).update({"used_at": now}, synchronize_session=False)
    code = f"{secrets.randbelow(1_000_000):06d}"
    secret = settings.session_secret.get_secret_value()
    challenge = PasswordResetChallenge(
        user_id=user.id,
        code_hash=keyed_hash(secret, f"reset:{user.id}:{code}"),
        expires_at=now + RESET_CODE_TTL,
    )
    db.add(challenge)
    db.commit()

    try:
        email_service.send_recovery_code(user.email, code)
    except EmailDeliveryError as error:
        challenge.used_at = utc_now()
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=RESET_FAILURE,
        ) from error

    return RESET_RESPONSE


@router.post("/password-reset/confirm")
def confirm_password_reset(
    payload: PasswordResetConfirm,
    request: Request,
    db: Session = Depends(get_db),
) -> dict[str, str]:
    settings = _settings(request)
    key = rate_limit_key(settings, payload.email, client_address(request))
    check_rate_limit(db, key, limit=10, window=timedelta(hours=1))
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None:
        db.commit()
        raise _validation_error(
            "invalid_or_expired_code",
            "The verification code is invalid or expired.",
            status.HTTP_400_BAD_REQUEST,
        )

    challenge = db.scalar(
        select(PasswordResetChallenge)
        .where(
            PasswordResetChallenge.user_id == user.id,
            PasswordResetChallenge.used_at.is_(None),
        )
        .order_by(PasswordResetChallenge.created_at.desc())
        .with_for_update()
    )
    now = utc_now()
    expected_hash = (
        keyed_hash(
            settings.session_secret.get_secret_value(),
            f"reset:{user.id}:{payload.code}",
        )
        if challenge is not None
        else ""
    )
    valid = (
        challenge is not None
        and challenge.expires_at > now
        and challenge.attempts < RESET_MAX_ATTEMPTS
        and hmac.compare_digest(challenge.code_hash, expected_hash)
    )
    if not valid:
        if challenge is not None:
            challenge.attempts += 1
            if challenge.attempts >= RESET_MAX_ATTEMPTS or challenge.expires_at <= now:
                challenge.used_at = now
        db.commit()
        raise _validation_error(
            "invalid_or_expired_code",
            "The verification code is invalid or expired.",
            status.HTTP_400_BAD_REQUEST,
        )

    challenge.used_at = now
    user.password_hash = hash_password(payload.new_password)
    db.query(AuthSession).filter(
        AuthSession.user_id == user.id,
        AuthSession.revoked_at.is_(None),
    ).update({"revoked_at": now}, synchronize_session=False)
    db.commit()
    return {"status": "password_updated"}
