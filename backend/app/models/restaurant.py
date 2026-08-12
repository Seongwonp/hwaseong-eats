from datetime import datetime

from sqlalchemy import BigInteger, Boolean, DateTime, Float, Index, String, Text, func, text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Restaurant(Base):
    """코나페이 가맹점 + 모범음식점을 담는 통합 업소 테이블.

    두 데이터를 하나로 뭉치는 게 아니라 출처 플래그를 각각 세워서,
    지도에서 칩 조합만으로 걸러지게 한다.
    """

    __tablename__ = "restaurants"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    address: Mapped[str] = mapped_column(Text, nullable=False)
    zip_code: Mapped[str | None] = mapped_column(String(10))
    phone: Mapped[str | None] = mapped_column(String(30))

    # 코나페이 주소는 도로명까지만 내려와서 수집 시점엔 좌표가 없다.
    # 지오코딩 배치가 나중에 채우므로 nullable.
    lat: Mapped[float | None] = mapped_column(Float)
    lng: Mapped[float | None] = mapped_column(Float)
    geocode_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending", server_default="pending"
    )

    category: Mapped[str | None] = mapped_column(String(100))
    biz_type_code: Mapped[str | None] = mapped_column(String(20))

    is_konapay: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )
    is_mobeom: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=False, server_default="false"
    )

    tags: Mapped[list[str] | None] = mapped_column(ARRAY(Text))

    # 코나페이 원본 키. 월 1회 재수집 시 이 값으로 UPSERT 한다.
    konapay_seq: Mapped[int | None] = mapped_column(BigInteger, unique=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    __table_args__ = (
        Index("ix_restaurants_coords", "lat", "lng"),
        Index("ix_restaurants_is_konapay", "is_konapay"),
        Index("ix_restaurants_is_mobeom", "is_mobeom"),
        Index("ix_restaurants_name", "name"),
        # 지도에서 가장 많이 거는 필터. 없으면 4만 행을 Seq Scan 한다.
        Index("ix_restaurants_category", "category"),
        Index("ix_restaurants_geocode_status", "geocode_status"),
        # ILIKE '%...%' 는 일반 인덱스를 못 탄다. 운영에서 314ms -> 0.3ms.
        # 로컬 DB 로케일이 C 면 한글 트라이그램이 안 만들어져 효과가 안 보인다.
        Index(
            "ix_restaurants_name_trgm",
            "name",
            postgresql_using="gin",
            postgresql_ops={"name": "gin_trgm_ops"},
        ),
        # 코나페이 원본 키가 없는 행(모범음식점 단독)은 상호명+주소로 중복을 막는다.
        Index(
            "uq_restaurants_name_address_no_seq",
            "name",
            "address",
            unique=True,
            postgresql_where=text("konapay_seq IS NULL"),
        ),
    )
