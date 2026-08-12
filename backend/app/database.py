import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL 이 설정되지 않았습니다. backend/.env 를 확인하세요.")

# 일부 호스팅은 postgres:// 로 준다. SQLAlchemy 2.0 은 이 스킴을 못 알아본다.
if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 무료 인스턴스는 유휴 상태에서 연결이 끊긴다. pool_pre_ping 으로 죽은 커넥션을 걸러내고,
# 커넥션 수도 넉넉히 잡지 않는다(무료 PostgreSQL 은 동시 연결 제한이 빡빡하다).
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=5,
    pool_recycle=300,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
