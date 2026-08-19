"""검수에서 나온 문제들을 다시 못 나게 고정한다.

DB 없이 도는 것만 여기 둔다. 실제 DB 가 필요한 회수 로직은 test_security_points.py 에 있다.
"""

from datetime import date, datetime, timedelta, timezone

import pytest

from app.core.constants import (
    GEOCODE_TARGET_STATUSES,
    REFINE_GEOCODE_STATUSES,
    VISIBLE_GEOCODE_STATUSES,
    category_for_biz_type,
    today_kst,
)
from app.models import User
from app.schemas.auth import UserResponse
from app.services.matching import normalize_name, road_key, same_place, same_road


class TestTodayKst:
    """Render 는 UTC 라 date.today() 를 쓰면 한국 자정~오전 9시에 하루가 밀렸다."""

    def test_한국_자정_직전_UTC_는_다음날로_본다(self):
        # 2026-08-18 23:30 UTC = 2026-08-19 08:30 KST
        utc_moment = datetime(2026, 8, 18, 23, 30, tzinfo=timezone.utc)
        assert today_kst(utc_moment) == date(2026, 8, 19)
        assert utc_moment.date() == date(2026, 8, 18)  # 예전 동작

    def test_한국_오전에도_같은_날을_준다(self):
        assert today_kst(datetime(2026, 8, 19, 0, 10, tzinfo=timezone.utc)) == date(2026, 8, 19)


class TestBizTypeCategory:
    """업태를 버리면 category=치킨전문점 필터에서 신규 데이터가 통째로 빠진다."""

    @pytest.mark.parametrize(
        "biz_type,expected",
        [
            ("통닭(치킨)", "치킨전문점"),
            ("호프/통닭", "일반주점"),
            ("정종/대포집/소주방", "일반주점"),
            ("라이브카페", "일반주점"),   # 이름만 카페고 주류 판매업
            ("키즈카페", "커피전문점"),
            ("한식", "일반음식점"),       # 모르는 업태는 기본값
            ("", "일반음식점"),
            (None, "일반음식점"),
        ],
    )
    def test_업태를_지도_업종으로_옮긴다(self, biz_type, expected):
        assert category_for_biz_type(biz_type) == expected


class TestGeocodeStatusSets:
    def test_중복은_노출하지_않는다(self):
        assert "duplicate" not in VISIBLE_GEOCODE_STATUSES

    def test_재검증이_확실한_좌표를_건드리지_않는다(self):
        # sangga·localdata 를 넣으면 카카오가 상호를 못 찾을 때 unverified 로 강등된다.
        # duplicate 를 넣으면 숨겨둔 중복이 verified 로 덮여 지도에 다시 뜬다.
        for status in ("sangga", "localdata", "verified", "duplicate", "pending"):
            assert status not in REFINE_GEOCODE_STATUSES

    def test_실패한_행도_다시_지오코딩한다(self):
        assert "failed" in GEOCODE_TARGET_STATUSES
        assert "pending" in GEOCODE_TARGET_STATUSES
        # 주소 검색 폴백이 만든 도로 중심점 좌표를 되돌리면 안 된다
        assert "unverified" not in GEOCODE_TARGET_STATUSES


class TestSharedMatching:
    def test_네_소스가_같은_정규화를_쓴다(self):
        from app.services import mobeom, sangga
        from app.services.geocode_refine import norm

        raw = "유한책임회사 우주가"
        assert normalize_name(raw) == sangga.norm(raw) == norm(raw) == "우주가"
        assert mobeom.normalize_name(raw) == "우주가"

    def test_상가정보도_도로명_부분일치를_거른다(self):
        # 예전 sangga.lookup 은 '중앙로' 를 '화산중앙로' 에 붙여 다른 가게 좌표를 가져왔다
        idx = {normalize_name("김밥천국"): [("화산중앙로", 37.2, 127.0)]}
        from app.services.sangga import lookup

        assert lookup(idx, "김밥천국", "경기 화성시 병점구 중앙로") is None
        assert lookup(idx, "김밥천국", "경기 화성시 병점구 화산중앙로") == (37.2, 127.0)

    def test_같은_가게_판정(self):
        assert same_place(
            "명가한식뷔페", "경기도 화성시 만세구 화성로 671-4",
            "명가한식뷔페", "경기 화성시 만세구 화성로",
        )
        assert not same_place(
            "명가한식뷔페", "경기도 화성시 만세구 화성로 671-4",
            "명가한식뷔페", "경기 화성시 만세구 서해로",
        )

    def test_도로명_추출은_건물번호_직전_토큰(self):
        assert road_key("경기도 화성시 동탄구 큰재봉길 23-12, 1층 (석우동, 펠리스타)") == "큰재봉길"
        assert same_road("큰재봉길", "큰재봉길")


class TestNearDuplicateGuard:
    """주소 표기가 갈려 대조가 실패해도 좌표로 한 번 더 막는다(중복 105건의 원인)."""

    @pytest.fixture(scope="class")
    def gr(self):
        # 수집 스크립트는 배포 브랜치에 없을 수 있고 pyproj 도 필요하다.
        return pytest.importorskip("app.services.general_restaurants")

    def test_50m_안_같은_상호는_같은_가게로_본다(self, gr):
        assert gr._is_near(37.20270, 126.82849, (37.20272, 126.82851))

    def test_멀면_다른_가게다(self, gr):
        assert not gr._is_near(37.20270, 126.82849, (37.21000, 126.83500))

    def test_좌표가_없는_기존_행은_비교하지_않는다(self, gr):
        assert not gr._is_near(37.20270, 126.82849, (None, None))


class TestResidentExpiry:
    """만료된 주민인증이 계속 인증됨으로 보이던 문제."""

    def _user(self, expires_at):
        return User(
            id=1, nickname="테스트", email=None, points=0,
            is_resident_verified=True, resident_expires_at=expires_at,
        )

    def test_만료되면_인증이_풀린다(self):
        past = datetime.now(timezone.utc) - timedelta(days=1)
        assert self._user(past).is_resident_active is False

    def test_유효기간_안이면_인증이다(self):
        future = datetime.now(timezone.utc) + timedelta(days=30)
        assert self._user(future).is_resident_active is True

    def test_응답에도_만료가_반영된다(self):
        past = datetime.now(timezone.utc) - timedelta(days=1)
        body = UserResponse.model_validate(self._user(past))
        assert body.is_resident_verified is False

    def test_인증한_적_없으면_False(self):
        user = User(id=1, nickname="테스트", email=None, points=0,
                    is_resident_verified=False, resident_expires_at=None)
        assert user.is_resident_active is False
