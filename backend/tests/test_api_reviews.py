"""식사평 API 계약과 클라이언트 인증 위조 방지 테스트."""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.core.constants import VISIBLE_GEOCODE_STATUSES
from app.database import SessionLocal
from app.main import app
from app.models import Restaurant


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
    email = f"review_{tag}@example.com"
    response = client.post("/auth/signup", json={
        "email": email, "password": "hwaseong1234", "nickname": f"리뷰{tag[:4]}"
    })
    headers = {"Authorization": f"Bearer {response.json()['access_token']}"}
    yield headers
    with SessionLocal() as db:
        db.execute(text("DELETE FROM users WHERE email=:email"), {"email": email})
        db.commit()


def test_클라이언트는_영수증_인증을_지정할_수_없다(client, user, restaurant_ids):
    response = client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[0], "is_receipt_verified": True
    })
    assert response.status_code == 422


def test_일반_리뷰는_0P이며_인증_배지가_없다(client, user, restaurant_ids):
    response = client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[0], "rating": 5, "comment": "좋아요"
    })
    assert response.status_code == 201, response.text
    body = response.json()
    assert body["earned_points"] == 0
    assert body["total_points"] == 0
    assert body["review"]["is_receipt_verified"] is False
    assert body["review"]["is_hwaseong_certified"] is False


def test_같은_가게에_두_번은_409(client, user, restaurant_ids):
    payload = {"restaurant_id": restaurant_ids[1]}
    assert client.post("/reviews", headers=user, json=payload).status_code == 201
    assert client.post("/reviews", headers=user, json=payload).status_code == 409


def test_로그인과_입력값을_검증한다(client, user, restaurant_ids):
    assert client.post("/reviews", json={"restaurant_id": restaurant_ids[0]}).status_code == 401
    assert client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[0], "rating": 6
    }).status_code == 422
    assert client.post("/reviews", headers=user, json={"restaurant_id": 999999999}).status_code == 404
    assert client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[0], "tags": [f"t{i}" for i in range(11)]
    }).status_code == 422


def test_목록_내리뷰_삭제(client, user, restaurant_ids):
    created = client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[2], "tags": ["가성비"]
    }).json()["review"]
    listing = client.get("/reviews", params={"restaurant_id": restaurant_ids[2]}).json()
    assert listing["total"] >= 1
    assert all(item["restaurant_id"] == restaurant_ids[2] for item in listing["items"])
    assert listing["items"][0]["nickname"]
    assert client.get("/reviews/me", headers=user).json()["total"] == 1
    assert client.delete(f"/reviews/{created['id']}", headers=user).status_code == 204
    assert client.get("/auth/me", headers=user).json()["points"] == 0


def test_내리뷰는_로그인이_필요하다(client):
    assert client.get("/reviews/me").status_code == 401


def test_남의_리뷰는_삭제할_수_없다(client, user, restaurant_ids):
    created = client.post("/reviews", headers=user, json={
        "restaurant_id": restaurant_ids[0]
    }).json()["review"]

    tag = uuid.uuid4().hex[:8]
    email = f"other_{tag}@example.com"
    signup = client.post("/auth/signup", json={
        "email": email, "password": "hwaseong1234", "nickname": f"타인{tag[:4]}"
    })
    other = {"Authorization": f"Bearer {signup.json()['access_token']}"}
    try:
        assert client.delete(f"/reviews/{created['id']}", headers=other).status_code == 404
    finally:
        with SessionLocal() as db:
            db.execute(text("DELETE FROM users WHERE email=:email"), {"email": email})
            db.commit()
