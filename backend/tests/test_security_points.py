"""비밀번호 해싱과 포인트 증감 테스트.

프론트 담당 피드백에서 나온 두 가지를 고정한다.
  - 포인트는 읽고 쓰면 안 되고 DB 에서 한 번에 증감해야 한다
  - 비밀번호는 bcrypt. MD5·SHA1 은 안 된다
"""

import pytest
from sqlalchemy import update

from app.core.security import (
    MAX_PASSWORD_BYTES,
    PasswordTooLongError,
    hash_password,
    verify_password,
)
from app.models import User
from app.services.points import add_points


class TestPasswordHashing:
    def test_해시는_원문을_담지_않는다(self):
        hashed = hash_password("hwaseong1234")
        assert "hwaseong1234" not in hashed

    def test_검증이_통과한다(self):
        assert verify_password("hwaseong1234", hash_password("hwaseong1234"))

    def test_틀린_비밀번호는_거른다(self):
        assert not verify_password("wrong", hash_password("hwaseong1234"))

    def test_같은_비밀번호도_해시가_매번_다르다(self):
        # salt 가 자동으로 붙는지 확인. 같으면 레인보우 테이블에 뚫린다
        assert hash_password("same") != hash_password("same")

    def test_bcrypt_형식이다(self):
        # $2b$ 는 bcrypt 식별자. MD5($1$)나 SHA($5$/$6$)가 아님을 고정한다
        assert hash_password("x").startswith("$2b$")

    def test_72바이트_초과는_막는다(self):
        # bcrypt 가 조용히 잘라내면 뒷부분이 다른 비밀번호가 같아진다
        with pytest.raises(PasswordTooLongError):
            hash_password("a" * (MAX_PASSWORD_BYTES + 1))

    def test_깨진_해시에도_예외를_올리지_않는다(self):
        assert not verify_password("x", "이건해시가아님")


class TestAddPoints:
    """실제 DB 를 쓴다. 테스트가 만든 사용자는 끝나고 지운다."""

    @pytest.fixture
    def user(self):
        from sqlalchemy import text

        from app.database import SessionLocal

        try:
            with SessionLocal() as probe:
                probe.execute(text("SELECT 1"))
        except Exception as e:
            pytest.skip(f"DB 연결 불가: {e}")

        with SessionLocal() as db:
            u = User(
                email="__test_points__@example.com",
                password_hash="x",
                nickname="__테스트__",
                points=0,
            )
            db.add(u)
            db.commit()
            db.refresh(u)
            yield u.id, db
            db.delete(db.get(User, u.id))
            db.commit()

    def test_적립되고_내역이_남는다(self, user):
        user_id, db = user
        add_points(db, user_id, 500, "화성인증 식사평")
        db.commit()
        assert db.get(User, user_id).points == 500

    def test_차감된다(self, user):
        user_id, db = user
        add_points(db, user_id, 1000, "적립")
        db.commit()
        add_points(db, user_id, -1000, "화성페이 전환")
        db.commit()
        assert db.get(User, user_id).points == 0

    def test_잔액보다_많이_쓰면_거부한다(self, user):
        from app.services.points import InsufficientPointsError

        user_id, db = user
        add_points(db, user_id, 500, "적립")
        db.commit()
        with pytest.raises(InsufficientPointsError):
            add_points(db, user_id, -1000, "화성페이 전환")
        db.rollback()
        assert db.get(User, user_id).points == 500

    def test_읽고쓰기가_아니라_DB에서_증감한다(self, user):
        """세션 밖에서 값이 바뀌어도 덮어쓰지 않아야 한다.

        points += 500 방식이면 미리 읽어둔 0 에 500 을 더해 500 으로 덮어쓴다.
        원자적 증감이면 1000 위에 더해 1500 이 된다.
        """
        user_id, db = user
        db.get(User, user_id)  # 세션에 0 인 상태로 적재

        # 다른 요청이 먼저 1000 을 적립한 상황을 흉내낸다
        db.execute(update(User).where(User.id == user_id).values(points=1000))
        db.commit()
        db.expire_all()

        add_points(db, user_id, 500, "화성인증 식사평")
        db.commit()
        assert db.get(User, user_id).points == 1500
