# SQLAlchemy 사용 가이드

> SQLAlchemy는 Python에서 DB를 객체(클래스)로 다루게 해주는 ORM이에요.  
> SQL을 직접 쓰는 대신 Python 코드로 DB를 조작해요.

---

## 1. DB 연결 설정

`app/database.py`

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from dotenv import load_dotenv
import os

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

class Base(DeclarativeBase):
    pass
```

---

## 2. 모델 정의 (테이블 = 클래스)

`app/models/restaurant.py`

```python
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

---

## 3. DB 세션을 FastAPI에서 쓰는 방법

`app/database.py` 에 아래 추가

```python
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

라우터에서 `Depends(get_db)` 로 주입해서 사용

```python
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.restaurant import Restaurant

router = APIRouter()

@router.get("/restaurants")
def get_restaurants(db: Session = Depends(get_db)):
    return db.query(Restaurant).all()
```

---

## 4. 자주 쓰는 CRUD 패턴

```python
# 전체 조회
db.query(Restaurant).all()

# 조건 조회
db.query(Restaurant).filter(Restaurant.is_hwaseong_pay == True).all()

# 단건 조회
db.query(Restaurant).filter(Restaurant.id == 1).first()

# 생성
new = Restaurant(name="맛있는 식당", address="화성시 ...")
db.add(new)
db.commit()
db.refresh(new)  # DB에서 생성된 id 등 반영

# 수정
restaurant = db.query(Restaurant).filter(Restaurant.id == 1).first()
restaurant.name = "새 이름"
db.commit()

# 삭제
db.delete(restaurant)
db.commit()
```

---

## 5. Pydantic 스키마 (요청·응답 형식 정의)

SQLAlchemy 모델은 DB용, Pydantic 스키마는 API 입출력용으로 분리해요.

`app/schemas/restaurant.py`

```python
from pydantic import BaseModel

class RestaurantResponse(BaseModel):
    id: int
    name: str
    address: str | None
    lat: float | None
    lng: float | None
    is_hwaseong_pay: bool

    model_config = {"from_attributes": True}  # SQLAlchemy 모델 → Pydantic 변환 허용
```

라우터에서 사용

```python
@router.get("/restaurants", response_model=list[RestaurantResponse])
def get_restaurants(db: Session = Depends(get_db)):
    return db.query(Restaurant).all()
```

---

다음 단계 → [Alembic 마이그레이션 가이드](./alembic-guide.md)
