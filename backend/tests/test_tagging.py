"""태그 규칙 테스트.

규칙이 추정이라 언제든 바뀔 수 있다. 바뀔 때 의도치 않게 다른 태그까지
휩쓸리지 않도록 경계만 고정해 둔다.
"""

import pytest

from app.services.tagging import TAG_SOLO, TAG_STUDY, TAG_TEEN, TAG_VALUE, tags_for


class TestStudy:
    def test_스터디카페(self):
        assert TAG_STUDY in tags_for("작심스터디카페 동탄점", "커피전문점", False)

    def test_대형_프랜차이즈_카페(self):
        assert TAG_STUDY in tags_for("스타벅스 동탄역점", "커피전문점", False)

    def test_개인_카페는_붙이지_않는다(self):
        # 매장마다 좌석 편차가 커서 상호명만으로는 판단할 수 없다
        assert TAG_STUDY not in tags_for("카페 라스유", "커피전문점", False)


class TestTeen:
    def test_분식_떡볶이(self):
        assert TAG_TEEN in tags_for("신전떡볶이 병점점", "일반음식점", False)
        assert TAG_TEEN in tags_for("일월분식", "일반음식점", False)

    def test_치킨전문점(self):
        assert TAG_TEEN in tags_for("교촌치킨 동탄역점", "치킨전문점", False)


class TestSolo:
    def test_한그릇_음식(self):
        for name in ("본가네국밥", "김밥천국", "이치류 라멘", "더돈까스"):
            assert TAG_SOLO in tags_for(name, "일반음식점", False), name

    def test_고깃집은_붙이지_않는다(self):
        assert TAG_SOLO not in tags_for("세광양대창 동탄역점", "일반음식점", False)


class TestValue:
    def test_뷔페_백반(self):
        assert TAG_VALUE in tags_for("사계절한식뷔페", "일반음식점", False)
        assert TAG_VALUE in tags_for("시골백반", "일반음식점", False)

    def test_모범음식점은_가성비로_본다(self):
        assert TAG_VALUE in tags_for("아무이름", "일반음식점", True)


class TestNoMatch:
    def test_해당_없으면_빈_목록(self):
        assert tags_for("제부도 조개구이", "일반음식점", False) == []

    @pytest.mark.parametrize("name", ["", None])
    def test_이름이_비어도_터지지_않는다(self, name):
        assert tags_for(name, "일반음식점", False) == []


class TestMultiple:
    def test_여러_태그가_동시에_붙을_수_있다(self):
        tags = tags_for("싸다김밥 뷔페", "일반음식점", False)
        assert TAG_SOLO in tags and TAG_VALUE in tags
