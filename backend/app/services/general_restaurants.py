"""화성시 일반음식점 전체 수집 (지방행정 인허가데이터 · 전국일반음식점표준데이터).

코나페이 가맹점만 있으면 화성페이 필터가 사실상 의미가 없다(거의 다 켜져 있음).
이 스크립트가 "동네 음식점 전체"를 채워야 화성페이 필터가 실제로 걸러주는 역할을 한다.

원본: https://www.data.go.kr/data/15096283/standard.do (전국일반음식점표준데이터)
실제 다운로드는 LOCALDATA 파일 서버가 내려준다. 시도 단위로만 필터가 되어(경기도 전체,
~140MB) 화성시 행은 여기서 다시 걸러낸다.

좌표는 위경도가 아니라 Bessel 중부원점(EPSG:5174) TM 좌표라 pyproj로 변환한다.

실행: uv run python -m app.services.general_restaurants
"""

from __future__ import annotations

import csv
import io
import re

import httpx
from pyproj import Transformer
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from app.core.constants import GEOCODE_LOCALDATA, in_hwaseong
from app.core.http import request_with_retry
from app.database import SessionLocal
from app.models import Restaurant

CSV_URL = "https://file.localdata.go.kr/file/download/general_restaurants/info"
GYEONGGI_ORG_CODE = "6410000_ALL"

HEADERS = {
    "User-Agent": "Mozilla/5.0",
    "Referer": "https://file.localdata.go.kr/file/general_restaurants/info",
}

OPEN_STATUS = "영업/정상"

# 인허가 데이터 좌표정보(X)/(Y) 는 Bessel 중부원점(EPSG:5174). 위경도(EPSG:4326)로 바꾼다.
_TM_TO_WGS84 = Transformer.from_crs("EPSG:5174", "EPSG:4326", always_xy=True)

# 기획서 1단계 규칙 기반 정제 — mobeom.py 와 동일 기준.
_CORP = re.compile(r"\(주\)|\(유\)|\(사\)|㈜|㈐|주식회사|유한회사")
_NON_WORD = re.compile(r"[^0-9a-zA-Z가-힣]")
_BUNJI = re.compile(r"\d+(-\d+)?[,.]?")


def normalize_name(name: str) -> str:
    return _NON_WORD.sub("", _CORP.sub("", name or ""))


def road_key(address: str) -> str:
    """주소에서 도로명 토큰 하나만 뽑는다. mobeom.py 의 road_key 와 동일 규칙."""
    tokens = (address or "").split()
    for i, token in enumerate(tokens):
        if _BUNJI.fullmatch(token):
            return _NON_WORD.sub("", tokens[i - 1]) if i else ""
    return _NON_WORD.sub("", tokens[-1]) if tokens else ""


def same_road(a: str, b: str) -> bool:
    return bool(a) and a == b


def fetch_rows() -> list[dict]:
    with httpx.Client(follow_redirects=True) as client:
        res = request_with_retry(
            client, "GET", CSV_URL,
            params={"orgCode": GYEONGGI_ORG_CODE},
            headers=HEADERS,
            timeout=120.0,
        )
    res.raise_for_status()
    text = res.content.decode("euc-kr", errors="replace")
    return list(csv.DictReader(io.StringIO(text)))


def to_coords(row: dict) -> tuple[float, float] | None:
    try:
        x, y = float(row["좌표정보(X)"]), float(row["좌표정보(Y)"])
    except (KeyError, TypeError, ValueError):
        return None
    if not x or not y:
        return None
    lng, lat = _TM_TO_WGS84.transform(x, y)
    if not in_hwaseong(lat, lng):
        return None
    return lat, lng


def run() -> None:
    print("경기도 일반음식점 CSV 다운로드 중 (~140MB)...")
    rows = fetch_rows()
    hwaseong_rows = [
        r for r in rows
        if "화성시" in (r.get("지번주소") or "") + (r.get("도로명주소") or "")
        and (r.get("영업상태명") or "").strip() == OPEN_STATUS
    ]
    print(f"경기도 {len(rows):,}건 중 화성시 영업중 {len(hwaseong_rows):,}건")

    with SessionLocal() as db:
        # 코나페이·모범음식점 포함 기존 전체 행과 대조 — 겹치면 새로 안 만든다.
        existing = db.execute(select(Restaurant.id, Restaurant.name, Restaurant.address)).all()
        by_name: dict[str, list] = {}
        for rid, name, addr in existing:
            by_name.setdefault(normalize_name(name), []).append((rid, addr))
        print(f"기존 {len(existing):,}건과 대조")

        new_rows = []
        matched = skipped_no_coord = 0
        for row in hwaseong_rows:
            name = (row.get("사업장명") or "").strip()
            address = (row.get("도로명주소") or row.get("지번주소") or "").strip()
            if not name or not address:
                continue

            target_road = road_key(address)
            hit = any(
                same_road(road_key(other_addr), target_road)
                for _, other_addr in by_name.get(normalize_name(name), [])
            )
            if hit:
                matched += 1
                continue

            coords = to_coords(row)
            if coords is None:
                skipped_no_coord += 1
                continue
            lat, lng = coords

            new_rows.append({
                "name": name,
                "address": address,
                "zip_code": (row.get("도로명우편번호") or row.get("소재지우편번호") or "").strip() or None,
                "phone": (row.get("전화번호") or "").strip() or None,
                "lat": lat,
                "lng": lng,
                "geocode_status": GEOCODE_LOCALDATA,
                "category": "일반음식점",
                "biz_type_code": (row.get("업태구분명") or "").strip() or None,
            })
            # 같은 배치 안에서 같은 가게가 또 나와도 다시 안 잡히게 색인에 반영.
            by_name.setdefault(normalize_name(name), []).append((None, address))

        # (name, address) 유니크 인덱스 기준 — 배치 안 중복은 미리 줄인다.
        new_rows = list({(r["name"], r["address"]): r for r in new_rows}.values())

        inserted = 0
        if new_rows:
            stmt = insert(Restaurant).values(new_rows)
            stmt = stmt.on_conflict_do_nothing(
                index_elements=["name", "address"],
                index_where=Restaurant.__table__.c.konapay_seq.is_(None),
            )
            result = db.execute(stmt)
            db.commit()
            inserted = result.rowcount or 0

        print(
            f"완료: 기존과 병합(스킵) {matched:,}건, "
            f"좌표 없음/화성시 밖 제외 {skipped_no_coord:,}건, "
            f"신규 추가 {inserted:,}건"
        )


if __name__ == "__main__":
    run()
