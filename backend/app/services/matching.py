"""상호명·주소 매칭 규칙.

코나페이·모범음식점·상가정보·일반음식점 인허가 네 소스가 같은 가게를 서로 다른 표기로
담고 있어서, 어느 쪽이든 같은 규칙으로 대조해야 한다. 규칙이 파이프라인마다 갈리면
한쪽은 같은 가게를 두 번 넣고 다른 쪽은 다른 가게를 하나로 합친다. 실제로 그랬다 —
sangga 는 도로명 부분일치를 허용해서 '중앙로' 가 '화산중앙로' 에 걸렸고,
general_restaurants 는 완전일치만 봐서 같은 가게를 105건 중복으로 넣었다.

기획서 1단계 규칙 기반 정제에 해당한다.
"""

from __future__ import annotations

import re

# 법인 표기는 소스마다 제각각이다.
#   코나페이 '(주) 마이선도니' · 카카오 '주식회사마이선도니' · 인허가 '㈜마이선도니'
_CORP = re.compile(
    r"\(주\)|\(유\)|\(사\)|㈜|㈐|주식회사|유한회사|유한책임회사"
)
_NON_WORD = re.compile(r"[^0-9a-zA-Z가-힣]")

# 건물번호. '23-12,' '1079-12' '183' 처럼 뒤에 쉼표·마침표가 붙어 오는 경우까지 본다.
_BUNJI = re.compile(r"\d+(-\d+)?[,.]?")


def normalize_name(name: str | None) -> str:
    """법인 표기와 기호를 걷어낸 상호명."""
    return _NON_WORD.sub("", _CORP.sub("", name or ""))


def road_key(address: str | None) -> str:
    """주소에서 도로명 토큰 하나만 뽑는다.

    건물번호 뒤에 층·건물명이 더 붙는 주소가 많아서 마지막 토큰을 쓰면 엉뚱한 걸 잡는다.
        '…동탄구 큰재봉길 23-12, 1층 (동탄구 석우동, 펠리스타)' → '펠리스타'
    첫 건물번호 직전 토큰이 도로명이다. 코나페이 주소는 건물번호가 아예 없어서
    그때는 마지막 토큰이 도로명이다.
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


def same_place(name_a: str | None, addr_a: str | None,
               name_b: str | None, addr_b: str | None) -> bool:
    """상호명이 같고 도로명까지 겹치면 같은 가게로 본다."""
    return (
        normalize_name(name_a) == normalize_name(name_b)
        and same_road(road_key(addr_a), road_key(addr_b))
    )
