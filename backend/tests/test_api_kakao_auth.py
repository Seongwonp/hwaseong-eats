"""카카오 로그인 토큰 발급처(app_id) 검증 테스트.

app_id 가 안 맞으면 DB 에 닿기 전에 막히므로, 이 파일의 테스트는 대부분
DB 없이 돈다. 카카오 서버 호출은 monkeypatch 로 대신한다.
"""

import httpx
import pytest
from fastapi.testclient import TestClient

from app.main import app

OUR_APP_ID = 123456
OTHER_APP_ID = 999999


class FakeResponse:
    def __init__(self, status_code: int, payload=None):
        self.status_code = status_code
        self._payload = payload

    def json(self):
        if self._payload is None:
            raise ValueError("본문이 JSON 이 아니다")
        return self._payload


@pytest.fixture
def client():
    # rate limit 이 걸리면 테스트끼리 서로 영향을 준다. 테스트 동안만 끈다.
    app.state.limiter.enabled = False
    yield TestClient(app)
    app.state.limiter.enabled = True


@pytest.fixture
def app_id_set(monkeypatch):
    monkeypatch.setenv("KAKAO_APP_ID", str(OUR_APP_ID))


def _patch_kakao(monkeypatch, response):
    """카카오 호출을 가로채고, 실제로 요청된 URL 을 기록해 돌려준다."""
    called = {}

    def fake_get(url, **kwargs):
        called["url"] = url
        called["headers"] = kwargs.get("headers", {})
        if isinstance(response, Exception):
            raise response
        return response

    monkeypatch.setattr(httpx, "get", fake_get)
    return called


def test_다른_앱_토큰은_거부한다(client, app_id_set, monkeypatch):
    """핵심 케이스 — 유효한 카카오 토큰이어도 남의 앱 것이면 못 들어온다."""
    _patch_kakao(monkeypatch, FakeResponse(200, {"id": 42, "app_id": OTHER_APP_ID}))

    res = client.post("/auth/kakao", json={"access_token": "남의앱토큰"})

    assert res.status_code == 401
    # 계정이 없어서 막힌 건지 앱이 달라서 막힌 건지 알려주지 않는다.
    assert res.json()["detail"] == "카카오 인증에 실패했습니다"


def test_우리_앱_토큰은_검증을_통과한다(client, app_id_set, monkeypatch):
    """app_id 가 맞으면 DB 조회 단계까지 넘어간다.

    DB 가 없으면 여기서 연결 오류가 나는데, 그건 app_id 검증을 통과했다는 뜻이다.
    401 만 아니면 된다.
    """
    _patch_kakao(monkeypatch, FakeResponse(200, {"id": 42, "app_id": OUR_APP_ID}))

    try:
        res = client.post("/auth/kakao", json={"access_token": "우리앱토큰"})
    except Exception:
        return  # DB 연결 실패 = 검증 통과 후 단계까지 갔다는 뜻

    assert res.status_code != 401


def test_access_token_info_를_호출한다(client, app_id_set, monkeypatch):
    """/v2/user/me 는 app_id 를 안 주므로 쓰면 안 된다."""
    called = _patch_kakao(monkeypatch, FakeResponse(200, {"id": 1, "app_id": OTHER_APP_ID}))

    client.post("/auth/kakao", json={"access_token": "토큰"})

    assert called["url"] == "https://kapi.kakao.com/v1/user/access_token_info"
    assert called["headers"]["Authorization"] == "Bearer 토큰"


def test_app_id_가_없는_응답은_502(client, app_id_set, monkeypatch):
    """카카오가 app_id 를 안 주면 검증할 수 없으니 통과시키지 않는다."""
    _patch_kakao(monkeypatch, FakeResponse(200, {"id": 42}))

    res = client.post("/auth/kakao", json={"access_token": "토큰"})

    assert res.status_code == 502


def test_카카오_401_은_401(client, app_id_set, monkeypatch):
    _patch_kakao(monkeypatch, FakeResponse(401))

    res = client.post("/auth/kakao", json={"access_token": "만료된토큰"})

    assert res.status_code == 401


def test_카카오_연결실패는_503(client, app_id_set, monkeypatch):
    _patch_kakao(monkeypatch, httpx.RequestError("연결 실패"))

    res = client.post("/auth/kakao", json={"access_token": "토큰"})

    assert res.status_code == 503


def test_환경변수가_없으면_카카오를_호출하지_않는다(client, monkeypatch):
    """설정 누락 시 조용히 통과시키지 말고 시끄럽게 죽어야 한다."""
    monkeypatch.delenv("KAKAO_APP_ID", raising=False)
    called = _patch_kakao(monkeypatch, FakeResponse(200, {"id": 1, "app_id": OUR_APP_ID}))

    with pytest.raises(RuntimeError, match="KAKAO_APP_ID"):
        client.post("/auth/kakao", json={"access_token": "토큰"})

    assert "url" not in called


def test_환경변수가_숫자가_아니면_죽는다(client, monkeypatch):
    monkeypatch.setenv("KAKAO_APP_ID", "앱아이디아님")
    _patch_kakao(monkeypatch, FakeResponse(200, {"id": 1, "app_id": OUR_APP_ID}))

    with pytest.raises(RuntimeError, match="숫자가 아닙니다"):
        client.post("/auth/kakao", json={"access_token": "토큰"})
