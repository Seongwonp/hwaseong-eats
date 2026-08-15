from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.core.ratelimit import EXCHANGE_LIMIT, LOGIN_LIMIT, SIGNUP_LIMIT, limiter
from app.core.security import (
    PasswordTooLongError,
    create_access_token,
    hash_password,
    verify_password,
)
from app.database import get_db
from app.models import PointHistory, User
from app.schemas.auth import LoginRequest, SignupRequest, TokenResponse, UserResponse
from app.schemas.point import (
    ExchangeRequest,
    ExchangeResponse,
    PointHistoryListResponse,
)
from app.services.points import InsufficientPointsError, add_points

router = APIRouter()

# 기획서 p.9 — 주민 인증은 6개월 유효라 매번 하지 않아도 된다.
RESIDENT_VERIFY_VALID = timedelta(days=182)


@router.post("/signup", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit(SIGNUP_LIMIT)
def signup(request: Request, body: SignupRequest, db: Session = Depends(get_db)):
    exists = db.scalar(
        select(User.id).where(
            (User.email == body.email) | (User.nickname == body.nickname)
        )
    )
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "이미 사용 중인 이메일 또는 닉네임입니다")

    try:
        password_hash = hash_password(body.password)
    except PasswordTooLongError as e:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, str(e)) from e

    user = User(
        email=body.email, password_hash=password_hash, nickname=body.nickname
    )
    db.add(user)
    try:
        db.commit()
    except IntegrityError as e:
        # 위 조회와 여기 사이에 같은 이메일로 다른 요청이 먼저 들어올 수 있다.
        # 최종 판정은 DB 유니크 제약에 맡긴다.
        db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT, "이미 사용 중인 이메일 또는 닉네임입니다"
        ) from e
    db.refresh(user)

    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/login", response_model=TokenResponse)
@limiter.limit(LOGIN_LIMIT)
def login(request: Request, body: LoginRequest, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == body.email))

    # 계정이 없는 것과 비밀번호가 틀린 것을 구분해서 알려주지 않는다.
    # 구분되면 어떤 이메일이 가입돼 있는지 훑을 수 있다.
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다"
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


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    user: User = Depends(get_current_user), db: Session = Depends(get_db)
):
    """회원 탈퇴. 리뷰·포인트 내역은 CASCADE로 함께 삭제된다."""
    db.delete(user)
    db.commit()


@router.get("/me/points", response_model=PointHistoryListResponse)
def point_history(
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """포인트 적립·사용 내역. 최신순."""
    total = db.scalar(
        select(func.count()).select_from(PointHistory).where(PointHistory.user_id == user.id)
    )
    items = db.scalars(
        select(PointHistory)
        .where(PointHistory.user_id == user.id)
        .order_by(PointHistory.created_at.desc(), PointHistory.id.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    return PointHistoryListResponse(total=total, balance=user.points, items=items)


@router.post("/me/points/exchange", response_model=ExchangeResponse)
@limiter.limit(EXCHANGE_LIMIT)
def exchange_points(
    request: Request,
    body: ExchangeRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """포인트를 화성페이로 전환한다. 1,000P = 1,000원.

    실제 화성페이 지급 연동은 없다. 포인트 차감과 내역 기록까지만 한다.
    """
    try:
        add_points(db, user.id, -body.points, "화성페이 전환")
    except InsufficientPointsError as e:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            f"포인트가 부족합니다 (보유 {user.points}P, 요청 {body.points}P)",
        ) from e

    db.commit()
    db.refresh(user)

    return ExchangeResponse(
        exchanged_points=body.points,
        exchanged_krw=body.points,  # 1P = 1원
        balance=user.points,
    )
