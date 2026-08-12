"""회원가입·로그인·주민인증 테스트."""

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.database import SessionLocal
from app.main import app
from app.models import User


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as e:
        pytest.skip(f"DB 연결 불가: {e}")
    # rate limit 이 걸리면 테스트끼리 서로 영향을 준다. 테스트 동안만 끈다.
    app.state.limiter.enabled = False
    yield TestClient(app)
    app.state.limiter.enabled = True


@pytest.fixture
def account(client):
    """매번 새 계정을 만들고 끝나면 지운다."""
    tag = uuid.uuid4().hex[:8]
    body = {
        "login_id": f"test_{tag}",
        "password": "hwaseong1234",
        "nickname": f"테스트{tag[:4]}",
    }
    res = client.post("/auth/signup", json=body)
    assert res.status_code == 201, res.text
    token = res.json()["access_token"]

    yield body, token, {"Authorization": f"Bearer {token}"}

    with SessionLocal() as db:
        db.execute(
            text("DELETE FROM users WHERE login_id = :lid"), {"lid": body["login_id"]}
        )
        db.commit()


class TestSignup:
    def test_가입하면_토큰이_나온다(self, account):
        _, token, _ = account
        assert token

    def test_비밀번호는_평문으로_저장되지_않는다(self, account):
        body, _, _ = account
        with SessionLocal() as db:
            user = db.query(User).filter_by(login_id=body["login_id"]).one()
        assert user.password_hash != body["password"]
        assert user.password_hash.startswith("$2b$")

    def test_아이디_중복은_409(self, client, account):
        body, _, _ = account
        res = client.post("/auth/signup", json={**body, "nickname": "다른닉네임"})
        assert res.status_code == 409

    def test_닉네임_중복도_409(self, client, account):
        body, _, _ = account
        res = client.post("/auth/signup", json={**body, "login_id": "other_id_123"})
        assert res.status_code == 409

    def test_짧은_비밀번호는_거부한다(self, client):
        res = client.post(
            "/auth/signup",
            json={"login_id": "shortpw01", "password": "1234", "nickname": "짧은비번"},
        )
        assert res.status_code == 422

    def test_아이디에_특수문자는_거부한다(self, client):
        res = client.post(
            "/auth/signup",
            json={"login_id": "bad id!", "password": "hwaseong1234", "nickname": "특수"},
        )
        assert res.status_code == 422


class TestLogin:
    def test_로그인_성공(self, client, account):
        body, _, _ = account
        res = client.post(
            "/auth/login",
            json={"login_id": body["login_id"], "password": body["password"]},
        )
        assert res.status_code == 200
        assert res.json()["access_token"]

    def test_비밀번호가_틀리면_401(self, client, account):
        body, _, _ = account
        res = client.post(
            "/auth/login", json={"login_id": body["login_id"], "password": "wrongpw123"}
        )
        assert res.status_code == 401

    def test_없는_아이디도_같은_401_메시지(self, client, account):
        """어느 아이디가 존재하는지 알려주면 계정을 훑을 수 있다."""
        body, _, _ = account
        wrong_pw = client.post(
            "/auth/login", json={"login_id": body["login_id"], "password": "wrongpw123"}
        )
        no_user = client.post(
            "/auth/login", json={"login_id": "nobody_here_xyz", "password": "wrongpw123"}
        )
        assert wrong_pw.status_code == no_user.status_code == 401
        assert wrong_pw.json()["detail"] == no_user.json()["detail"]


class TestMe:
    def test_토큰으로_내_정보를_본다(self, client, account):
        body, _, headers = account
        res = client.get("/auth/me", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["login_id"] == body["login_id"]
        assert data["points"] == 0
        assert data["is_resident_verified"] is False

    def test_토큰이_없으면_401(self, client):
        assert client.get("/auth/me").status_code == 401

    def test_위조_토큰은_401(self, client, account):
        _, token, _ = account
        res = client.get(
            "/auth/me", headers={"Authorization": f"Bearer {token[:-3]}xxx"}
        )
        assert res.status_code == 401


class TestResidentVerify:
    def test_인증하면_만료일이_6개월_뒤로_잡힌다(self, client, account):
        from datetime import datetime

        _, _, headers = account
        res = client.post("/auth/verify", headers=headers)
        assert res.status_code == 200

        data = res.json()
        assert data["is_resident_verified"] is True
        expires = datetime.fromisoformat(data["resident_expires_at"])
        days = (expires - datetime.now(expires.tzinfo)).days
        assert 175 < days <= 182

    def test_토큰_없이는_인증할_수_없다(self, client):
        assert client.post("/auth/verify").status_code == 401
