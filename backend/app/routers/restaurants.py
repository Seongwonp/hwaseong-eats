import math
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import Float, func, literal, select
from sqlalchemy.orm import Session

from app.core.constants import (
    FOOD_CATEGORIES,
    MAP_CATEGORY_GROUPS,
    VISIBLE_GEOCODE_STATUSES,
)
from app.database import get_db
from app.models import Restaurant, Review
from app.schemas.restaurant import RestaurantListResponse, RestaurantResponse

router = APIRouter()

EARTH_RADIUS_KM = 6371.0
KM_PER_LAT_DEG = 111.0


def _visible():
    """지도에 띄울 수 있는 행만 남긴다.

    unverified 는 좌표가 도로 중심점 수준이라 데이터는 남겨두되 조회에서 뺀다.
    목록과 단건 조회가 같은 기준을 써야 목록에 없는 걸 상세로는 볼 수 있는 일이 안 생긴다.
    """
    return (
        Restaurant.lat.is_not(None),
        Restaurant.lng.is_not(None),
        Restaurant.geocode_status.in_(VISIBLE_GEOCODE_STATUSES),
    )


def _escape_like(value: str) -> str:
    """LIKE 특수문자를 문자 그대로 찾도록 막는다.

    이스케이프하지 않으면 q=% 하나로 전체가 반환된다.
    """
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _rating_columns():
    """음식점별 평균 별점과 식사평 수.

    조회된 행에 대해서만 인덱스로 찾으므로(reviews.restaurant_id) 목록 전체를
    미리 집계하지 않는다. 별점을 안 남긴 식사평이 있어 평균과 개수의 모집단이 다르다.
    """
    avg = (
        select(func.round(func.avg(Review.rating), 1).cast(Float))
        .where(Review.restaurant_id == Restaurant.id)
        .scalar_subquery()
    )
    count = (
        select(func.count())
        .select_from(Review)
        .where(Review.restaurant_id == Restaurant.id)
        .scalar_subquery()
    )
    return avg.label("avg_rating"), count.label("review_count")


def _build(row_restaurant, avg_rating, review_count, distance=None) -> RestaurantResponse:
    return RestaurantResponse.model_validate(row_restaurant).model_copy(
        update={
            "avg_rating": float(avg_rating) if avg_rating is not None else None,
            "review_count": review_count or 0,
            "distance_km": round(distance, 3) if distance is not None else None,
        }
    )


def _distance_km(lat: float, lng: float):
    """하버사인. PostGIS 없이 쓰려고 SQL 식으로 직접 짠다.

    SQLAlchemy 함수 객체는 ** 를 못 받으므로 제곱은 곱셈으로 쓴다.
    """
    lat1, lng1 = func.radians(literal(lat)), func.radians(literal(lng))
    lat2, lng2 = func.radians(Restaurant.lat), func.radians(Restaurant.lng)

    sin_dlat = func.sin((lat2 - lat1) / 2)
    sin_dlng = func.sin((lng2 - lng1) / 2)
    a = sin_dlat * sin_dlat + func.cos(lat1) * func.cos(lat2) * sin_dlng * sin_dlng

    return (2 * EARTH_RADIUS_KM * func.asin(func.sqrt(a))).cast(Float)


@router.get("", response_model=RestaurantListResponse)
def list_restaurants(
    is_konapay: bool | None = Query(None, description="화성페이 가맹점만"),
    is_mobeom: bool | None = Query(None, description="모범음식점만"),
    category: str | None = Query(None, description="업종명 (예: 일반음식점)"),
    category_group: Literal["restaurant", "cafe", "convenience", "mart"] | None = Query(
        None, description="지도 분류: restaurant, cafe, convenience, mart"
    ),
    q: str | None = Query(None, description="상호명 검색"),
    food_only: bool = Query(True, description="음식 업종만"),
    lat: float | None = Query(None, ge=-90, le=90, description="현재 위치 위도"),
    lng: float | None = Query(None, ge=-180, le=180, description="현재 위치 경도"),
    radius_km: float | None = Query(None, gt=0, le=50, description="반경(km)"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """조건별 음식점 조회. lat/lng 을 주면 거리를 계산해 가까운 순으로 준다."""
    if (lat is None) != (lng is None):
        raise HTTPException(400, "lat 과 lng 은 함께 넘겨야 합니다")
    if radius_km is not None and lat is None:
        raise HTTPException(400, "radius_km 을 쓰려면 lat/lng 이 필요합니다")

    filters = list(_visible())
    if category is not None and category_group is not None:
        raise HTTPException(400, "category 와 category_group 은 함께 쓸 수 없습니다")

    if category_group is not None:
        filters.append(Restaurant.category.in_(MAP_CATEGORY_GROUPS[category_group]))
    elif food_only:
        filters.append(Restaurant.category.in_(FOOD_CATEGORIES))
    if is_konapay is not None:
        filters.append(Restaurant.is_konapay.is_(is_konapay))
    if is_mobeom is not None:
        filters.append(Restaurant.is_mobeom.is_(is_mobeom))
    if category:
        filters.append(Restaurant.category == category)
    if q:
        filters.append(Restaurant.name.ilike(f"%{_escape_like(q)}%", escape="\\"))

    if lat is not None and radius_km is not None:
        # 위경도 인덱스를 타도록 사각형으로 먼저 자른 뒤, 남은 것만 실제 거리로 거른다.
        lat_pad = radius_km / KM_PER_LAT_DEG
        lng_pad = lat_pad / max(0.01, abs(math.cos(math.radians(lat))))
        filters += [
            Restaurant.lat.between(lat - lat_pad, lat + lat_pad),
            Restaurant.lng.between(lng - lng_pad, lng + lng_pad),
            _distance_km(lat, lng) <= radius_km,
        ]

    total = db.scalar(select(func.count()).select_from(Restaurant).where(*filters))

    avg_rating, review_count = _rating_columns()

    if lat is not None:
        distance = _distance_km(lat, lng)
        stmt = (
            select(Restaurant, avg_rating, review_count, distance.label("distance_km"))
            .where(*filters)
            .order_by("distance_km")
        )
        rows = db.execute(stmt.limit(limit).offset(offset)).all()
        items = [_build(r, a, c, d) for r, a, c, d in rows]
    else:
        stmt = (
            select(Restaurant, avg_rating, review_count)
            .where(*filters)
            .order_by(Restaurant.id)
        )
        rows = db.execute(stmt.limit(limit).offset(offset)).all()
        items = [_build(r, a, c) for r, a, c in rows]

    return RestaurantListResponse(total=total, items=items)


@router.get("/{restaurant_id}", response_model=RestaurantResponse)
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    """목록과 같은 노출 기준을 적용한다.

    좌표가 없거나 unverified 인 행을 그냥 돌려주면 응답 스키마의 lat/lng 검증에
    걸려 500 이 난다. 목록에 안 나오는 건 상세로도 안 보이는 게 맞다.
    """
    avg_rating, review_count = _rating_columns()
    row = db.execute(
        select(Restaurant, avg_rating, review_count).where(
            Restaurant.id == restaurant_id, *_visible()
        )
    ).first()
    if row is None:
        raise HTTPException(404, "음식점을 찾을 수 없습니다")
    return _build(*row)
