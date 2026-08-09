# 백엔드 CRUD 구현 가이드

> FastAPI + SQLAlchemy 기반 CRUD 패턴.  
> 모든 기능은 이 패턴을 반복해서 구현한다.

---

## 기본 패턴: 모델 → 스키마 → 라우터

하나의 기능을 만들 때 항상 이 순서로 작업한다.

```
1. app/models/xxx.py      ← DB 테이블 정의
2. app/schemas/xxx.py     ← API 입출력 형식 정의
3. app/routers/xxx.py     ← 엔드포인트 구현
4. app/main.py            ← 라우터 등록
5. alembic 마이그레이션   ← DB에 테이블 반영
```

---

## 1. 모델 작성 (app/models/)

```python
# app/models/restaurant.py
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime
from sqlalchemy.sql import func
from app.database import Base

class Restaurant(Base):
    __tablename__ = "restaurants"

    id = Column(Integer, primary_key=True)
    name = Column(String, nullable=False)
    address = Column(String)
    lat = Column(Float)
    lng = Column(Float)
    category = Column(String)
    is_hwaseong_pay = Column(Boolean, default=False)
    source = Column(String)
    created_at = Column(DateTime, server_default=func.now())
```

모델을 만들었으면 `alembic/env.py` 에 import 추가

```python
from app.models.restaurant import Restaurant
from app.database import Base
target_metadata = Base.metadata
```

그 다음 마이그레이션 생성 및 적용

```bash
uv run alembic revision --autogenerate -m "add restaurants table"
uv run alembic upgrade head
```

---

## 2. 스키마 작성 (app/schemas/)

모델과 별개로 API 요청·응답 형식을 Pydantic으로 정의한다.

```python
# app/schemas/restaurant.py
from pydantic import BaseModel

class RestaurantCreate(BaseModel):
    name: str
    address: str | None = None
    lat: float | None = None
    lng: float | None = None
    category: str | None = None
    is_hwaseong_pay: bool = False
    source: str | None = None

class RestaurantResponse(BaseModel):
    id: int
    name: str
    address: str | None
    lat: float | None
    lng: float | None
    category: str | None
    is_hwaseong_pay: bool

    model_config = {"from_attributes": True}  # SQLAlchemy 모델 변환 허용
```

---

## 3. 라우터 작성 (app/routers/)

```python
# app/routers/restaurants.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.restaurant import Restaurant
from app.schemas.restaurant import RestaurantCreate, RestaurantResponse

router = APIRouter()

# 목록 조회
@router.get("/", response_model=list[RestaurantResponse])
def get_restaurants(
    is_hwaseong_pay: bool | None = None,
    category: str | None = None,
    db: Session = Depends(get_db),
):
    query = db.query(Restaurant)
    if is_hwaseong_pay is not None:
        query = query.filter(Restaurant.is_hwaseong_pay == is_hwaseong_pay)
    if category:
        query = query.filter(Restaurant.category == category)
    return query.all()

# 단건 조회
@router.get("/{restaurant_id}", response_model=RestaurantResponse)
def get_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    item = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="음식점을 찾을 수 없습니다")
    return item

# 생성
@router.post("/", response_model=RestaurantResponse)
def create_restaurant(data: RestaurantCreate, db: Session = Depends(get_db)):
    item = Restaurant(**data.model_dump())
    db.add(item)
    db.commit()
    db.refresh(item)
    return item

# 수정
@router.patch("/{restaurant_id}", response_model=RestaurantResponse)
def update_restaurant(restaurant_id: int, data: RestaurantCreate, db: Session = Depends(get_db)):
    item = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="음식점을 찾을 수 없습니다")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    db.commit()
    db.refresh(item)
    return item

# 삭제
@router.delete("/{restaurant_id}")
def delete_restaurant(restaurant_id: int, db: Session = Depends(get_db)):
    item = db.query(Restaurant).filter(Restaurant.id == restaurant_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="음식점을 찾을 수 없습니다")
    db.delete(item)
    db.commit()
    return {"message": "삭제되었습니다"}
```

---

## 4. main.py에 라우터 등록

```python
# app/main.py
from app.routers import restaurants

app.include_router(restaurants.router, prefix="/restaurants", tags=["restaurants"])
```

---

## 5. 확인

서버 실행 후 http://localhost:8000/docs 접속하면  
Swagger UI에서 API를 바로 테스트할 수 있다.

---

## 구현 순서 (우선순위)

| 순서 | 기능 | 엔드포인트 |
|------|------|-----------|
| 1 | 음식점 조회 (지도 핵심) | `GET /restaurants` |
| 2 | 오늘 절기·축제 | `GET /festivals/today` |
| 3 | 음식점 상세 | `GET /restaurants/{id}` |
| 4 | 리뷰 작성 | `POST /reviews` |
| 5 | 포인트 조회 | `GET /rewards` |
| 6 | 주민 인증 | `POST /auth/verify` |
| 7 | 포인트 전환 | `POST /rewards/convert` |
