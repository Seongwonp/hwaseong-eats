"""포인트 적립·차감.

`user.points += 500` 처럼 읽고 쓰면 안 된다. 요청 두 개가 동시에 들어오면 둘 다
같은 값을 읽고 같은 값을 써서 한쪽 적립이 통째로 사라진다(lost update).
DB 에서 한 번에 증감시켜야 한다 — UPDATE users SET points = points + 500.
"""

from __future__ import annotations

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.models import PointHistory, User


class InsufficientPointsError(RuntimeError):
    pass


class UserNotFoundError(RuntimeError):
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


def revoke_points(db: Session, user_id: int, amount: int, reason: str) -> int:
    """적립분을 되돌린다. 잔액이 모자라면 남은 만큼만 회수하고 실제 회수액을 돌려준다.

    add_points 로 회수하면 안 된다. 이미 화성페이로 전환해 잔액이 0 이면 예외가 올라와서
    식사평 삭제 자체가 실패한다(500). 적립분을 다 못 걷는 건 정상 상황이다 —
    사용자가 이미 가져간 것이고, 유니크 제약이 같은 가게 재작성을 막고 있어서
    그걸로 포인트를 다시 만들 수는 없다.

    잔액을 잠근 뒤 계산하므로 동시 요청에도 마이너스로 내려가지 않는다.
    """
    if amount <= 0:
        return 0

    balance = db.scalar(
        select(User.points).where(User.id == user_id).with_for_update()
    )
    if balance is None:
        raise UserNotFoundError(f"사용자를 찾을 수 없습니다 (user_id={user_id})")

    taken = min(amount, balance)
    if taken:
        db.execute(
            update(User).where(User.id == user_id).values(points=User.points - taken)
        )
        db.add(PointHistory(user_id=user_id, delta=-taken, reason=reason))
    return taken
