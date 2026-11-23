from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import User, utc_now
from app.schemas.users import ProfileUpdate, UserResponse


router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserResponse)
def get_profile(user: User = Depends(get_current_user)) -> User:
    return user


@router.patch("", response_model=UserResponse)
def update_profile(
    payload: ProfileUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> User:
    changes = payload.model_dump(exclude_unset=True)
    for field, value in changes.items():
        setattr(user, field, value)
    user.updated_at = utc_now()
    db.commit()
    db.refresh(user)
    return user
