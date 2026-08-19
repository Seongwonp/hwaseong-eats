from datetime import datetime

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
