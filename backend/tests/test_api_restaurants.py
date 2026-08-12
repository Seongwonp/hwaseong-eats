"""GET /restaurants 엔드포인트 테스트.

실제 DB 를 붙여 돈다. DB 가 안 떠 있으면 통째로 건너뛴다.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import VISIBLE_GEOCODE_STATUSES
from app.database import SessionLocal
from app.main import app
from app.models import Restaurant

DONGTAN_STATION = {"lat": 37.2014, "lng": 127.0985}


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as e:
        pytest.skip(f"DB 연결 불가: {e}")
    return TestClient(app)


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
