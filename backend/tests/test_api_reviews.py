"""식사평 등록·조회·삭제와 포인트 적립 테스트."""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import REVIEW_POINTS, VISIBLE_GEOCODE_STATUSES
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
        ids = db.scalars(
            select(Restaurant.id)
            .where(Restaurant.geocode_status.in_(VISIBLE_GEOCODE_STATUSES))
            .limit(3)
        ).all()
    return list(ids)


def _signup(client):
    tag = uuid.uuid4().hex[:8]
    email = f"rv_{tag}@example.com"
    res = client.post(
        "/auth/signup",
        json={"email": email, "password": "hwaseong1234", "nickname": f"리뷰{tag[:4]}"},
    )
    assert res.status_code == 201, res.text
    return email, {"Authorization": f"Bearer {res.json()['access_token']}"}


@pytest.fixture
def plain_user(client):
    """주민인증을 하지 않은 계정."""
    email, headers = _signup(client)
    yield headers
    with SessionLocal() as db:
        db.execute(text("DELETE FROM users WHERE email = :em"), {"em": email})
        db.commit()


@pytest.fixture
def verified_user(client):
    """주민인증까지 마친 계정."""
    email, headers = _signup(client)
    assert client.post("/auth/verify", headers=headers).status_code == 200
    yield headers
    with SessionLocal() as db:
        db.execute(text("DELETE FROM users WHERE email = :em"), {"em": email})
        db.commit()


class TestCreate:
    def test_화성인증_리뷰는_500P_적립(self, client, verified_user, restaurant_ids):
        res = client.post(
            "/reviews",
            headers=verified_user,
            json={
                "restaurant_id": restaurant_ids[0],
                "tags": ["양 많음", "가성비"],
                "rating": 5,
                "comment": "국물이 진하다",
                "is_receipt_verified": True,
            },
        )
        assert res.status_code == 201, res.text
        body = res.json()
        assert body["earned_points"] == REVIEW_POINTS
        assert body["total_points"] == REVIEW_POINTS
        assert body["review"]["is_hwaseong_certified"] is True

    def test_영수증_인증이_없으면_포인트가_없다(self, client, verified_user, restaurant_ids):
        res = client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": False},
        )
        assert res.json()["earned_points"] == 0
        assert res.json()["review"]["is_hwaseong_certified"] is False

    def test_주민인증이_없으면_포인트가_없다(self, client, plain_user, restaurant_ids):
        res = client.post(
            "/reviews",
            headers=plain_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        )
        assert res.status_code == 201
        assert res.json()["earned_points"] == 0

    def test_같은_가게에_두_번은_409(self, client, verified_user, restaurant_ids):
        payload = {"restaurant_id": restaurant_ids[1], "is_receipt_verified": True}
        assert client.post("/reviews", headers=verified_user, json=payload).status_code == 201
        assert client.post("/reviews", headers=verified_user, json=payload).status_code == 409

    def test_중복_시도로_포인트가_늘지_않는다(self, client, verified_user, restaurant_ids):
        payload = {"restaurant_id": restaurant_ids[1], "is_receipt_verified": True}
        client.post("/reviews", headers=verified_user, json=payload)
        client.post("/reviews", headers=verified_user, json=payload)
        me = client.get("/auth/me", headers=verified_user).json()
        assert me["points"] == REVIEW_POINTS

    def test_없는_음식점은_404(self, client, verified_user):
        res = client.post(
            "/reviews", headers=verified_user, json={"restaurant_id": 999999999}
        )
        assert res.status_code == 404

    def test_로그인_없이는_401(self, client, restaurant_ids):
        res = client.post("/reviews", json={"restaurant_id": restaurant_ids[0]})
        assert res.status_code == 401

    def test_별점_범위를_벗어나면_422(self, client, verified_user, restaurant_ids):
        res = client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "rating": 6},
        )
        assert res.status_code == 422

    def test_태그가_너무_많으면_422(self, client, verified_user, restaurant_ids):
        res = client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "tags": [f"t{i}" for i in range(11)]},
        )
        assert res.status_code == 422


class TestList:
    def test_음식점별_조회(self, client, verified_user, restaurant_ids):
        rid = restaurant_ids[2]
        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": rid, "is_receipt_verified": True},
        )
        body = client.get("/reviews", params={"restaurant_id": rid}).json()
        assert body["total"] >= 1
        assert all(x["restaurant_id"] == rid for x in body["items"])

    def test_닉네임이_함께_나온다(self, client, verified_user, restaurant_ids):
        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        )
        body = client.get(
            "/reviews", params={"restaurant_id": restaurant_ids[0]}
        ).json()
        assert body["items"][0]["nickname"]

    def test_내_리뷰_조회(self, client, verified_user, restaurant_ids):
        client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        )
        body = client.get("/reviews/me", headers=verified_user).json()
        assert body["total"] == 1

    def test_내_리뷰는_로그인이_필요하다(self, client):
        assert client.get("/reviews/me").status_code == 401


class TestDelete:
    def test_삭제하면_포인트가_회수된다(self, client, verified_user, restaurant_ids):
        created = client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        ).json()
        assert created["total_points"] == REVIEW_POINTS

        rid = created["review"]["id"]
        assert client.delete(f"/reviews/{rid}", headers=verified_user).status_code == 204

        me = client.get("/auth/me", headers=verified_user).json()
        assert me["points"] == 0

    def test_남의_리뷰는_지울_수_없다(self, client, verified_user, plain_user, restaurant_ids):
        created = client.post(
            "/reviews",
            headers=verified_user,
            json={"restaurant_id": restaurant_ids[0], "is_receipt_verified": True},
        ).json()
        rid = created["review"]["id"]
        assert client.delete(f"/reviews/{rid}", headers=plain_user).status_code == 404
