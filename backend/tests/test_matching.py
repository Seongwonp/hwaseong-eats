"""상호명·주소 정규화와 매칭 로직 테스트.

여기 있는 함수들이 수만 건의 좌표를 좌우한다. 실제로 정규식 하나가 잘못돼
'문어스토리해천 본점' 이 '문어' 로 깎이는 바람에 매칭이 통째로 실패한 적이 있다.
"""

import pytest

from app.core.constants import VISIBLE_GEOCODE_STATUSES, in_hwaseong
from app.services import mobeom, sangga
from app.services.geocode_refine import is_same_place, norm, region_hint
from app.services.geocoding import strip_sido


class TestNorm:
    @pytest.mark.parametrize(
        "raw,expected",
        [
            ("(주) 마이선도니", "마이선도니"),
            ("주식회사마이선도니", "마이선도니"),
            ("㈜강린", "강린"),
            ("유한책임회사 우주가", "우주가"),
            ("본죽&비빔밥cafe 동탄역점", "본죽비빔밥cafe동탄역점"),
        ],
    )
    def test_법인표기와_기호를_걷어낸다(self, raw, expected):
        assert norm(raw) == expected

    def test_상가정보쪽_norm_도_같은_결과(self):
        assert sangga.norm("(주) 마이선도니") == "마이선도니"


class TestIsSamePlace:
    def test_지점명이_붙어도_같은_곳으로_본다(self):
        assert is_same_place("문어스토리해천", "문어스토리해천 본점")
        assert is_same_place("교촌치킨 동탄역점", "교촌치킨동탄역점")

    def test_법인표기_차이는_무시한다(self):
        assert is_same_place("(주) 마이선도니", "주식회사마이선도니")

    def test_다른_가게는_거른다(self):
        assert not is_same_place("카페플랜츠", "아이디플랜츠")
        assert not is_same_place("또곱창", "황태집")

    def test_너무_짧은_이름은_매칭하지_않는다(self):
        # 한 글자짜리가 아무 데나 붙는 걸 막는다
        assert not is_same_place("A", "A커피")


class TestRoadKey:
    def test_도로명_토큰만_남긴다(self):
        assert sangga.road_of("경기 화성시 동탄구 동탄대로5길") == "동탄대로5길"
        assert sangga.road_of("경기도 화성시 동탄구 중리길 183") == "중리길"

    def test_모범음식점쪽도_동일하게_동작(self):
        assert mobeom.road_key("경기도 화성시 효행구 매송면 화성로 2419-10") == "화성로"

    def test_빈_주소는_빈_문자열(self):
        assert sangga.road_of("") == ""
        assert mobeom.road_key(None) == ""


class TestSameRoad:
    def test_완전일치만_인정한다(self):
        assert mobeom.same_road("화산중앙로", "화산중앙로")

    def test_부분일치는_거른다(self):
        # '중앙로' 가 '화산중앙로' 에 걸리면 다른 가게가 같은 가게가 된다
        assert not mobeom.same_road("중앙로", "화산중앙로")

    def test_빈값은_매칭하지_않는다(self):
        assert not mobeom.same_road("", "")


class TestStripSido:
    def test_시도명만_떼어낸다(self):
        assert strip_sido("경기 화성시 동탄구 동탄대로") == "화성시 동탄구 동탄대로"
        assert strip_sido("경기도 화성시 병점구 용주로") == "화성시 병점구 용주로"

    def test_시도명이_없으면_그대로_둔다(self):
        # 무조건 첫 토큰을 버리면 의미 있는 토큰이 날아간다
        assert strip_sido("화성시 동탄구 동탄대로") == "화성시 동탄구 동탄대로"


class TestRegionHint:
    def test_구읍면_토큰을_뽑는다(self):
        assert region_hint("경기 화성시 동탄구 동탄대로") == "동탄구"
        assert region_hint("경기 화성시 만세구 향남읍 발안공단로5길") == "만세구"

    def test_못_찾으면_화성시로_떨어진다(self):
        assert region_hint("경기 화성시") == "화성시"


class TestInHwaseong:
    def test_화성시_안_좌표(self):
        assert in_hwaseong(37.197428, 127.098431)  # 동탄역

    def test_화성시_밖_좌표는_거른다(self):
        assert not in_hwaseong(37.5665, 126.9780)  # 서울시청
        assert not in_hwaseong(35.1796, 129.0756)  # 부산


class TestVisibleStatuses:
    def test_unverified_는_노출하지_않는다(self):
        assert "unverified" not in VISIBLE_GEOCODE_STATUSES

    def test_좌표없는_상태도_노출하지_않는다(self):
        assert "pending" not in VISIBLE_GEOCODE_STATUSES
        assert "failed" not in VISIBLE_GEOCODE_STATUSES


class TestKonapayCoords:
    """코나페이 원본에 0,0 이나 타지역 좌표가 섞여 들어온다."""

    def _row(self, lat, lng):
        from app.services.konapay import to_row

        return to_row(
            {"addr": "경기 화성시 동탄구 동탄대로", "simpleNm": "테스트", "seq": 1,
             "latitude": lat, "longitude": lng}
        )

    def test_0_0_좌표는_버린다(self):
        row = self._row(0, 0)
        assert row["lat"] is None and row["geocode_status"] == "pending"

    def test_화성시_밖_좌표도_버린다(self):
        row = self._row(37.5665, 126.9780)  # 서울시청
        assert row["lat"] is None

    def test_정상_좌표는_유지한다(self):
        row = self._row(37.197428, 127.098431)
        assert row["lat"] == 37.197428 and row["geocode_status"] == "konapay"


class TestMobeomRoadKey:
    """모범음식점 주소는 건물번호 뒤에 층·건물명이 더 붙는다."""

    def test_건물번호_뒤_군더더기를_무시한다(self):
        addr = "경기도 화성시 동탄구 큰재봉길 23-12, 1층 (동탄구 석우동, 펠리스타)"
        assert mobeom.road_key(addr) == "큰재봉길"

    def test_지하층_표기도_처리한다(self):
        addr = "경기도 화성시 효행구 봉담읍 삼천병마로 1079-12, 지하 1층 일부"
        assert mobeom.road_key(addr) == "삼천병마로"

    def test_건물번호가_없으면_마지막_토큰(self):
        assert mobeom.road_key("경기 화성시 동탄구 동탄대로") == "동탄대로"

    def test_모범음식점과_코나페이_주소가_같은_도로로_매칭된다(self):
        a = mobeom.road_key("경기도 화성시 동탄구 중리길 183")
        b = mobeom.road_key("경기 화성시 동탄구 중리길")
        assert mobeom.same_road(a, b)
