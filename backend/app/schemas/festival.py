from datetime import date

from pydantic import BaseModel, Field


class SeasonalEventResponse(BaseModel):
    id: int
    name: str
    event_type: str = Field(description="절기 | 명절 | 축제")
    start_date: date
    end_date: date
    food_keyword: str | None

    # 축제만 값이 있다.
    location: str | None
    lat: float | None
    lng: float | None
    radius_km: float | None

    d_day: int = Field(description="시작일까지 남은 일수. 기간 중이면 0, 지났으면 음수")
    is_active: bool = Field(description="지금 지도에 띄울 때인지 (기념일 ±3일 / 축제 기간)")

    model_config = {"from_attributes": True}


class SeasonalEventListResponse(BaseModel):
    total: int
    items: list[SeasonalEventResponse]


class TodayResponse(BaseModel):
    date: date
    primary: SeasonalEventResponse | None = Field(description="배너에 띄울 하나")
    items: list[SeasonalEventResponse]
