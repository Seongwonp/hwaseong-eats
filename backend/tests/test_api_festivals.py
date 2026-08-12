"""절기·축제 API 테스트."""

from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select, text

from app.database import SessionLocal
from app.main import app
from app.models import SeasonalEvent
from app.routers.festivals import NEAR_DAYS


@pytest.fixture(scope="module")
def client():
    try:
        with SessionLocal() as db:
            db.execute(text("SELECT 1"))
    except Exception as e:
        pytest.skip(f"DB 연결 불가: {e}")
    return TestClient(app)


@pytest.fixture(scope="module")
def seeded(client):
    with SessionLocal() as db:
        if not db.scalar(select(SeasonalEvent.id)):
            pytest.skip("seasonal_events 가 비어 있다. app.services.seasonal 을 먼저 돌릴 것")
    return True


class TestList:
    def test_전체_조회(self, client, seeded):
        body = client.get("/festivals").json()
        assert body["total"] > 0

    def test_종류별_필터(self, client, seeded):
        body = client.get("/festivals", params={"event_type": "축제"}).json()
        assert all(x["event_type"] == "축제" for x in body["items"])

    def test_축제만_좌표를_갖는다(self, client, seeded):
        for x in client.get("/festivals", params={"event_type": "축제"}).json()["items"]:
            assert x["lat"] is not None and x["radius_km"] is not None
        for x in client.get("/festivals", params={"event_type": "절기"}).json()["items"]:
            assert x["lat"] is None

    def test_시작일순으로_정렬된다(self, client, seeded):
        dates = [x["start_date"] for x in client.get("/festivals").json()["items"]]
        assert dates == sorted(dates)

    def test_지난_일정_제외(self, client, seeded):
        today = date.today().isoformat()
        for x in client.get("/festivals", params={"upcoming_only": True}).json()["items"]:
            assert x["end_date"] >= today


class TestToday:
    def test_응답_형식(self, client, seeded):
        body = client.get("/festivals/today").json()
        assert body["date"] == date.today().isoformat()
        assert "primary" in body and "items" in body

    def test_기념일_전후_3일만_잡힌다(self, client, seeded):
        today = date.today()
        for x in client.get("/festivals/today").json()["items"]:
            start = date.fromisoformat(x["start_date"])
            end = date.fromisoformat(x["end_date"])
            assert start - timedelta(days=NEAR_DAYS) <= today <= end + timedelta(days=NEAR_DAYS)

    def test_잡힌_일정은_전부_활성이다(self, client, seeded):
        assert all(x["is_active"] for x in client.get("/festivals/today").json()["items"])

    def test_primary는_items에서_고른다(self, client, seeded):
        body = client.get("/festivals/today").json()
        if body["primary"]:
            assert body["primary"]["id"] in [x["id"] for x in body["items"]]
        else:
            assert body["items"] == []


class TestDDay:
    def test_기간_중이면_0(self, client, seeded):
        today = date.today()
        for x in client.get("/festivals").json()["items"]:
            if x["start_date"] <= today.isoformat() <= x["end_date"]:
                assert x["d_day"] == 0

    def test_지난_일정은_음수(self, client, seeded):
        today = date.today().isoformat()
        past = [x for x in client.get("/festivals").json()["items"] if x["end_date"] < today]
        assert all(x["d_day"] < 0 for x in past)


class TestDetail:
    def test_단건_조회(self, client, seeded):
        first = client.get("/festivals", params={"limit": 1}).json()["items"][0]
        assert client.get(f"/festivals/{first['id']}").status_code == 200

    def test_없는_id는_404(self, client, seeded):
        assert client.get("/festivals/999999999").status_code == 404


class TestDataQuality:
    """프론트가 하드코딩하던 날짜에 오류가 있어 서버로 옮겼다."""

    def test_2026년_추석은_9월_24일이다(self, client, seeded):
        with SessionLocal() as db:
            chuseok = db.scalar(
                select(SeasonalEvent).where(
                    SeasonalEvent.name == "추석", SeasonalEvent.start_date >= date(2026, 1, 1)
                )
            )
        if chuseok is None:
            pytest.skip("2026 추석 데이터 없음")
        assert chuseok.start_date == date(2026, 9, 24)

    def test_2026년_초복은_7월_15일이다(self, client, seeded):
        with SessionLocal() as db:
            bok = db.scalar(
                select(SeasonalEvent).where(
                    SeasonalEvent.name == "초복", SeasonalEvent.start_date >= date(2026, 1, 1)
                )
            )
        if bok is None:
            pytest.skip("2026 초복 데이터 없음")
        assert bok.start_date == date(2026, 7, 15)


class TestDedupe:
    """표준데이터에 같은 축제가 회차 표기만 다르게 두 번 실려 있다."""

    def test_회차_연도_표기를_걷어낸다(self):
        from app.services.seasonal import normalize_festival_name as norm

        assert norm("화성뱃놀이축제") == norm("제15회 화성 뱃놀이 축제")
        assert norm("2025 화성 학생동아리 축제") == "화성학생동아리축제"

    def test_다른_축제까지_묶지는_않는다(self):
        from app.services.seasonal import normalize_festival_name as norm

        assert norm("제3회 도농 어울림 축제") != norm("제3회 화성 루나 빛 축제")

    def test_같은_날짜여야_중복으로_본다(self):
        """연례 축제가 해마다 지워지면 안 된다."""
        from app.services.seasonal import dedupe_festivals

        rows = [
            {"name": "화성뱃놀이축제", "start_date": date(2026, 5, 22), "location": "전곡항"},
            {"name": "제15회 화성 뱃놀이 축제", "start_date": date(2026, 5, 22), "location": None},
            {"name": "화성뱃놀이축제", "start_date": date(2027, 5, 21), "location": "전곡항"},
        ]
        assert len(dedupe_festivals(rows)) == 2

    def test_정보가_더_많은_쪽을_남긴다(self):
        from app.services.seasonal import dedupe_festivals

        rows = [
            {"name": "축제", "start_date": date(2026, 5, 1), "location": None, "lat": None},
            {"name": "제2회 축제", "start_date": date(2026, 5, 1), "location": "공원", "lat": 37.2},
        ]
        kept = dedupe_festivals(rows)
        assert len(kept) == 1 and kept[0]["location"] == "공원"

    def test_실제_데이터에_중복이_없다(self, client, seeded):
        from app.services.seasonal import normalize_festival_name as norm

        items = client.get("/festivals", params={"event_type": "축제"}).json()["items"]
        keys = [(norm(x["name"]), x["start_date"]) for x in items]
        assert len(keys) == len(set(keys))
