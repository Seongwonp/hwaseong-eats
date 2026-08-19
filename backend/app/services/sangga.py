"""소상공인시장진흥공단 상가(상권)정보로 좌표를 채운다.

국세청·카드사 기반이라 카카오·네이버에 등록하지 않은 소상공인도 들어 있고,
경도·위도를 이미 갖고 있어서 지오코딩 없이 좌표를 얻을 수 있다.
카카오에서 못 찾은 업소의 절반 이상이 여기서 해결된다.

원본: https://www.data.go.kr/data/15083033/fileData.do (시도별 CSV, zip)

실행: uv run python -m app.services.sangga
"""

from __future__ import annotations

import collections
import csv
import io
import zipfile
from pathlib import Path

from sqlalchemy import text

from app.core.constants import GEOCODE_SANGGA, REFILL_GEOCODE_STATUSES
from app.database import SessionLocal

# 매칭 규칙은 네 소스가 같은 걸 써야 한다. app/services/matching.py 참고.
# norm / road_of 이름은 기존 호출부·테스트 호환용으로 남긴다.
from app.services.matching import normalize_name as norm
from app.services.matching import road_key as road_of
from app.services.matching import same_road

DATA_DIR = Path(__file__).resolve().parents[2] / "data"
EXTRACTED = DATA_DIR / "hwaseong_sangga.csv"


def extract_hwaseong(zip_path: Path) -> Path:
    """전국 zip 에서 경기 CSV 를 스트리밍으로 읽어 화성시 행만 뽑아낸다.

    경기 파일 하나가 369MB라 통째로 풀지 않는다.
    """
    with zipfile.ZipFile(zip_path) as z:
        member = next(
            i for i in z.infolist() if "경기" in i.filename.encode("cp437").decode("euc-kr")
        )
        with z.open(member) as fh, open(EXTRACTED, "w", encoding="utf-8", newline="") as out:
            reader = csv.reader(io.TextIOWrapper(fh, encoding="utf-8", newline=""))
            cols = next(reader)
            writer = csv.writer(out)
            writer.writerow(cols)
            sgg = cols.index("시군구명")
            kept = 0
            for row in reader:
                if "화성시" in row[sgg]:
                    writer.writerow(row)
                    kept += 1
    print(f"화성시 {kept:,}건 추출 → {EXTRACTED.name}")
    return EXTRACTED


def build_index(csv_path: Path) -> dict[str, list[tuple[str, float, float]]]:
    """정규화한 상호명 → [(도로명, 위도, 경도)] 색인."""
    idx: dict[str, list] = collections.defaultdict(list)
    with open(csv_path, encoding="utf-8") as f:
        for row in csv.DictReader(f):
            try:
                lat, lng = float(row["위도"]), float(row["경도"])
            except (TypeError, ValueError):
                continue
            road = road_of(row["도로명"])
            # 코나페이는 '교촌치킨 동탄역점' 처럼 지점명을 붙여 쓰는 경우가 많다.
            for key in {norm(row["상호명"]), norm(row["상호명"] + row["지점명"])}:
                if key:
                    idx[key].append((road, lat, lng))
    return idx


def lookup(idx: dict, name: str, address: str) -> tuple[float, float] | None:
    """상호명이 같고 도로명까지 완전히 같을 때만 좌표를 가져온다.

    예전에는 부분일치('중앙로' in '화산중앙로')도 허용했는데, 그러면 다른 가게 좌표를
    가져온다. mobeom.py 가 같은 이유로 완전일치만 인정하는데 여기만 규칙이 달랐다.
    """
    road = road_of(address)
    for cand_road, lat, lng in idx.get(norm(name), []):
        if same_road(cand_road, road):
            return lat, lng
    return None


def run() -> None:
    if not EXTRACTED.exists():
        zips = sorted(DATA_DIR.glob("*.zip"))
        if not zips:
            raise RuntimeError(f"{DATA_DIR} 에 상가정보 zip 이 없습니다.")
        extract_hwaseong(zips[0])

    idx = build_index(EXTRACTED)
    print(f"상가정보 색인 {len(idx):,}개 상호")

    with SessionLocal() as db:
        rows = db.execute(
            text(
                "SELECT id, name, address FROM restaurants "
                "WHERE geocode_status = ANY(:st)"
            ),
            {"st": list(REFILL_GEOCODE_STATUSES)},
        ).all()
        print(f"대상 {len(rows):,}건")

        updates = []
        for rid, name, address in rows:
            hit = lookup(idx, name, address)
            if hit:
                updates.append(
                    {"id": rid, "lat": hit[0], "lng": hit[1], "st": GEOCODE_SANGGA}
                )

        matched = len(updates)
        stmt = text(
            "UPDATE restaurants SET lat=:lat, lng=:lng, "
            "geocode_status=:st, updated_at=now() WHERE id=:id"
        )
        # 1건씩 왕복하면 1만 6천 번을 오간다. 묶어서 보낸다.
        for i in range(0, matched, 2000):
            db.execute(stmt, updates[i : i + 2000])
            db.commit()
            print(f"  {min(i + 2000, matched):,}/{matched:,} 갱신", end="\r", flush=True)

    print(f"\n완료: {matched:,}건 좌표 갱신 (미매칭 {len(rows) - matched:,}건)")


if __name__ == "__main__":
    run()
