from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import SeasonalEvent
from app.schemas.festival import SeasonalEventListResponse, SeasonalEventResponse, TodayResponse

router = APIRouter()

# 기념일 ±3일 안에 들면 "때가 됐다"고 본다. 기획서 p.8 마커 색 규칙과 같은 기준이다.
NEAR_DAYS = 3


def _to_response(event: SeasonalEvent, today: date) -> SeasonalEventResponse:
    if today < event.start_date:
        d_day = (event.start_date - today).days
    elif today > event.end_date:
        d_day = (event.end_date - today).days
    else:
        d_day = 0

    return SeasonalEventResponse(
        id=event.id,
        name=event.name,
        event_type=event.event_type,
        start_date=event.start_date,
        end_date=event.end_date,
        food_keyword=event.food_keyword,
        location=event.location,
        lat=event.lat,
        lng=event.lng,
        radius_km=event.radius_km,
        d_day=d_day,
        is_active=event.start_date - timedelta(days=NEAR_DAYS)
        <= today
        <= event.end_date + timedelta(days=NEAR_DAYS),
    )


@router.get("", response_model=SeasonalEventListResponse)
def list_events(
    event_type: str | None = Query(None, description="절기 | 명절 | 축제"),
    upcoming_only: bool = Query(False, description="아직 안 끝난 것만"),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
):
    today = date.today()

    filters = []
    if event_type:
        filters.append(SeasonalEvent.event_type == event_type)
    if upcoming_only:
        filters.append(SeasonalEvent.end_date >= today)

    total = db.scalar(select(func.count()).select_from(SeasonalEvent).where(*filters))
    events = db.scalars(
        select(SeasonalEvent).where(*filters).order_by(SeasonalEvent.start_date).limit(limit)
    ).all()

    return SeasonalEventListResponse(
        total=total, items=[_to_response(e, today) for e in events]
    )


@router.get("/today", response_model=TodayResponse)
def today_events(db: Session = Depends(get_db)):
    """오늘 띄울 절기·축제.

    아무것도 누르지 않아도 답이 나오게 하는 게 기획서 시나리오A 다. 기념일 ±3일,
    축제는 기간 중이면 잡는다. 기간이 끝나면 자연히 빠진다.
    """
    today = date.today()
    window = timedelta(days=NEAR_DAYS)

    events = db.scalars(
        select(SeasonalEvent)
        .where(
            SeasonalEvent.start_date - window <= today,
            SeasonalEvent.end_date + window >= today,
        )
        .order_by(SeasonalEvent.start_date)
    ).all()

    items = [_to_response(e, today) for e in events]
    # 배너는 하나만 띄운다. 절기와 축제가 겹치면 축제를 앞세운다 — 기간이 짧아 놓치기 쉽다.
    primary = None
    if items:
        primary = sorted(items, key=lambda x: (x.event_type != "축제", abs(x.d_day)))[0]

    return TodayResponse(date=today, primary=primary, items=items)


@router.get("/{event_id}", response_model=SeasonalEventResponse)
def get_event(event_id: int, db: Session = Depends(get_db)):
    event = db.get(SeasonalEvent, event_id)
    if event is None:
        raise HTTPException(404, "일정을 찾을 수 없습니다")
    return _to_response(event, date.today())
