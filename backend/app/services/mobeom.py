"""화성시 모범음식점 수집 (공공데이터포털 15153027).

코나페이 데이터와 겹치는 가게는 새로 만들지 않고 기존 행에 is_mobeom 만 세운다.
같은 가게가 두 행으로 갈리면 "화성페이 + 모범음식점" 교집합 필터가 깨지기 때문이다.

실행: uv run python -m app.services.mobeom
"""

from __future__ import annotations

import csv
import io
import os

import httpx
from sqlalchemy import select

from app.core.constants import GEOCODE_PENDING
from app.database import SessionLocal
from app.models import Restaurant

# atchFileId 가 하드코딩이라 원본이 갱신되면 조용히 404 가 된다. 환경변수로 덮어쓸 수 있게 둔다.
CSV_URL = os.getenv(
    "MOBEOM_CSV_URL",
    "https://www.data.go.kr/cmm/cmm/fileDownload.do"
    "?atchFileId=FILE_000000003595667&fileDetailSn=1",
)

# 이 컬럼이 없으면 우리가 아는 그 파일이 아니다.
REQUIRED_COLUMNS = ("음식점명", "주소")

# 매칭 규칙은 네 소스가 같은 걸 써야 한다. app/services/matching.py 참고.
# 아래 재노출은 기존 호출부·테스트 호환용이다.
from app.services.matching import (  # noqa: E402
    normalize_name,
    road_key,
    same_road,
)


class SourceChangedError(RuntimeError):
    """받아온 파일이 기대한 형식이 아니다. 0건으로 조용히 끝나는 것보다 낫다."""


def fetch_rows() -> list[dict]:
    res = httpx.get(CSV_URL, timeout=60, follow_redirects=True)
    if res.status_code != 200:
        raise SourceChangedError(
            f"모범음식점 CSV 내려받기 실패 {res.status_code}. 공공데이터포털에서 새 "
            f"atchFileId 를 확인하고 MOBEOM_CSV_URL 로 덮어쓰세요."
        )
    text = res.content.decode("euc-kr", errors="replace")
    reader = csv.DictReader(io.StringIO(text))
    missing = [c for c in REQUIRED_COLUMNS if c not in (reader.fieldnames or [])]
    if missing:
        raise SourceChangedError(
            f"CSV 컬럼이 바뀌었습니다. 없는 컬럼: {missing}. "
            f"받은 컬럼: {(reader.fieldnames or [])[:8]}…"
        )
    return list(reader)


def run() -> None:
    rows = fetch_rows()
    print(f"모범음식점 {len(rows)}건 수신")

    with SessionLocal() as db:
        # 코나페이 행만 보면, 지난 실행에서 새로 넣은 모범음식점 단독 행을 못 찾아
        # 재실행할 때마다 같은 가게가 다시 들어간다. 전체를 대상으로 대조한다.
        existing = db.execute(
            select(Restaurant.id, Restaurant.name, Restaurant.address)
        ).all()
        by_name: dict[str, list] = {}
        for rid, name, addr in existing:
            by_name.setdefault(normalize_name(name), []).append((rid, addr))
        print(f"기존 {len(existing):,}건과 대조")

        matched = inserted = 0
        for row in rows:
            name = (row.get("음식점명") or "").strip()
            address = (row.get("주소") or "").strip()
            phone = (row.get("전화번호") or "").strip() or None
            if not name or not address:
                continue

            # 상호명이 같고 도로명까지 겹치면 동일 가게로 본다.
            hit = None
            target_road = road_key(address)
            for rid, other_addr in by_name.get(normalize_name(name), []):
                if same_road(road_key(other_addr), target_road):
                    hit = rid
                    break

            if hit:
                db.get(Restaurant, hit).is_mobeom = True
                matched += 1
            else:
                new = Restaurant(
                    name=name,
                    address=address,
                    phone=phone,
                    is_mobeom=True,
                    geocode_status=GEOCODE_PENDING,
                    category="모범음식점",
                )
                db.add(new)
                db.flush()
                # 같은 CSV 안에 중복이 있어도 두 번 들어가지 않도록 색인에 바로 반영한다.
                by_name.setdefault(normalize_name(name), []).append((new.id, address))
                inserted += 1

        db.commit()
        print(f"완료: 기존 행에 병합 {matched}건, 신규 추가 {inserted}건")


if __name__ == "__main__":
    run()
