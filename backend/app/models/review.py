from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Index, SmallInteger, Text, func
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Review(Base):
    """식사평.

    리뷰 방향(태그 항목·별점 도입 여부·글 허용 여부)이 아직 확정 전이라
    자리만 잡아둔 상태다. rating / comment 는 의도적으로 nullable.
    """

    __tablename__ = "reviews"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)

    restaurant_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("restaurants.id", ondelete="CASCADE"), nullable=False
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # 정해진 몇 가지 중 고르는 방식. 항목이 확정되면 코드 레벨에서 검증한다.
    tags: Mapped[list[str] | None] = mapped_column(ARRAY(Text))
    rating: Mapped[int | None] = mapped_column(SmallInteger)
    comment: Mapped[str | None] = mapped_column(Text)

    is_receipt_verified: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    receipt_image_url: Mapped[str | None] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        Index("ix_reviews_restaurant_id", "restaurant_id"),
        Index("ix_reviews_user_id", "user_id"),
    )
