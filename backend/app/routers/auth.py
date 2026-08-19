import os
import secrets
from datetime import datetime, timedelta, timezone

import httpx
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.deps import get_current_user
from app.core.ratelimit import (
    EXCHANGE_LIMIT,
    LOGIN_LIMIT,
    NICKNAME_LIMIT,
    SIGNUP_LIMIT,
    VERIFY_LIMIT,
    limiter,
)
from app.core.security import (
    PasswordTooLongError,
    create_access_token,
    hash_password,
    verify_password,
)
from app.database import get_db
from app.models import PointHistory, User
from app.schemas.auth import KakaoLoginRequest, LoginRequest, NicknameUpdateRequest, SignupRequest, TokenResponse, UserResponse
from app.schemas.point import (
    ExchangeRequest,
    ExchangeResponse,
    PointHistoryListResponse,
)
from app.services.points import InsufficientPointsError, add_points

router = APIRouter()

# 기획서 p.9 — 주민 인증은 6개월 유효라 매번 하지 않아도 된다.
RESIDENT_VERIFY_VALID = timedelta(days=182)


def _kakao_app_id() -> int:
    """카카오 앱 ID. 카카오 개발자 콘솔 > 앱 설정 > 요약 정보 의 숫자 ID 다.

    security.py 의 _secret() 과 같이 호출 시점에 읽는다. 임포트 시점에 읽으면
    이 값이 필요 없는 테스트와 배치 스크립트까지 같이 죽는다.
    """
    raw = os.getenv("KAKAO_APP_ID")
    if not raw:
        raise RuntimeError("KAKAO_APP_ID 가 없습니다. backend/.env 를 확인하세요.")
    try:
        return int(raw)
    except ValueError as e:
        raise RuntimeError(f"KAKAO_APP_ID 가 숫자가 아닙니다: {raw!r}") from e


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
    # password_hash가 None이면 카카오 전용 계정이므로 같은 오류로 처리한다.
    if user is None or user.password_hash is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status.HTTP_401_UNAUTHORIZED, "이메일 또는 비밀번호가 올바르지 않습니다"
        )

    return TokenResponse(access_token=create_access_token(user.id))


@router.post("/kakao", response_model=TokenResponse)
@limiter.limit(LOGIN_LIMIT)
def kakao_login(request: Request, body: KakaoLoginRequest, db: Session = Depends(get_db)):
    """카카오 소셜 로그인.

    앱에서 받은 카카오 액세스 토큰의 발급처를 확인한 뒤,
    기존 계정이 있으면 로그인, 없으면 신규 계정을 생성한다.

    /v2/user/me 가 아니라 /v1/user/access_token_info 를 쓴다. 전자는 토큰이 유효한
    카카오 토큰인지만 알려주고 어느 앱에서 발급됐는지는 알려주지 않는다. 그러면 다른
    카카오 앱에서 발급된 토큰으로도 로그인이 되어버린다. 후자는 회원번호와 함께 app_id
    를 돌려주므로 우리 앱 토큰인지 확인할 수 있다. 닉네임은 어차피 랜덤 생성이라
    프로필 조회가 필요 없고, 호출 횟수도 그대로 1회다.
    """
    expected_app_id = _kakao_app_id()

    try:
        resp = httpx.get(
            "https://kapi.kakao.com/v1/user/access_token_info",
            headers={"Authorization": f"Bearer {body.access_token}"},
            timeout=10.0,
        )
    except httpx.RequestError as e:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "카카오 서버에 연결할 수 없습니다") from e

    if resp.status_code == 401:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "카카오 인증에 실패했습니다")
    if resp.status_code == 429:
        raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "카카오 서버가 요청을 제한하고 있습니다")
    if resp.status_code != 200:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "카카오 서버 오류가 발생했습니다")

    try:
        data = resp.json()
        kakao_id = int(data["id"])
        app_id = int(data["app_id"])
    except Exception as e:
        raise HTTPException(status.HTTP_502_BAD_GATEWAY, "카카오 응답을 파싱할 수 없습니다") from e

    # 다른 앱에서 발급된 토큰은 우리 회원번호 체계와 무관하다. 401 로 막는다.
    if app_id != expected_app_id:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "카카오 인증에 실패했습니다")

    # 기존 카카오 계정이면 바로 토큰 발급
    user = db.scalar(select(User).where(User.kakao_id == kakao_id))
    if user:
        return TokenResponse(access_token=create_access_token(user.id))

    # 신규 가입 — 랜덤 닉네임 자동 생성 후 commit까지 최대 5회 재시도
    for _ in range(5):
        nickname = f"볏섬{secrets.token_hex(4)}"
        while db.scalar(select(User.id).where(User.nickname == nickname)):
            nickname = f"볏섬{secrets.token_hex(4)}"

        user = User(kakao_id=kakao_id, nickname=nickname)
        db.add(user)
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
            # 동일 kakao_id가 먼저 커밋됐으면 해당 계정으로 로그인
            existing = db.scalar(select(User).where(User.kakao_id == kakao_id))
            if existing:
                return TokenResponse(access_token=create_access_token(existing.id))
            # 닉네임 충돌이면 다음 루프에서 새 닉네임으로 재시도
            continue
        db.refresh(user)
        return TokenResponse(access_token=create_access_token(user.id))

    raise HTTPException(status.HTTP_503_SERVICE_UNAVAILABLE, "잠시 후 다시 시도해 주세요")


@router.get("/me", response_model=UserResponse)
def me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=UserResponse)
@limiter.limit(NICKNAME_LIMIT)
def update_me(
    request: Request,
    body: NicknameUpdateRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """닉네임 변경. 이미 사용 중인 닉네임이면 409."""
    if body.nickname == user.nickname:
        return user
    user.nickname = body.nickname
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "이미 사용 중인 닉네임입니다")
    db.refresh(user)
    return user


@router.post("/verify", response_model=UserResponse)
@limiter.limit(VERIFY_LIMIT)
def verify_resident(
    request: Request,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
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
