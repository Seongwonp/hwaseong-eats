"""절기·명절·축제 수집.

절기와 잡절(초복·중복·말복)은 한국천문연구원 특일 정보를 정리한 저장소에서 받는다.
인증키가 필요 없고 매년 갱신된다.

축제는 공공데이터포털 전국문화축제표준데이터 CSV 에서 화성시 것만 뽑는다.
좌표가 들어 있어 축제장 반경 강조(기획서 p.7)에 바로 쓸 수 있다.

프론트가 하드코딩하던 날짜에는 오류가 있었다 — 2026년 추석을 10/6 으로,
도농어울림축제를 10/10 으로 잡고 있었는데 실제로는 9/24 와 9/19 다.

실행: uv run python -m app.services.seasonal
"""

from __future__ import annotations

import csv
import io
import re
from datetime import date, datetime
from pathlib import Path

import httpx
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert

from app.core.http import request_with_retry
from app.database import SessionLocal
from app.models import SeasonalEvent

HOLIDAY_URL = "https://holidays.dist.be/{year}.json"
DATA_DIR = Path(__file__).resolve().parents[2] / "data"
FESTIVAL_CSV = DATA_DIR / "전국문화축제표준데이터.csv"

# 축제 주변 강조 반경. 기획서 p.7 기준.
FESTIVAL_RADIUS_KM = 3.0

# 우리가 다루는 날. 24절기 전부를 띄우면 "때에 맞춰"라는 의미가 흐려진다.
# 값은 그날 먹는 음식.
TRACKED_DAYS: dict[str, str] = {
    "초복": "삼계탕·보양식",
    "중복": "삼계탕·장어",
    "말복": "삼계탕·장어",
    "동지": "팥죽",
    "정월대보름": "오곡밥·나물",
    "설날": "떡국",
    "추석": "송편·전·나물",
    "입춘": "봄나물",
    "입추": "제철 과일",
}

_NAME_TO_TYPE = {"설날": "명절", "추석": "명절"}

# 같은 축제가 회차·연도 표기만 다르게 두 번 등록돼 있다.
#   '화성뱃놀이축제' 와 '제15회 화성 뱃놀이 축제'
# 이 표기를 걷어내고 공백을 지우면 같은 이름이 된다.
_ORDINAL = re.compile(r"제?\s*\d+\s*회|20\d{2}\s*년?")
_SPACE = re.compile(r"\s+")


def normalize_festival_name(name: str) -> str:
    return _SPACE.sub("", _ORDINAL.sub("", name or ""))


def dedupe_festivals(rows: list[dict]) -> list[dict]:
    """회차 표기만 다른 중복을 하나로 줄인다.

    이름을 정규화한 값과 시작일이 같으면 같은 축제로 본다. 날짜까지 같아야 하므로
    같은 이름의 연례 축제가 해마다 지워지지는 않는다.
    남길 쪽은 정보가 더 많은 행 — 회차가 붙은 이름이 대체로 최신 등록이다.
    """
    best: dict[tuple[str, date], dict] = {}
    for row in rows:
        key = (normalize_festival_name(row["name"]), row["start_date"])
        prev = best.get(key)
        if prev is None or _richness(row) > _richness(prev):
            best[key] = row

    dropped = len(rows) - len(best)
    if dropped:
        print(f"  중복 축제 {dropped}건 제거")
    return list(best.values())


def _richness(row: dict) -> int:
    """채워진 항목 수. 같은 축제면 더 많이 채워진 쪽을 남긴다."""
    return sum(1 for k in ("location", "lat", "lng", "description") if row.get(k))


def fetch_days(year: int) -> list[dict]:
    """절기·명절을 연 단위로 가져온다.

    다음 해 데이터는 그 해가 가까워져야 올라온다. 없으면 조용히 건너뛴다.
    """
    with httpx.Client() as client:
        res = request_with_retry(client, "GET", HOLIDAY_URL.format(year=year), timeout=30)
    if res.status_code == 404:
        return []
    res.raise_for_status()

    rows: dict[tuple[str, date], dict] = {}
    for item in res.json():
        name = item["name"]
        if name not in TRACKED_DAYS:
            continue
        day = datetime.strptime(item["date"], "%Y-%m-%d").date()
        # 연휴는 같은 이름이 여러 날 들어온다. 한 해에 한 건으로 합친다.
        key = (name, day.year)
        existing = rows.get(key)
        if existing is None:
            rows[key] = {
                "name": name,
                "event_type": _NAME_TO_TYPE.get(name, "절기"),
                "start_date": day,
                "end_date": day,
                "food_keyword": TRACKED_DAYS[name],
                "location": None,
                "lat": None,
                "lng": None,
                "radius_km": None,
                "description": None,
            }
        else:
            existing["start_date"] = min(existing["start_date"], day)
            existing["end_date"] = max(existing["end_date"], day)
    return list(rows.values())


def fetch_festivals() -> list[dict]:
    """화성시 축제만 뽑는다."""
    if not FESTIVAL_CSV.exists():
        print(f"  축제 CSV 없음: {FESTIVAL_CSV.name} (건너뜀)")
        return []

    text = FESTIVAL_CSV.read_bytes().decode("euc-kr")
    out = []
    for row in csv.DictReader(io.StringIO(text)):
        addr = (row.get("소재지도로명주소") or "") + (row.get("소재지지번주소") or "")
        if "화성시" not in addr:
            continue
        try:
            start = datetime.strptime(row["축제시작일자"], "%Y-%m-%d").date()
            end = datetime.strptime(row["축제종료일자"], "%Y-%m-%d").date()
        except (ValueError, KeyError):
            continue

        def num(key):
            try:
                return float(row[key])
            except (TypeError, ValueError, KeyError):
                return None

        out.append(
            {
                "name": row["축제명"].strip(),
                "event_type": "축제",
                "start_date": start,
                "end_date": end,
                "food_keyword": None,
                "location": (row.get("개최장소") or "").strip() or None,
                "lat": num("위도"),
                "lng": num("경도"),
                "radius_km": FESTIVAL_RADIUS_KM,
                "description": (row.get("축제내용") or "").strip() or None,
            }
        )
    return out


def run(years: tuple[int, ...] = (2026, 2027)) -> None:
    rows: list[dict] = []
    for year in years:
        got = fetch_days(year)
        print(f"  {year}년 절기·명절 {len(got)}건")
        rows += got

    festivals = dedupe_festivals(fetch_festivals())
    print(f"  화성시 축제 {len(festivals)}건")
    rows += festivals

    if not rows:
        print("가져온 게 없습니다.")
        return

    with SessionLocal() as db:
        stmt = insert(SeasonalEvent).values(rows)
        stmt = stmt.on_conflict_do_update(
            index_elements=["name", "start_date"],
            set_={
                "end_date": stmt.excluded.end_date,
                "food_keyword": stmt.excluded.food_keyword,
                "location": stmt.excluded.location,
                "lat": stmt.excluded.lat,
                "lng": stmt.excluded.lng,
                "radius_km": stmt.excluded.radius_km,
                "updated_at": func.now(),
            },
        )
        db.execute(stmt)
        db.commit()

    print(f"완료: {len(rows)}건 저장")


if __name__ == "__main__":
    run()
