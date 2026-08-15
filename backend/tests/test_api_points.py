"""별점 집계와 서버 주도 포인트 적립·교환 테스트."""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import POINTS_PER_CONVERT, REVIEW_POINTS, VISIBLE_GEOCODE_STATUSES
from app.database import SessionLocal
from app.main import app
from app.models import Restaurant
from app.services.points import add_points


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as exc:
        pytest.skip(f"DB 연결 불가: {exc}")
    app.state.limiter.enabled = False
    yield TestClient(app)
    app.state.limiter.enabled = True


@pytest.fixture(scope="module")
def restaurant_ids():
    with SessionLocal() as db:
        return list(db.scalars(select(Restaurant.id).where(
            Restaurant.geocode_status.in_(VISIBLE_GEOCODE_STATUSES)
        ).limit(3)).all())


@pytest.fixture
def user(client):
    tag = uuid.uuid4().hex[:8]
    email = f"points_{tag}@example.com"
    response = client.post("/auth/signup", json={
        "email": email, "password": "hwaseong1234", "nickname": f"포인트{tag[:3]}"
    })
    headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
    yield headers
    with SessionLocal() as db:
        db.execute(text("DELETE FROM users WHERE email=:email"), {"email": email})
        db.commit()


def _grant(client, headers, amount):
    user_id = client.get("/auth/me", headers=headers).json()["id"]
    with SessionLocal() as db:
        add_points(db, user_id, amount, "서버 검증 적립")
        db.commit()


def test_별점과_리뷰수가_집계된다(client, user, restaurant_ids):
    rid = restaurant_ids[0]
    before = client.get(f"/restaurants/{rid}").json()
    assert client.post("/reviews", headers=user, json={"restaurant_id": rid, "rating": 4}).status_code == 201
    after = client.get(f"/restaurants/{rid}").json()
    assert after["review_count"] == before["review_count"] + 1
    assert after["avg_rating"] is not None


def test_서버_적립은_내역과_잔액에_반영된다(client, user):
    _grant(client, user, REVIEW_POINTS)
    body = client.get("/auth/me/points", headers=user).json()
    assert body["balance"] == REVIEW_POINTS
    assert body["items"][0]["delta"] == REVIEW_POINTS
    assert body["items"][0]["reason"] == "서버 검증 적립"


def test_포인트_내역은_최신순이다(client, user):
    _grant(client, user, REVIEW_POINTS)
    _grant(client, user, REVIEW_POINTS)
    items = client.get("/auth/me/points", headers=user).json()["items"]
    created_at = [item["created_at"] for item in items]
    assert created_at == sorted(created_at, reverse=True)


def test_포인트_전환(client, user):
    _grant(client, user, POINTS_PER_CONVERT)
    response = client.post("/auth/me/points/exchange", headers=user, json={"points": POINTS_PER_CONVERT})
    assert response.status_code == 200, response.text
    assert response.json()["balance"] == 0
    history = client.get("/auth/me/points", headers=user).json()["items"]
    assert history[0]["delta"] == -POINTS_PER_CONVERT


def test_잔액과_전환단위를_검증한다(client, user):
    _grant(client, user, REVIEW_POINTS)
    assert client.post("/auth/me/points/exchange", headers=user, json={"points": POINTS_PER_CONVERT}).status_code == 400
    assert client.get("/auth/me", headers=user).json()["points"] == REVIEW_POINTS
    assert client.post("/auth/me/points/exchange", headers=user, json={"points": 500}).status_code == 422
    assert client.post("/auth/me/points/exchange", headers=user, json={"points": 1500}).status_code == 422
    assert client.post("/auth/me/points/exchange", json={"points": POINTS_PER_CONVERT}).status_code == 401


def test_포인트_내역은_로그인이_필요하다(client):
    assert client.get("/auth/me/points").status_code == 401
