from datetime import datetime
from typing import Annotated

from pydantic import BaseModel, ConfigDict, Field

# 태그 항목이 확정 전이라 값 자체는 검증하지 않는다. 개수와 길이만 막아둔다.
MAX_TAGS = 10
MAX_TAG_LENGTH = 20


class ReviewCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    restaurant_id: int
    tags: list[Annotated[str, Field(max_length=MAX_TAG_LENGTH)]] = Field(
        default_factory=list, max_length=MAX_TAGS
    )
    rating: int | None = Field(None, ge=1, le=5)
    comment: str | None = Field(None, max_length=100)


class ReviewResponse(BaseModel):
    id: int
    restaurant_id: int
    user_id: int
    nickname: str
    tags: list[str] | None
    rating: int | None
    comment: str | None
    is_receipt_verified: bool

    # 주민인증 + 영수증 인증을 모두 통과한 리뷰. 기획서 p.9 의 신뢰 장치.
    is_hwaseong_certified: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ReviewCreateResponse(BaseModel):
    review: ReviewResponse
    earned_points: int = Field(description="이번 작성으로 적립된 포인트")
    total_points: int


class ReviewListResponse(BaseModel):
    total: int
    items: list[ReviewResponse]
