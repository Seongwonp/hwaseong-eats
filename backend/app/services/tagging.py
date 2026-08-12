"""목적별 태그를 규칙으로 붙인다.

⚠️ 여기서 붙이는 태그는 **추정이지 검증된 사실이 아니다.**

기획서 p.5 는 `#카공픽 #10대픽 #혼밥 #가성비` 를 보조기능으로 두는데, 이 정보는
공공데이터에 없다. 원래는 식사평이 쌓이면서 채워져야 할 값이다. 다만 프론트 지도에
필터칩이 이미 붙어 있어서, 지금 누르면 빈 화면이 나온다. 데모가 돌아가도록
상호명·업종에서 뽑아낼 수 있는 만큼만 규칙으로 채운다.

식사평 기반으로 바뀌면 이 모듈은 버린다.

실행: uv run python -m app.services.tagging
"""

from __future__ import annotations

import re

from sqlalchemy import select, update

from app.core.constants import FOOD_CATEGORIES
from app.database import SessionLocal
from app.models import Restaurant

TAG_STUDY = "카공픽"
TAG_TEEN = "10대픽"
TAG_SOLO = "혼밥"
TAG_VALUE = "가성비"

# 좌석이 넓어 오래 앉아 있기 좋은 프랜차이즈. 개인 카페는 매장마다 편차가 커서 뺀다.
_CAFE_FRANCHISE = re.compile(
    r"스타벅스|투썸|할리스|이디야|메가커피|메가엠지씨|컴포즈|빽다방|파스쿠찌|커피빈|"
    r"엔제리너스|탐앤탐스|공차|더벤티"
)
_STUDY = re.compile(r"스터디")

# 10대가 주로 가는 곳. 분식·떡볶이·패스트푸드.
_TEEN = re.compile(r"떡볶이|분식|햄버거|피자|버거")

# 1인분을 시켜 혼자 먹기 자연스러운 업종.
_SOLO = re.compile(r"국밥|김밥|라멘|우동|국수|덮밥|돈까스|돈가스|칼국수|해장국")

# 값이 싸다고 볼 만한 신호.
_VALUE = re.compile(r"뷔페|백반|기사식당|가정식")


def tags_for(name: str, category: str | None, is_mobeom: bool) -> list[str]:
    """상호명과 업종에서 붙일 수 있는 태그를 고른다."""
    name = name or ""
    tags: list[str] = []

    if _STUDY.search(name) or (category == "커피전문점" and _CAFE_FRANCHISE.search(name)):
        tags.append(TAG_STUDY)

    if _TEEN.search(name) or category == "치킨전문점":
        tags.append(TAG_TEEN)

    if _SOLO.search(name):
        tags.append(TAG_SOLO)

    # 모범음식점은 화성시가 위생·가격을 보고 지정한 곳이라 가성비 신호로 본다.
    if _VALUE.search(name) or is_mobeom:
        tags.append(TAG_VALUE)

    return tags


def run() -> None:
    with SessionLocal() as db:
        rows = db.execute(
            select(Restaurant.id, Restaurant.name, Restaurant.category, Restaurant.is_mobeom)
            .where(Restaurant.category.in_(FOOD_CATEGORIES))
        ).all()
        print(f"음식 업종 {len(rows):,}건 대상")

        updates = []
        for rid, name, category, is_mobeom in rows:
            tags = tags_for(name, category, is_mobeom)
            if tags:
                updates.append({"id": rid, "tags": tags})

        # 규칙이 바뀌면 결과도 바뀌므로 매번 전부 지우고 다시 계산한다.
        db.execute(update(Restaurant).values(tags=None))

        # 기본키 기준 대량 UPDATE. 딕셔너리에 id 가 들어 있으면 SQLAlchemy 가 묶어 보낸다.
        for i in range(0, len(updates), 2000):
            db.execute(update(Restaurant), updates[i : i + 2000])
        db.commit()

        print(f"완료: {len(updates):,}건에 태그 부여")
        for tag in (TAG_STUDY, TAG_TEEN, TAG_SOLO, TAG_VALUE):
            n = sum(1 for u in updates if tag in u["tags"])
            print(f"  #{tag}: {n:,}건")


if __name__ == "__main__":
    run()
