from datetime import datetime

from pydantic import BaseModel, Field

from app.core.constants import POINTS_PER_CONVERT


class PointHistoryResponse(BaseModel):
    id: int
    delta: int = Field(description="적립은 양수, 사용은 음수")
    reason: str
    created_at: datetime

    model_config = {"from_attributes": True}


class PointHistoryListResponse(BaseModel):
    total: int
    balance: int = Field(description="현재 잔액")
    items: list[PointHistoryResponse]


class ExchangeRequest(BaseModel):
    # 1,000P = 화성페이 1,000원. 기획서 p.10 기준으로 1,000P 단위로만 전환한다.
    points: int = Field(
        ge=POINTS_PER_CONVERT,
        multiple_of=POINTS_PER_CONVERT,
        description=f"{POINTS_PER_CONVERT}P 단위",
    )


class ExchangeResponse(BaseModel):
    exchanged_points: int
    exchanged_krw: int
    balance: int = Field(description="전환 후 잔액")
