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
    tags: list[str] | None  # 현재 비어 있음. 식사평 기반으로 채울 자리

    # 지도 카드에 "★ 4.6 (122)" 로 쓰인다.
    # 별점을 안 남긴 식사평도 있어서 평균은 별점이 있는 것만, 개수는 전체를 센다.
    avg_rating: float | None = None
    review_count: int = 0

    # 좌표 출처. 프론트가 정확도에 따라 표시를 달리하고 싶을 때 쓴다.
    geocode_status: str

    # lat/lng 을 넘겨 조회한 경우에만 채워진다.
    distance_km: float | None = None

    model_config = {"from_attributes": True}


class RestaurantListResponse(BaseModel):
    total: int = Field(description="필터 조건에 맞는 전체 건수")
    items: list[RestaurantResponse]
