"""도메인 상수.

수집·지오코딩·API가 같은 기준을 봐야 해서 한 곳에 모은다.
"""

# 지도에 띄울 음식 업종. 코나페이 bizTypeNm 값과 모범음식점 표기를 그대로 쓴다.
FOOD_CATEGORIES = (
    "일반음식점",
    "커피전문점",
    "치킨전문점",
    "제과.제빵",
    "일반주점",
    "기타음식점",
    "모범음식점",
)

# geocode_status 값 — 좌표를 어디서 얻었고 얼마나 믿을 수 있는지를 함께 담는다.
#   sangga     상가(상권)정보 좌표. 국세청·카드사 기반이라 가장 믿을 만하다
#   verified   카카오 장소 검색에서 상호명까지 일치 확인
#   ok         카카오 좌표. 상호명 대조는 안 거침
#   konapay    코나페이 원본 좌표. 소수점 5~6자리로 정밀도가 낮아 따로 구분한다
#   unverified 좌표가 도로 중심점 수준. 다른 업소와 같은 지점에 찍혀 있다
#   pending    아직 좌표를 안 채움
#   failed     좌표를 못 찾음
GEOCODE_SANGGA = "sangga"
GEOCODE_VERIFIED = "verified"
GEOCODE_OK = "ok"
GEOCODE_KONAPAY = "konapay"
GEOCODE_UNVERIFIED = "unverified"
GEOCODE_PENDING = "pending"
GEOCODE_FAILED = "failed"

# API 응답에 내보낼 상태. unverified 는 좌표를 믿을 수 없어 지도에서 제외한다.
# 데이터는 지우지 않고 남겨두되, 조회에서만 빠진다.
#
# konapay 는 정밀도가 낮지만 도로 중심점으로 뭉갠 값이 아니라 운영사가 준 실제 좌표라
# 노출은 하되 출처를 구분해 둔다. 프론트가 필요하면 이 값으로 표시를 달리하면 된다.
VISIBLE_GEOCODE_STATUSES = (
    GEOCODE_SANGGA,
    GEOCODE_VERIFIED,
    GEOCODE_OK,
    GEOCODE_KONAPAY,
)

# 좌표를 새로 채울 대상. 이미 자리 잡은 행은 건드리지 않는다.
REFILL_GEOCODE_STATUSES = (GEOCODE_UNVERIFIED, GEOCODE_PENDING, GEOCODE_FAILED)

# 화성시 대략 범위. 동명이인 가게가 엉뚱한 지역에서 잡히는 걸 거른다.
HWASEONG_LAT_RANGE = (36.95, 37.35)
HWASEONG_LNG_RANGE = (126.55, 127.20)


def in_hwaseong(lat: float, lng: float) -> bool:
    return (
        HWASEONG_LAT_RANGE[0] <= lat <= HWASEONG_LAT_RANGE[1]
        and HWASEONG_LNG_RANGE[0] <= lng <= HWASEONG_LNG_RANGE[1]
    )


# 리워드 (기획서 p.10)
REVIEW_POINTS = 500          # 화성인증 식사평 1건당
POINTS_PER_CONVERT = 1000    # 화성페이 전환 최소 단위
