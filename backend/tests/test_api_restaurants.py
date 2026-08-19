"""GET /restaurants 엔드포인트 테스트.

실제 DB 를 붙여 돈다. DB 가 안 떠 있으면 통째로 건너뛴다.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import VISIBLE_GEOCODE_STATUSES
from app.database import SessionLocal
from app.main import app
from app.models import Restaurant, Review, User

DONGTAN_STATION = {"lat": 37.2014, "lng": 127.0985}


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as e:
        pytest.skip(f"DB 연결 불가: {e}")
    return TestClient(app)


@pytest.fixture(scope="module")
def search_seed(client):
    restaurant_id = 8_888_000_001
    user_id = 8_888_000_002
    review_id = 8_888_000_003
    with SessionLocal() as db:
        db.execute(text("DELETE FROM reviews WHERE id=:id"), {"id": review_id})
        db.execute(text("DELETE FROM users WHERE id=:id"), {"id": user_id})
        db.execute(text("DELETE FROM restaurants WHERE id=:id"), {"id": restaurant_id})
        db.add(Restaurant(
            id=restaurant_id,
            name="통합검색테스트식당",
            address="경기도 화성시 테스트로 1",
            lat=37.2,
            lng=127.0,
            geocode_status="verified",
            category="일반음식점",
            tags=["음식점태그검색"],
            is_konapay=True,
        ))
        db.add(User(
            id=user_id,
            email="restaurant-search@example.com",
            password_hash="not-used",
            nickname="검색fixture",
        ))
        db.flush()
        db.add(Review(
            id=review_id,
            restaurant_id=restaurant_id,
            user_id=user_id,
            tags=["리뷰태그검색"],
            rating=5,
            earned_points=0,
        ))
        db.commit()
    yield restaurant_id
    with SessionLocal() as db:
        db.execute(text("DELETE FROM reviews WHERE id=:id"), {"id": review_id})
        db.execute(text("DELETE FROM users WHERE id=:id"), {"id": user_id})
        db.execute(text("DELETE FROM restaurants WHERE id=:id"), {"id": restaurant_id})
        db.commit()


class TestList:
    def test_기본_조회(self, client):
        body = client.get("/restaurants", params={"limit": 5}).json()
        assert body["total"] > 0
        assert len(body["items"]) == 5

    def test_노출_대상만_나온다(self, client):
        body = client.get("/restaurants", params={"limit": 200}).json()
        for item in body["items"]:
            assert item["geocode_status"] in VISIBLE_GEOCODE_STATUSES
            assert item["lat"] is not None and item["lng"] is not None

    def test_화성페이_필터(self, client):
        body = client.get("/restaurants", params={"is_konapay": True, "limit": 50}).json()
        assert all(x["is_konapay"] for x in body["items"])

    def test_교집합_필터가_더_좁다(self, client):
        both = client.get(
            "/restaurants", params={"is_konapay": True, "is_mobeom": True, "limit": 1}
        ).json()["total"]
        only_pay = client.get(
            "/restaurants", params={"is_konapay": True, "limit": 1}
        ).json()["total"]
        assert 0 < both < only_pay

    def test_업종_필터(self, client):
        body = client.get(
            "/restaurants", params={"category": "커피전문점", "limit": 20}
        ).json()
        assert all(x["category"] == "커피전문점" for x in body["items"])

    @pytest.mark.parametrize(
        ("group", "categories"),
        [
            ("restaurant", {"일반음식점", "치킨전문점", "제과.제빵", "일반주점", "기타음식점", "모범음식점"}),
            ("cafe", {"커피전문점"}),
            ("convenience", {"편의점"}),
            ("mart", {"슈퍼마켓.마트"}),
        ],
    )
    def test_지도_분류는_서버에서_필터링된다(self, client, group, categories):
        body = client.get(
            "/restaurants", params={"category_group": group, "limit": 50}
        ).json()
        assert body["total"] > 0
        assert body["items"]
        assert all(item["category"] in categories for item in body["items"])

    def test_업종과_지도분류는_동시에_쓸_수_없다(self, client):
        response = client.get(
            "/restaurants",
            params={"category": "커피전문점", "category_group": "cafe"},
        )
        assert response.status_code == 400

    def test_알_수_없는_지도분류는_422(self, client):
        response = client.get(
            "/restaurants", params={"category_group": "unknown"}
        )
        assert response.status_code == 422


class TestSearch:
    def test_상호명_검색(self, client):
        body = client.get("/restaurants", params={"q": "본죽", "limit": 10}).json()
        assert body["total"] > 0
        assert all("본죽" in x["name"] for x in body["items"])

    def test_와일드카드는_문자로_취급한다(self, client):
        """이스케이프하지 않으면 q=% 하나로 전체가 반환된다."""
        all_count = client.get("/restaurants", params={"limit": 1}).json()["total"]
        pct = client.get("/restaurants", params={"q": "%", "limit": 1}).json()["total"]
        assert pct < all_count

    def test_없는_이름은_0건(self, client):
        body = client.get("/restaurants", params={"q": "존재하지않는가게이름zzz"}).json()
        assert body["total"] == 0

    def test_업종명으로_검색한다(self, client):
        body = client.get(
            "/restaurants", params={"q": "커피전문점", "limit": 100}
        ).json()
        assert body["total"] > 0
        assert any(item["category"] == "커피전문점" for item in body["items"])

    @pytest.mark.parametrize("query", ["음식점태그검색", "리뷰태그검색"])
    def test_음식점과_리뷰_태그로_검색한다(
        self, client, search_seed, query
    ):
        body = client.get("/restaurants", params={"q": query}).json()
        assert search_seed in [item["id"] for item in body["items"]]

    def test_화성페이_키워드는_가맹점을_검색한다(self, client):
        body = client.get(
            "/restaurants", params={"q": "화성페이", "limit": 50}
        ).json()
        assert body["total"] > 0
        assert all(item["is_konapay"] for item in body["items"])

    def test_공백과_너무_긴_검색어를_거절한다(self, client):
        assert client.get("/restaurants", params={"q": "   "}).status_code == 400
        assert client.get("/restaurants", params={"q": "가" * 101}).status_code == 422


class TestDistance:
    def test_가까운_순으로_정렬된다(self, client):
        body = client.get(
            "/restaurants", params={**DONGTAN_STATION, "radius_km": 1, "limit": 20}
        ).json()
        distances = [x["distance_km"] for x in body["items"]]
        assert distances == sorted(distances)

    def test_반경을_넓히면_건수가_늘어난다(self, client):
        counts = [
            client.get(
                "/restaurants", params={**DONGTAN_STATION, "radius_km": r, "limit": 1}
            ).json()["total"]
            for r in (0.5, 1, 3)
        ]
        assert counts == sorted(counts)
        assert counts[0] < counts[-1]

    def test_반경_밖은_안_나온다(self, client):
        body = client.get(
            "/restaurants", params={**DONGTAN_STATION, "radius_km": 1, "limit": 100}
        ).json()
        assert all(x["distance_km"] <= 1.0 for x in body["items"])

    def test_거리를_안_주면_distance는_비어있다(self, client):
        body = client.get("/restaurants", params={"limit": 3}).json()
        assert all(x["distance_km"] is None for x in body["items"])


class TestValidation:
    def test_lat만_주면_400(self, client):
        assert client.get("/restaurants", params={"lat": 37.2}).status_code == 400

    def test_radius만_주면_400(self, client):
        assert client.get("/restaurants", params={"radius_km": 1}).status_code == 400

    def test_범위를_벗어난_좌표는_422(self, client):
        res = client.get("/restaurants", params={"lat": 999, "lng": 127})
        assert res.status_code == 422


class TestDetail:
    def test_노출_대상은_조회된다(self, client):
        with SessionLocal() as db:
            rid = db.scalar(
                select(Restaurant.id).where(
                    Restaurant.geocode_status.in_(VISIBLE_GEOCODE_STATUSES),
                    Restaurant.lat.is_not(None),
                )
            )
        assert client.get(f"/restaurants/{rid}").status_code == 200

    def test_좌표없는_행은_500이_아니라_404(self, client):
        """응답 스키마가 lat/lng 을 필수로 받아서, 그냥 돌려주면 검증에 걸려 500 이 난다."""
        with SessionLocal() as db:
            rid = db.scalar(select(Restaurant.id).where(Restaurant.lat.is_(None)))
        if rid is None:
            pytest.skip("좌표 없는 행이 없다")
        assert client.get(f"/restaurants/{rid}").status_code == 404

    def test_unverified_는_상세로도_안_보인다(self, client):
        with SessionLocal() as db:
            rid = db.scalar(
                select(Restaurant.id).where(Restaurant.geocode_status == "unverified")
            )
        if rid is None:
            pytest.skip("unverified 행이 없다")
        assert client.get(f"/restaurants/{rid}").status_code == 404

    def test_없는_id는_404(self, client):
        assert client.get("/restaurants/999999999").status_code == 404
