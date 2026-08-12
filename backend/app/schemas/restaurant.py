from pydantic import BaseModel, Field


class RestaurantResponse(BaseModel):
    id: int
    name: str
    address: str
    phone: str | None
    lat: float
    lng: float
    category: str | None
    is_konapay: bool
    is_mobeom: bool
    tags: list[str] | None

    # 좌표 출처. 프론트가 정확도에 따라 표시를 달리하고 싶을 때 쓴다.
    geocode_status: str

    # lat/lng 을 넘겨 조회한 경우에만 채워진다.
    distance_km: float | None = None

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    total: int = Field(description="필터 조건에 맞는 전체 건수")
    items: list[RestaurantResponse]
