from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.constants import REVIEW_POINTS
from app.core.deps import get_current_user
from app.database import get_db
from app.models import Restaurant, Review, User
from app.models.restaurant import visible_filters
from app.schemas.review import (
    ReviewCreate,
    ReviewCreateResponse,
    ReviewListResponse,
    ReviewResponse,
)
from app.services.points import add_points, revoke_points

router = APIRouter()


def _is_certified(user: User, review: Review) -> bool:
    """화성인증 리뷰인지. 주민인증이 살아 있고 영수증까지 확인된 경우만.

    만료 판정은 User.is_resident_active 한 곳에서만 한다.
    """
    return bool(review.is_receipt_verified and user.is_resident_active)


def _to_response(review: Review, user: User) -> ReviewResponse:
    return ReviewResponse(
        id=review.id,
        restaurant_id=review.restaurant_id,
        user_id=review.user_id,
        nickname=user.nickname,
        tags=review.tags,
        rating=review.rating,
        comment=review.comment,
        is_receipt_verified=review.is_receipt_verified,
        is_hwaseong_certified=_is_certified(user, review),
        created_at=review.created_at,
    )


@router.post("", response_model=ReviewCreateResponse, status_code=status.HTTP_201_CREATED)
def create_review(
    body: ReviewCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """식사평 등록.

    화성인증(주민인증 + 영수증) 리뷰만 포인트를 준다. 기획서 p.10 기준이다.
    """
    # 목록·상세와 같은 노출 기준을 본다. 그냥 db.get 으로 확인하면 지도에 없고
    # 상세조회도 404 인 가게(좌표 미확보·중복으로 내려둔 행)에 식사평이 달린다.
    exists_visible = db.scalar(
        select(Restaurant.id).where(
            Restaurant.id == body.restaurant_id, *visible_filters()
        )
    )
    if not exists_visible:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "음식점을 찾을 수 없습니다")

    review = Review(
        restaurant_id=body.restaurant_id,
        user_id=user.id,
        tags=body.tags or None,
        rating=body.rating,
        comment=body.comment,
        # 영수증 검증 결과는 클라이언트 입력을 신뢰하지 않는다.
        # 검증 파이프라인이 생기기 전까지 모든 신규 리뷰는 미인증이다.
        is_receipt_verified=False,
        receipt_image_url=None,
    )
    db.add(review)

    try:
        db.flush()
    except IntegrityError as e:
        db.rollback()
        # uq_reviews_user_restaurant. 같은 가게에 반복 작성해 포인트를 만드는 걸 막는다.
        raise HTTPException(
            status.HTTP_409_CONFLICT, "이미 이 음식점에 식사평을 남겼습니다"
        ) from e

    earned = REVIEW_POINTS if _is_certified(user, review) else 0
    review.earned_points = earned
    if earned:
        add_points(db, user.id, earned, "화성인증 식사평")

    db.commit()
    db.refresh(review)
    db.refresh(user)

    return ReviewCreateResponse(
        review=_to_response(review, user),
        earned_points=earned,
        total_points=user.points,
    )


@router.get("", response_model=ReviewListResponse)
def list_reviews(
    restaurant_id: int | None = Query(None, description="음식점별 조회"),
    certified_only: bool = Query(False, description="화성인증 식사평만"),
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    filters = []
    if restaurant_id is not None:
        filters.append(Review.restaurant_id == restaurant_id)
    if certified_only:
        # _is_certified 와 같은 기준이어야 한다. 만료된 인증은 화성인증이 아니다.
        now = datetime.now(timezone.utc)
        filters.append(Review.is_receipt_verified.is_(True))
        filters.append(User.is_resident_verified.is_(True))
        filters.append(
            (User.resident_expires_at.is_(None)) | (User.resident_expires_at >= now)
        )

    base = select(Review, User).join(User, Review.user_id == User.id).where(*filters)
    total = db.scalar(
        select(func.count())
        .select_from(Review)
        .join(User, Review.user_id == User.id)
        .where(*filters)
    )

    rows = db.execute(
        base.order_by(Review.created_at.desc()).limit(limit).offset(offset)
    ).all()
    return ReviewListResponse(
        total=total, items=[_to_response(r, u) for r, u in rows]
    )


@router.get("/me", response_model=ReviewListResponse)
def my_reviews(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    total = db.scalar(
        select(func.count()).select_from(Review).where(Review.user_id == user.id)
    )
    rows = db.scalars(
        select(Review)
        .where(Review.user_id == user.id)
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    return ReviewListResponse(
        total=total, items=[_to_response(r, user) for r in rows]
    )


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_review(
    review_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    review = db.get(Review, review_id)
    if review is None or review.user_id != user.id:
        # 남의 리뷰인지 없는 리뷰인지 구분해서 알려주지 않는다.
        raise HTTPException(status.HTTP_404_NOT_FOUND, "식사평을 찾을 수 없습니다")

    # 지우고 다시 써서 포인트를 만드는 걸 막으려고 적립분을 회수한다.
    # 조건을 다시 따지지 않고 작성 시점에 기록해 둔 금액만 되돌린다.
    # 이미 전환해서 잔액이 모자라면 남은 만큼만 걷는다 — 여기서 예외를 올리면
    # 사용자가 자기 식사평을 영구히 못 지운다.
    if review.earned_points:
        revoke_points(db, user.id, review.earned_points, "식사평 삭제")

    db.delete(review)
    db.commit()
