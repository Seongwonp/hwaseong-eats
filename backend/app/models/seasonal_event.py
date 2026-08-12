from datetime import date, datetime

from sqlalchemy import BigInteger, Date, DateTime, Float, Index, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class SeasonalEvent(Base):
    """절기·명절·축제를 한 테이블에 담는다.

    지도에서는 "오늘 뭘 먹을 때인가"를 묻지, 그게 절기인지 축제인지를 먼저 나누지 않는다.
    조회가 항상 날짜 기준이라 한 테이블에서 기간으로 거르는 게 단순하다.
    """

    __tablename__ = "seasonal_events"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    event_type: Mapped[str] = mapped_column(String(20), nullable=False)  # 절기 | 명절 | 축제

    # 절기·명절은 하루라 시작일과 종료일이 같다.
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)

    # 그날 뭘 먹는지. 배너 문구에 쓴다.
    food_keyword: Mapped[str | None] = mapped_column(String(100))

    # 축제만 갖는 값. 절기는 지역이 없다.
    location: Mapped[str | None] = mapped_column(String(200))
    lat: Mapped[float | None] = mapped_column(Float)
    lng: Mapped[float | None] = mapped_column(Float)
    radius_km: Mapped[float | None] = mapped_column(Float)

    description: Mapped[str | None] = mapped_column(Text)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    __table_args__ = (
        Index("ix_seasonal_events_dates", "start_date", "end_date"),
        Index("ix_seasonal_events_type", "event_type"),
        # 같은 축제가 표준데이터에 두 번 실려 있는 경우가 있어(회차 표기 차이)
        # 이름+시작일로 중복을 막는다.
        Index("uq_seasonal_events_name_start", "name", "start_date", unique=True),
    )
