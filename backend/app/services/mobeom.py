"""화성시 모범음식점 수집 (공공데이터포털 15153027).

코나페이 데이터와 겹치는 가게는 새로 만들지 않고 기존 행에 is_mobeom 만 세운다.
같은 가게가 두 행으로 갈리면 "화성페이 + 모범음식점" 교집합 필터가 깨지기 때문이다.

실행: uv run python -m app.services.mobeom
"""

from __future__ import annotations

import csv
import io
import re

import httpx
from sqlalchemy import select

from app.core.constants import GEOCODE_PENDING
from app.database import SessionLocal
from app.models import Restaurant

CSV_URL = (
    "https://www.data.go.kr/cmm/cmm/fileDownload.do"
    "?atchFileId=FILE_000000003595667&fileDetailSn=1"
)

# 기획서 1단계 규칙 기반 정제 — 법인 표기·공백·괄호를 걷어낸 뒤 비교한다.
_CORP = re.compile(r"\(주\)|\(유\)|\(사\)|㈜|㈐|주식회사|유한회사")
_NON_WORD = re.compile(r"[^0-9a-zA-Z가-힣]")


def normalize_name(name: str) -> str:
    return _NON_WORD.sub("", _CORP.sub("", name or ""))


_BUNJI = re.compile(r"\d+(-\d+)?[,.]?")


def road_key(address: str) -> str:
    """주소에서 도로명 토큰 하나만 뽑는다.

    모범음식점 주소는 건물번호 뒤에 층·건물명이 더 붙는다.
        '…동탄구 큰재봉길 23-12, 1층 (동탄구 석우동, 펠리스타)'
    그래서 마지막 토큰을 쓰면 '펠리스타)' 가 잡힌다. 첫 숫자 토큰 직전이 도로명이다.
    코나페이 주소는 건물번호가 아예 없어서 그때는 마지막 토큰이 도로명이다.
    """
    tokens = (address or "").split()
    for i, token in enumerate(tokens):
        if _BUNJI.fullmatch(token):
            return _NON_WORD.sub("", tokens[i - 1]) if i else ""
    return _NON_WORD.sub("", tokens[-1]) if tokens else ""


def same_road(a: str, b: str) -> bool:
    """도로명이 같은지 본다.

    부분일치를 쓰면 '중앙로' 가 '화산중앙로' 에 걸려 다른 가게를 같은 가게로 본다.
    완전일치만 인정한다.
    """
    return bool(a) and a == b


def fetch_rows() -> list[dict]:
    res = httpx.get(CSV_URL, timeout=60, follow_redirects=True)
    res.raise_for_status()
    text = res.content.decode("euc-kr")
    return list(csv.DictReader(io.StringIO(text)))


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
