"""좌표가 다른 업소와 겹치는 행을 카카오 장소 검색으로 재검증한다.

geocoding.py 는 키워드 검색이 실패하면 주소 검색으로 폴백하는데, 코나페이 주소엔
건물번호가 없어서 도로 중심점 한 곳에 수십 개가 쌓인다. 여기서는 폴백을 쓰지 않고
검색 결과의 상호명이 실제로 일치할 때만 좌표를 갱신한다.

실행: uv run python -m app.services.geocode_refine [건수]
"""

from __future__ import annotations

import os
import sys
import time
from difflib import SequenceMatcher

import httpx
from dotenv import load_dotenv
from sqlalchemy import text

from app.core.http import request_with_retry
from app.database import SessionLocal
from app.models import Restaurant
from app.core.constants import (
    FOOD_CATEGORIES,
    GEOCODE_UNVERIFIED,
    GEOCODE_VERIFIED,
    REFINE_GEOCODE_STATUSES,
    in_hwaseong,
)
from app.services.geocoding import KEYWORD_URL, AuthError

load_dotenv()

# 코나페이는 '(주) 마이선도니', 카카오는 '주식회사마이선도니' 처럼 법인 표기가 제각각이다.
# 정규화 규칙은 matching.py 한 곳에서만 정한다. norm 이름은 기존 호출부·테스트 호환용.
from app.services.matching import normalize_name as norm  # noqa: E402


def region_hint(address: str) -> str:
    """주소에서 구/읍/면 토큰을 뽑아 검색 범위를 좁힌다."""
    for token in (address or "").split():
        if token.endswith(("구", "읍", "면")):
            return token
    return "화성시"


def is_same_place(shop: str, place: str) -> bool:
    """'문어스토리해천' 과 '문어스토리해천 본점' 처럼 지점명이 붙은 경우까지 같은 곳으로 본다."""
    a, b = norm(shop), norm(place)
    if len(a) < 2 or len(b) < 2:
        return False
    if a in b or b in a:
        return True
    return SequenceMatcher(None, a, b).ratio() >= 0.7


def find_place(client: httpx.Client, name: str, address: str) -> tuple[float, float] | None:
    """상호명이 일치하는 장소만 채택한다. 못 찾으면 None (폴백 없음)."""
    for query in (f"{name} {region_hint(address)}", f"{name} 화성시"):
        res = request_with_retry(
            client, "GET", KEYWORD_URL, params={"query": query, "size": 15}
        )
        if res.status_code in (401, 403):
            raise AuthError(f"카카오 API 인증 실패({res.status_code}): {res.text}")
        if res.status_code != 200:
            continue

        for doc in res.json().get("documents", []):
            lat, lng = float(doc["y"]), float(doc["x"])
            if in_hwaseong(lat, lng) and is_same_place(name, doc["place_name"]):
                return lat, lng
    return None


# 좌표 출처가 확실한 행은 대상에서 뺀다(:sts).
#   sangga·localdata  업소 단위 실좌표다. 카카오가 상호를 못 찾으면 unverified 로
#                     내려가 지도에서 사라진다 — 검증된 좌표를 잃는 손해다.
#   verified          이미 이 스크립트가 확인한 행이다.
#   duplicate         다른 출처로 이미 들어온 중복이라 숨겨둔 행이다. 여기서 손대면
#                     verified 로 덮여 같은 가게가 지도에 두 번 뜬다.
# 같은 건물에 입점한 업소들이 좌표를 공유하는 건 정상이라, 좌표 중복만으로는
# 오류라고 볼 수 없다는 점도 같은 이유다.
TARGET_SQL = text(
    """
    WITH dup AS (
        SELECT lat, lng FROM restaurants
        WHERE lat IS NOT NULL GROUP BY lat, lng HAVING count(*) > 1
    )
    SELECT r.id FROM restaurants r
    JOIN dup d ON r.lat = d.lat AND r.lng = d.lng
    WHERE r.category = ANY(:cats)
      AND r.geocode_status = ANY(:sts)
    ORDER BY r.id
    """
)


def run(limit: int | None = None) -> None:
    key = os.getenv("KAKAO_API_KEY")
    if not key:
        raise RuntimeError("KAKAO_API_KEY 가 없습니다.")

    with SessionLocal() as db:
        ids = [
            r[0]
            for r in db.execute(
                TARGET_SQL,
                {
                    "cats": list(FOOD_CATEGORIES),
                    "sts": list(REFINE_GEOCODE_STATUSES),
                },
            )
        ]
        if limit:
            ids = ids[:limit]
        print(f"겹치는 좌표 대상 {len(ids):,}건")

        moved = same = unverified = 0
        with httpx.Client(headers={"Authorization": f"KakaoAK {key}"}, timeout=15) as client:
            for i, rid in enumerate(ids, 1):
                r = db.get(Restaurant, rid)
                try:
                    hit = find_place(client, r.name, r.address)
                except AuthError as e:
                    db.commit()
                    print(f"\n중단: {e}")
                    return
                except httpx.HTTPError:
                    hit = None

                if hit is None:
                    # 상호명이 확인되는 장소가 없다. 기존 좌표는 두되 신뢰도만 낮춰 표시한다.
                    r.geocode_status = GEOCODE_UNVERIFIED
                    unverified += 1
                elif (round(hit[0], 6), round(hit[1], 6)) == (round(r.lat, 6), round(r.lng, 6)):
                    r.geocode_status = GEOCODE_VERIFIED
                    same += 1
                else:
                    r.lat, r.lng = hit
                    r.geocode_status = GEOCODE_VERIFIED
                    moved += 1

                if i % 100 == 0:
                    db.commit()
                    print(f"  {i:,}/{len(ids):,}  이동 {moved:,} 유지 {same:,} 미확인 {unverified:,}",
                          end="\r", flush=True)
                time.sleep(0.05)

        db.commit()

    print(f"\n완료: 좌표 이동 {moved:,} / 그대로 {same:,} / 미확인 {unverified:,}")


if __name__ == "__main__":
    run(limit=int(sys.argv[1]) if len(sys.argv) > 1 else None)
