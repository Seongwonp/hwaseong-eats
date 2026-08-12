from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.core.ratelimit import LOGIN_LIMIT, SIGNUP_LIMIT, limiter
from app.core.security import (
    PasswordTooLongError,
    create_access_token,
    hash_password,
    verify_password,
)
from app.database import get_db
from app.models import User
from app.schemas.auth import LoginRequest, SignupRequest, TokenResponse, UserResponse

router = APIRouter()

# 기획서 p.9 — 주민 인증은 6개월 유효라 매번 하지 않아도 된다.
RESIDENT_VERIFY_VALID = timedelta(days=182)


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit(SIGNUP_LIMIT)
def signup(request: Request, body: SignupRequest, db: Session = Depends(get_db)):
    exists = db.scalar(
        select(User.id).where(
            (User.login_id == body.login_id) | (User.nickname == body.nickname)
        )
    )
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "이미 사용 중인 아이디 또는 닉네임입니다")

    try:
        password_hash = hash_password(body.password)
    except PasswordTooLongError as e:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(e)) from e

    user = User(
        login_id=body.login_id, password_hash=password_hash, nickname=body.nickname
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/login", response_model=TokenResponse)
@limiter.limit(LOGIN_LIMIT)
def login(request: Request, body: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.login_id == body.login_id))

    # 아이디가 없는 것과 비밀번호가 틀린 것을 구분해서 알려주지 않는다.
    # 구분되면 어떤 아이디가 존재하는지 훑을 수 있다.
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "아이디 또는 비밀번호가 올바르지 않습니다"
        )

    return TokenResponse(access_token=create_access_token(user.id))


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user


@router.post("/verify", response_model=UserResponse)
def verify_resident(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """화성 주민 인증.

    실제 주민등록 확인 연동은 아직 없다. 데모에서는 호출하면 인증된 것으로 처리하고,
    유효기간만 기획서대로 6개월을 채워 둔다.
    """
    now = datetime.now(timezone.utc)
    user.is_resident_verified = True
    user.resident_verified_at = now
    user.resident_expires_at = now + RESIDENT_VERIFY_VALID
    db.commit()
    db.refresh(user)
    return user
