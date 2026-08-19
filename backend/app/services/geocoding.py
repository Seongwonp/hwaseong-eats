"""주소 → 좌표 변환 (카카오 로컬 API).

코나페이 주소는 도로명까지만 내려오고 건물번호가 없다. 주소 검색만 쓰면
같은 도로의 가맹점이 전부 한 점에 겹치므로, 상호명을 얹은 키워드 검색을 먼저 시도한다.

실행: uv run python -m app.services.geocoding [건수]
"""

from __future__ import annotations

import os
import sys
import time

import httpx
from dotenv import load_dotenv
from sqlalchemy import select

from app.core.constants import (
    FOOD_CATEGORIES,
    GEOCODE_FAILED,
    GEOCODE_OK,
    GEOCODE_PENDING,
    in_hwaseong,
)
from app.core.http import request_with_retry
from app.database import SessionLocal
from app.models import Restaurant

load_dotenv()

KEYWORD_URL = "https://dapi.kakao.com/v2/local/search/keyword.json"
ADDRESS_URL = "https://dapi.kakao.com/v2/local/search/address.json"



def _pick(docs: list[dict]) -> tuple[float, float] | None:
    for d in docs:
        lat, lng = float(d["y"]), float(d["x"])
        if in_hwaseong(lat, lng):
            return lat, lng
    return None


class AuthError(RuntimeError):
    """키가 막혀 있는 상태. 이걸 '좌표 없음'으로 처리하면 전 건이 failed 로 오염된다."""


def _search(client: httpx.Client, url: str, query: str) -> list[dict]:
    res = request_with_retry(client, "GET", url, params={"query": query, "size": 5})
    if res.status_code in (401, 403):
        raise AuthError(f"카카오 API 인증 실패({res.status_code}): {res.text}")
    if res.status_code != 200:
        return []
    return res.json().get("documents", [])


def strip_sido(address: str) -> str:
    """맨 앞 시도명만 떼어낸다.

    무조건 첫 토큰을 버리면 형식이 다른 주소에서 의미 있는 토큰이 날아간다.
    """
    tokens = (address or "").split()
    if tokens and tokens[0] in ("경기", "경기도"):
        tokens = tokens[1:]
    return " ".join(tokens)


def lookup(client: httpx.Client, name: str, address: str) -> tuple[float, float] | None:
    """키워드 검색 → 실패 시 주소 검색 순으로 좌표를 찾는다."""
    road = strip_sido(address)

    if hit := _pick(_search(client, KEYWORD_URL, f"{name} {road}")):
        return hit
    if hit := _pick(_search(client, ADDRESS_URL, address)):
        return hit
    return None


def run(limit: int | None = None, food_only: bool = True) -> None:
    key = os.getenv("KAKAO_API_KEY")
    if not key:
        raise RuntimeError("KAKAO_API_KEY 가 없습니다. backend/.env 를 확인하세요.")

    with SessionLocal() as db:
        stmt = select(Restaurant).where(Restaurant.geocode_status == GEOCODE_PENDING)
        if food_only:
            stmt = stmt.where(Restaurant.category.in_(FOOD_CATEGORIES))
        if limit:
            stmt = stmt.limit(limit)
        targets = db.scalars(stmt).all()

        print(f"대상 {len(targets):,}건")
        ok = failed = 0

        with httpx.Client(
            headers={"Authorization": f"KakaoAK {key}"}, timeout=15
        ) as client:
            for i, r in enumerate(targets, 1):
                try:
                    hit = lookup(client, r.name, r.address)
                except AuthError as e:
                    db.commit()
                    print(f"\n중단: {e}")
                    print("콘솔에서 [제품 설정] > [카카오맵] 사용 설정을 켜세요.")
                    return
                except httpx.HTTPError:
                    hit = None

                if hit:
                    r.lat, r.lng = hit
                    r.geocode_status = GEOCODE_OK
                    ok += 1
                else:
                    r.geocode_status = GEOCODE_FAILED
                    failed += 1

                if i % 100 == 0:
                    db.commit()
                    print(f"  {i:,}/{len(targets):,}  성공 {ok:,} 실패 {failed:,}", end="\r", flush=True)
                time.sleep(0.05)

        db.commit()

    rate = ok / (ok + failed) * 100 if ok + failed else 0
    print(f"\n완료: 성공 {ok:,} / 실패 {failed:,} (성공률 {rate:.1f}%)")


if __name__ == "__main__":
    run(limit=int(sys.argv[1]) if len(sys.argv) > 1 else None)
