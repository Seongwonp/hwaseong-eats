from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    SmallInteger,
    Text,
    UniqueConstraint,
    desc,
    func,
)
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

    # 작성 시점에 실제로 적립한 금액. 삭제할 때 이 값만큼만 회수한다.
    # 삭제 시점에 조건을 다시 따지면, 작성 후 인증 상태가 바뀐 경우 적립한 적 없는
    # 포인트를 깎으려 들어 터진다.
    earned_points: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default="0"
    )
    receipt_image_url: Mapped[str | None] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    __table_args__ = (
        Index("ix_reviews_restaurant_id", "restaurant_id"),
        Index("ix_reviews_user_id", "user_id"),
        # 음식점별·사용자별로 최신순 정렬해 꺼낸다.
        Index("ix_reviews_restaurant_created", "restaurant_id", desc("created_at")),
        Index("ix_reviews_user_created", "user_id", desc("created_at")),
        Index("ix_reviews_tags_gin", "tags", postgresql_using="gin"),
        # 한 사람이 같은 가게에 여러 번 쓰면 리뷰당 500P 라 포인트를 무한히 만들 수 있다.
        # 다만 재방문 후 다시 쓰는 것도 함께 막히므로, 방문 단위로 허용하기로 하면
        # 이 제약을 풀고 영수증 단위 유니크로 바꿔야 한다.
        UniqueConstraint("user_id", "restaurant_id", name="uq_reviews_user_restaurant"),
    )
