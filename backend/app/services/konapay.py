"""코나페이(경기지역화폐) 화성시 가맹점 수집.

search.konacard.co.kr 매장 검색이 쓰는 내부 API를 그대로 호출한다.
주소가 도로명까지만 내려오고 좌표도 대부분 비어 있어서, 좌표는 geocoding 단계에서 채운다.

실행: uv run python -m app.services.konapay
"""

from __future__ import annotations

import html
import time

import httpx
from sqlalchemy import func
from sqlalchemy.dialects.postgresql import insert

from app.core.constants import GEOCODE_KONAPAY, GEOCODE_PENDING, in_hwaseong
from app.core.http import request_with_retry
from app.database import SessionLocal
from app.models import Restaurant

API_URL = "https://search.konacard.co.kr/api/v1/payable-merchants"
AFFILIATE_ID = "26"  # 화성시
AFFILIATE_NAME = "화성시"
PAGE_SIZE = 1000

HEADERS = {
    "Content-Type": "application/json; charset=UTF-8",
    "Referer": "https://search.konacard.co.kr/payable-merchants",
    "User-Agent": "Mozilla/5.0",
}


def fetch_page(client: httpx.Client, page_num: int) -> dict:
    payload = {
        "id": AFFILIATE_ID,
        "bizType": "",
        "merchantType": "HN",
        "pageNum": str(page_num),
        "pageSize": str(PAGE_SIZE),
        "affiliateName": AFFILIATE_NAME,
        "searchKey": "",
    }
    res = request_with_retry(
        client, "POST", API_URL, json=payload, headers=HEADERS, timeout=60
    )
    res.raise_for_status()
    body = res.json()
    if body["header"]["resultCode"] != 200:
        raise RuntimeError(f"API 오류: {body['header']}")
    return body["data"]


def to_row(m: dict) -> dict | None:
    addr = (m.get("addr") or "").strip()
    # id=26 으로 걸러도 인근 시군 데이터가 소량 섞여 들어온다.
    if "화성시" not in addr:
        return None

    # 0,0 이나 화성시 밖 좌표가 섞여 들어온다. 그대로 두면 기니만에 마커가 찍힌다.
    lat, lng = m.get("latitude"), m.get("longitude")
    if not (lat and lng and in_hwaseong(lat, lng)):
        lat = lng = None

    return {
        "name": html.unescape(m.get("simpleNm") or "").strip(),
        "address": addr,
        "zip_code": (m.get("zipCd") or "").strip() or None,
        "phone": (m.get("telNo") or "").strip() or None,
        "lat": lat,
        "lng": lng,
        "geocode_status": GEOCODE_KONAPAY if lat else GEOCODE_PENDING,
        "category": (m.get("bizTypeNm") or "").strip() or None,
        "biz_type_code": (m.get("bizType") or "").strip() or None,
        "is_konapay": True,
        "konapay_seq": m.get("seq"),
    }


def run() -> None:
    with httpx.Client() as client, SessionLocal() as db:
        first = fetch_page(client, 1)
        total = first["totalCount"]
        pages = (total + PAGE_SIZE - 1) // PAGE_SIZE
        print(f"화성시 가맹점 {total:,}건 / {pages}페이지")

        saved = skipped = 0
        for page in range(1, pages + 1):
            data = first if page == 1 else fetch_page(client, page)
            rows = [r for r in (to_row(m) for m in data["merchants"]) if r]
            skipped += len(data["merchants"]) - len(rows)

            # 한 배치에 같은 seq 가 두 번 들어오면 ON CONFLICT DO UPDATE 가
            # "cannot affect row a second time" 로 터진다. 배치 안에서 먼저 줄인다.
            rows = list({r["konapay_seq"]: r for r in rows}.values())

            if rows:
                stmt = insert(Restaurant).values(rows)
                # 월 1회 재수집을 염두에 두고 원본 키 기준 UPSERT.
                # is_mobeom 은 다른 파이프라인이 세우는 값이라 건드리지 않는다.
                stmt = stmt.on_conflict_do_update(
                    index_elements=["konapay_seq"],
                    set_={
                        "name": stmt.excluded.name,
                        "address": stmt.excluded.address,
                        "zip_code": stmt.excluded.zip_code,
                        "phone": stmt.excluded.phone,
                        "category": stmt.excluded.category,
                        "biz_type_code": stmt.excluded.biz_type_code,
                        "is_konapay": True,
                        # onupdate 는 ORM 경로에서만 도는데 여기선 SQL 을 직접 날린다.
                        "updated_at": func.now(),
                    },
                )
                db.execute(stmt)
                db.commit()
                saved += len(rows)

            print(f"  {page}/{pages} 저장 {saved:,}건", end="\r", flush=True)
            time.sleep(0.3)  # 남의 서버라 간격을 둔다

        print(f"\n완료: {saved:,}건 저장, {skipped:,}건 제외(화성시 외)")


if __name__ == "__main__":
    run()
