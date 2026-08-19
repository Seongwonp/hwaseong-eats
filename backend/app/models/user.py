from datetime import datetime, timezone

from sqlalchemy import BigInteger, Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class User(Base):
    """자체 계정 + 카카오 소셜 계정 회원."""

    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)

    # 카카오 로그인 사용자는 kakao_id만 있고 email/password_hash는 None
    kakao_id: Mapped[int | None] = mapped_column(BigInteger, unique=True, nullable=True)
    email: Mapped[str | None] = mapped_column(String(255), unique=True, nullable=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    nickname: Mapped[str] = mapped_column(String(20), unique=True, nullable=False)

    # 화성주민 인증은 6개월 유효라 만료 시점을 따로 들고 있는다.
    is_resident_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    resident_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    resident_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    points: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    @property
    def is_resident_active(self) -> bool:
        """주민인증이 지금도 살아 있는지.

        is_resident_verified 컬럼만 보면 안 된다. 인증은 6개월 유효인데 만료 시 컬럼을
        되돌리는 배치가 없어서, 만료된 사용자도 계속 True 로 보인다. 응답과 화성인증
        판정은 이 값을 쓴다.
        """
        if not self.is_resident_verified:
            return False
        expires = self.resident_expires_at
        return expires is None or expires >= datetime.now(timezone.utc)
