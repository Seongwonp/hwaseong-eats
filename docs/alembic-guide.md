# Alembic 마이그레이션 가이드

> Alembic은 DB 스키마 변경을 버전으로 관리해주는 도구예요.  
> 모델을 수정할 때마다 마이그레이션 파일을 만들어서 팀원 모두가 같은 DB 구조를 유지해요.

---

## 1. 초기 설정 (처음 한 번만)

```bash
cd hwaseong-food/backend

uv run alembic init alembic
```

`alembic/` 폴더와 `alembic.ini` 파일이 생성돼요.

---

## 2. alembic.ini 수정

`alembic.ini` 에서 DB URL 설정 라인을 찾아서 `.env` 에서 읽어오도록 수정

`alembic/env.py` 상단에 아래 추가

```python
from dotenv import load_dotenv
from app.database import Base
from app.models import restaurant, review, user, reward, festival  # 모든 모델 import
import os

load_dotenv()

# alembic.ini의 sqlalchemy.url을 .env 값으로 덮어쓰기
config.set_main_option("sqlalchemy.url", os.getenv("DATABASE_URL"))

# Base.metadata 연결 (자동 감지용)
target_metadata = Base.metadata
```

---

## 3. 마이그레이션 파일 생성

모델을 만들거나 수정했을 때 실행

```bash
uv run alembic revision --autogenerate -m "설명"

# 예시
uv run alembic revision --autogenerate -m "add restaurants table"
uv run alembic revision --autogenerate -m "add is_hwaseong_pay column"
```

`alembic/versions/` 폴더에 마이그레이션 파일이 생성돼요.

---

## 4. 마이그레이션 적용 (DB에 반영)

```bash
# 최신 버전으로 적용
uv run alembic upgrade head

# 한 단계만 적용
uv run alembic upgrade +1
```

---

## 5. 롤백 (되돌리기)

```bash
# 한 단계 되돌리기
uv run alembic downgrade -1

# 처음으로 되돌리기
uv run alembic downgrade base
```

---

## 6. 현재 상태 확인

```bash
# 현재 적용된 버전 확인
uv run alembic current

# 전체 히스토리 확인
uv run alembic history
```

---

## 7. 실제 작업 흐름 (팀 협업 시)

```
1. 모델 수정 (app/models/xxx.py)
2. 마이그레이션 파일 생성
   uv run alembic revision --autogenerate -m "변경 설명"
3. 마이그레이션 확인 (alembic/versions/ 파일 열어서 up/downgrade 확인)
4. DB에 적용
   uv run alembic upgrade head
5. git add alembic/versions/ 파일 커밋
6. 팀원이 pull 받은 후
   uv run alembic upgrade head  ← 팀원도 동일하게 실행
```

---

## 주의사항

- 마이그레이션 파일은 반드시 **깃에 커밋**해야 해요. 안 하면 팀원 DB가 달라져요.
- `--autogenerate` 가 모든 변경을 완벽하게 잡지는 않아요. 생성된 파일을 꼭 열어서 `upgrade` / `downgrade` 함수가 맞는지 확인하세요.
- 절대 이미 적용된 마이그레이션 파일을 수정하지 마세요. 새 마이그레이션을 만드세요.
