"""도메인 상수.

수집·지오코딩·API가 같은 기준을 봐야 해서 한 곳에 모은다.
"""

from datetime import date, datetime
from zoneinfo import ZoneInfo

# 서비스 기준 시간대. Render 컨테이너는 UTC 라 date.today() 를 그냥 쓰면
# 한국 자정~오전 9시 사이에 하루가 밀린다. 절기 D-day 가 어긋나는 원인이었다.
KST = ZoneInfo("Asia/Seoul")


def today_kst(now: datetime | None = None) -> date:
    """한국 기준 오늘. 절기·축제 판정은 전부 이 값을 쓴다.

    now 는 테스트에서 시각을 고정하려고 받는다. tz 정보가 있으면 KST 로 변환한다.
    """
    moment = now or datetime.now(KST)
    if moment.tzinfo is not None:
        moment = moment.astimezone(KST)
    return moment.date()


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

# 지도 UI의 사용자 친화적 분류를 코나페이 원본 업종명에 대응시킨다.
# 원본의 "슈퍼마켓.마트"를 화면에서는 "대형마트"로 간단히 표시한다.
MAP_CATEGORY_GROUPS = {
    "restaurant": tuple(
        category for category in FOOD_CATEGORIES if category != "커피전문점"
    ),
    "cafe": ("커피전문점",),
    "convenience": ("편의점",),
    "mart": ("슈퍼마켓.마트",),
}

# 인허가 데이터의 업태구분명을 위 FOOD_CATEGORIES 로 옮긴다.
# 전부 "일반음식점" 으로 넣으면 category=치킨전문점 필터와 업종 검색에서 신규 데이터가
# 통째로 빠진다. 원본 업태는 biz_type_code 에 그대로 남겨두고 category 만 맞춘다.
# 여기 없는 업태(한식·중국식·분식 등)는 일반음식점으로 둔다 — 지도 분류가 같다.
BIZ_TYPE_TO_CATEGORY = {
    "통닭(치킨)": "치킨전문점",
    "호프/통닭": "일반주점",       # 주업태가 주점이다. 치킨 단독은 위 항목
    "정종/대포집/소주방": "일반주점",
    "감성주점": "일반주점",
    "라이브카페": "일반주점",       # 이름만 카페고 주류 판매업이다
    "키즈카페": "커피전문점",
    "커피숍": "커피전문점",
    "다방": "커피전문점",
    "카페": "커피전문점",
    "제과점": "제과.제빵",
    "제과점영업": "제과.제빵",
}

DEFAULT_FOOD_CATEGORY = "일반음식점"


def category_for_biz_type(biz_type: str | None) -> str:
    """업태구분명 → 지도 업종. 모르는 업태는 일반음식점으로 떨어진다."""
    return BIZ_TYPE_TO_CATEGORY.get((biz_type or "").strip(), DEFAULT_FOOD_CATEGORY)

# geocode_status 값 — 좌표를 어디서 얻었고 얼마나 믿을 수 있는지를 함께 담는다.
#   sangga     상가(상권)정보 좌표. 국세청·카드사 기반이라 가장 믿을 만하다
#   localdata  지방행정 인허가 데이터(일반음식점표준데이터) 원본 좌표. 인허가 등록 시
#              사업자가 신고한 좌표라 sangga 급으로 믿을 만하다
#   verified   카카오 장소 검색에서 상호명까지 일치 확인
#   ok         카카오 좌표. 상호명 대조는 안 거침
#   konapay    코나페이 원본 좌표. 소수점 5~6자리로 정밀도가 낮아 따로 구분한다
#   unverified 좌표가 도로 중심점 수준. 다른 업소와 같은 지점에 찍혀 있다
#   pending    아직 좌표를 안 채움
#   failed     좌표를 못 찾음
#   duplicate  다른 출처로 이미 들어온 같은 업소. 좌표는 정상이지만 지도에 두 번
#              찍히므로 조회에서만 뺀다. 화성페이 여부·원본 키를 가진 쪽을 남긴다
GEOCODE_SANGGA = "sangga"
GEOCODE_LOCALDATA = "localdata"
GEOCODE_VERIFIED = "verified"
GEOCODE_OK = "ok"
GEOCODE_KONAPAY = "konapay"
GEOCODE_UNVERIFIED = "unverified"
GEOCODE_PENDING = "pending"
GEOCODE_FAILED = "failed"
GEOCODE_DUPLICATE = "duplicate"

# API 응답에 내보낼 상태. unverified 는 좌표를 믿을 수 없어 지도에서 제외한다.
# 데이터는 지우지 않고 남겨두되, 조회에서만 빠진다.
#
# konapay 는 정밀도가 낮지만 도로 중심점으로 뭉갠 값이 아니라 운영사가 준 실제 좌표라
# 노출은 하되 출처를 구분해 둔다. 프론트가 필요하면 이 값으로 표시를 달리하면 된다.
VISIBLE_GEOCODE_STATUSES = (
    GEOCODE_SANGGA,
    GEOCODE_LOCALDATA,
    GEOCODE_VERIFIED,
    GEOCODE_OK,
    GEOCODE_KONAPAY,
)

# 좌표를 새로 채울 대상. 이미 자리 잡은 행은 건드리지 않는다.
# 상가정보는 업소 단위 실좌표라 unverified 를 덮어써도 나빠지지 않는다.
REFILL_GEOCODE_STATUSES = (GEOCODE_UNVERIFIED, GEOCODE_PENDING, GEOCODE_FAILED)

# 카카오 지오코딩으로 좌표를 채울 대상.
# unverified 는 여기서 뺀다 — geocoding 은 주소 검색 폴백을 쓰는데, 그게 만든
# 도로 중심점 좌표를 geocode_refine 이 unverified 로 내린 것이라 다시 넣으면 원상복구다.
# failed 는 넣는다. 다음 실행에서 찾아질 수 있다.
GEOCODE_TARGET_STATUSES = (GEOCODE_PENDING, GEOCODE_FAILED)

# 좌표 재검증(geocode_refine) 대상.
# 출처가 확실한 좌표(sangga·localdata)와 이미 확인된 verified 는 건드리지 않는다.
# duplicate 를 넣으면 숨겨둔 중복이 verified 로 덮여 지도에 다시 뜬다.
REFINE_GEOCODE_STATUSES = (GEOCODE_OK, GEOCODE_KONAPAY, GEOCODE_UNVERIFIED)

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
