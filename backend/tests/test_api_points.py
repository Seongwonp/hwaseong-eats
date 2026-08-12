"""평균 별점 집계, 포인트 내역·전환 테스트.

프론트 담당 요청 3건을 고정한다.
"""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import POINTS_PER_CONVERT, REVIEW_POINTS, VISIBLE_GEOCODE_STATUSES
from app.database import SessionLocal
from app.main import app
from app.models import Restaurant


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as e:
        pytest.skip(f"DB 연결 불가: {e}")
    app.state.limiter.enabled = False
    yield TestClient(app)
    app.state.limiter.enabled = True


@pytest.fixture(scope="module")
def restaurant_ids():
    with SessionLocal() as db:
        return list(
            db.scalars(
                select(Restaurant.id)
                .where(Restaurant.geocode_status.in_(VISIBLE_GEOCODE_STATUSES))
                .limit(4)
            ).all()
        )


@pytest.fixture
def verified_user(client):
    tag = uuid.uuid4().hex[:8]
    email = f"pt_{tag}@example.com"
    res = client.post(
        "/auth/signup",
        json={"email": email, "password": "hwaseong1234", "nickname": f"포인트{tag[:3]}"},
    )
    headers = {"Authorization": f"Bearer {res.json()['access_token']}"}
    client.post("/auth/verify", headers=headers)
    yield headers
    with SessionLocal() as db:
        db.execute(text("DELETE FROM users WHERE email = :e"), {"e": email})
        db.commit()


class TestRatingAggregate:
    def test_리뷰가_없으면_별점은_null_개수는_0(self, client):
        item = client.get("/restaurants", params={"limit": 1}).json()["items"][0]
        assert "avg_rating" in item and "review_count" in item

    def test_별점을_남기면_평균에_반영된다(self, client, verified_user, restaurant_ids):
        rid = restaurant_ids[3]
        before = client.get(f"/restaurants/{rid}").json()

        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": rid, "rating": 4, "is_receipt_verified": True},
        )
        after = client.get(f"/restaurants/{rid}").json()

        assert after["review_count"] == before["review_count"] + 1
        assert after["avg_rating"] is not None

    def test_별점_없는_식사평도_개수에는_들어간다(self, client, verified_user, restaurant_ids):
        rid = restaurant_ids[2]
        before = client.get(f"/restaurants/{rid}").json()

        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": rid, "is_receipt_verified": True},
        )
        after = client.get(f"/restaurants/{rid}").json()

        assert after["review_count"] == before["review_count"] + 1

    def test_목록에도_집계가_붙는다(self, client):
        items = client.get("/restaurants", params={"limit": 5}).json()["items"]
        assert all(isinstance(x["review_count"], int) for x in items)


class TestPointHistory:
    def test_적립하면_내역이_남는다(self, client, verified_user, restaurant_ids):
        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        )
        body = client.get("/auth/me/points", headers=verified_user).json()

        assert body["total"] == 1
        assert body["balance"] == REVIEW_POINTS
        assert body["items"][0]["delta"] == REVIEW_POINTS
        assert body["items"][0]["reason"] == "화성인증 식사평"

    def test_최신순으로_나온다(self, client, verified_user, restaurant_ids):
        for rid in restaurant_ids[:2]:
            client.post(
                "/reviews",
                headers=verified_user,
                json={"restaurant_id": rid, "is_receipt_verified": True},
            )
        items = client.get("/auth/me/points", headers=verified_user).json()["items"]
        assert [x["created_at"] for x in items] == sorted(
            [x["created_at"] for x in items], reverse=True
        )

    def test_로그인이_필요하다(self, client):
        assert client.get("/auth/me/points").status_code == 401


class TestExchange:
    def _earn(self, client, headers, restaurant_ids, count):
        for rid in restaurant_ids[:count]:
            client.post(
                "/reviews",
                headers=headers,
                json={"restaurant_id": rid, "is_receipt_verified": True},
            )

    def test_전환하면_차감된다(self, client, verified_user, restaurant_ids):
        self._earn(client, verified_user, restaurant_ids, 2)  # 1,000P

        res = client.post(
            "/auth/me/points/exchange",
            headers=verified_user,
            json={"points": POINTS_PER_CONVERT},
        )
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["exchanged_points"] == POINTS_PER_CONVERT
        assert body["exchanged_krw"] == POINTS_PER_CONVERT
        assert body["balance"] == 0

    def test_전환_내역이_남는다(self, client, verified_user, restaurant_ids):
        self._earn(client, verified_user, restaurant_ids, 2)
        client.post(
            "/auth/me/points/exchange",
            headers=verified_user,
            json={"points": POINTS_PER_CONVERT},
        )
        items = client.get("/auth/me/points", headers=verified_user).json()["items"]
        assert items[0]["delta"] == -POINTS_PER_CONVERT
        assert items[0]["reason"] == "화성페이 전환"

    def test_잔액보다_많이_전환하면_400(self, client, verified_user, restaurant_ids):
        self._earn(client, verified_user, restaurant_ids, 1)  # 500P 뿐
        res = client.post(
            "/auth/me/points/exchange",
            headers=verified_user,
            json={"points": POINTS_PER_CONVERT},
        )
        assert res.status_code == 400

    def test_잔액이_깎이지_않았는지_확인한다(self, client, verified_user, restaurant_ids):
        self._earn(client, verified_user, restaurant_ids, 1)
        client.post(
            "/auth/me/points/exchange",
            headers=verified_user,
            json={"points": POINTS_PER_CONVERT},
        )
        me = client.get("/auth/me", headers=verified_user).json()
        assert me["points"] == REVIEW_POINTS

    def test_최소_단위_미만은_422(self, client, verified_user):
        res = client.post(
            "/auth/me/points/exchange", headers=verified_user, json={"points": 500}
        )
        assert res.status_code == 422

    def test_1000P_단위가_아니면_422(self, client, verified_user):
        res = client.post(
            "/auth/me/points/exchange", headers=verified_user, json={"points": 1500}
        )
        assert res.status_code == 422

    def test_로그인이_필요하다(self, client):
        res = client.post(
            "/auth/me/points/exchange", json={"points": POINTS_PER_CONVERT}
        )
        assert res.status_code == 401
