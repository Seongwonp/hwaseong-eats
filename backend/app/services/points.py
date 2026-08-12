"""포인트 적립·차감.

`user.points += 500` 처럼 읽고 쓰면 안 된다. 요청 두 개가 동시에 들어오면 둘 다
같은 값을 읽고 같은 값을 써서 한쪽 적립이 통째로 사라진다(lost update).
DB 에서 한 번에 증감시켜야 한다 — UPDATE users SET points = points + 500.
"""

from __future__ import annotations

from sqlalchemy import update
from sqlalchemy.orm import Session

from app.models import PointHistory, User


class InsufficientPointsError(RuntimeError):
    pass


def add_points(db: Session, user_id: int, delta: int, reason: str) -> None:
    """포인트를 원자적으로 증감하고 내역을 남긴다.

    delta 가 음수면 잔액이 모자랄 때 아무것도 하지 않고 예외를 올린다.
    잔액 확인과 차감을 한 문장에서 하므로 조회와 갱신 사이에 끼어들 틈이 없다.
    """
    stmt = update(User).where(User.id == user_id).values(points=User.points + delta)
    if delta < 0:
        stmt = stmt.where(User.points >= -delta)

    result = db.execute(stmt)
    if result.rowcount == 0:
        raise InsufficientPointsError(
            f"포인트가 부족하거나 사용자를 찾을 수 없습니다 (user_id={user_id}, delta={delta})"
        )

    db.add(PointHistory(user_id=user_id, delta=delta, reason=reason))
