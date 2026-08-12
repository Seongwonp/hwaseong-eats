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
        "email": f"test_{tag}@example.com",
        "password": "hwaseong1234",
        "nickname": f"테스트{tag[:4]}",
    }
    res = client.post("/auth/signup", json=body)
    assert res.status_code == 201, res.text
    token = res.json()["access_token"]

    yield body, token, {"Authorization": f"Bearer {token}"}

    with SessionLocal() as db:
        db.execute(
            text("DELETE FROM users WHERE email = :em"), {"em": body["email"]}
        )
        db.commit()


class TestSignup:
    def test_가입하면_토큰이_나온다(self, account):
        _, token, _ = account
        assert token

    def test_비밀번호는_평문으로_저장되지_않는다(self, account):
        body, _, _ = account
        with SessionLocal() as db:
            user = db.query(User).filter_by(email=body["email"]).one()
        assert user.password_hash != body["password"]
        assert user.password_hash.startswith("$2b$")

    def test_아이디_중복은_409(self, client, account):
        body, _, _ = account
        res = client.post("/auth/signup", json={**body, "nickname": "다른닉네임"})
        assert res.status_code == 409

    def test_닉네임_중복도_409(self, client, account):
        body, _, _ = account
        res = client.post("/auth/signup", json={**body, "email": "other_addr@example.com"})
        assert res.status_code == 409

    def test_짧은_비밀번호는_거부한다(self, client):
        res = client.post(
            "/auth/signup",
            json={"email": "shortpw@example.com", "password": "1234", "nickname": "짧은비번"},
        )
        assert res.status_code == 422

    def test_이메일_형식이_아니면_거부한다(self, client):
        res = client.post(
            "/auth/signup",
            json={"email": "not-an-email", "password": "hwaseong1234", "nickname": "형식"},
        )
        assert res.status_code == 422


class TestLogin:
    def test_로그인_성공(self, client, account):
        body, _, _ = account
        res = client.post(
            "/auth/login",
            json={"email": body["email"], "password": body["password"]},
        )
        assert res.status_code == 200
        assert res.json()["access_token"]

    def test_비밀번호가_틀리면_401(self, client, account):
        body, _, _ = account
        res = client.post(
            "/auth/login", json={"email": body["email"], "password": "wrongpw123"}
        )
        assert res.status_code == 401

    def test_없는_계정도_같은_401_메시지(self, client, account):
        """어느 이메일이 가입돼 있는지 알려주면 계정을 훑을 수 있다."""
        body, _, _ = account
        wrong_pw = client.post(
            "/auth/login", json={"email": body["email"], "password": "wrongpw123"}
        )
        no_user = client.post(
            "/auth/login", json={"email": "nobody_here@example.com", "password": "wrongpw123"}
        )
        assert wrong_pw.status_code == no_user.status_code == 401
        assert wrong_pw.json()["detail"] == no_user.json()["detail"]


class TestMe:
    def test_토큰으로_내_정보를_본다(self, client, account):
        body, _, headers = account
        res = client.get("/auth/me", headers=headers)
        assert res.status_code == 200
        data = res.json()
        assert data["email"] == body["email"]
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


class TestEmailNormalization:
    def test_대소문자만_다른_주소는_같은_계정으로_본다(self, client):
        """정규화하지 않으면 Case@X.com 과 case@x.com 이 별개 계정이 된다."""
        import uuid

        tag = uuid.uuid4().hex[:8]
        upper = f"Case_{tag}@Example.COM"
        lower = f"case_{tag}@example.com"

        first = client.post(
            "/auth/signup",
            json={"email": upper, "password": "hwaseong1234", "nickname": f"대{tag[:4]}"},
        )
        assert first.status_code == 201
        second = client.post(
            "/auth/signup",
            json={"email": lower, "password": "hwaseong1234", "nickname": f"소{tag[:4]}"},
        )
        assert second.status_code == 409

        with SessionLocal() as db:
            db.execute(text("DELETE FROM users WHERE email = :e"), {"e": lower})
            db.commit()

    def test_대문자로_가입해도_소문자로_로그인된다(self, client):
        import uuid

        tag = uuid.uuid4().hex[:8]
        client.post(
            "/auth/signup",
            json={
                "email": f"Mixed_{tag}@Example.com",
                "password": "hwaseong1234",
                "nickname": f"혼합{tag[:4]}",
            },
        )
        res = client.post(
            "/auth/login",
            json={"email": f"mixed_{tag}@example.com", "password": "hwaseong1234"},
        )
        assert res.status_code == 200

        with SessionLocal() as db:
            db.execute(
                text("DELETE FROM users WHERE email = :e"),
                {"e": f"mixed_{tag}@example.com"},
            )
            db.commit()
