# 백엔드 개발환경 세팅 가이드

> 백엔드 담당: 곽기원  
> 스택: Python + FastAPI + uv + SQLAlchemy + Alembic + PostgreSQL

---

## 1. uv 설치

`uv` 는 `requirements.txt` 대신 쓰는 현대적인 Python 패키지 관리 도구예요.  
pip보다 10~100배 빠르고, 의존성 충돌도 알아서 해결해줘요.

```bash
# macOS / Linux
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows (PowerShell)
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"

# 설치 확인
uv --version
```

---

## 2. 레포 클론 후 백엔드 세팅

```bash
git clone https://github.com/팀레포/hwaseong-food.git
cd hwaseong-food/backend

# 가상환경 생성 + 의존성 설치 (한 번에)
uv sync
```

---

## 3. 백엔드 프로젝트 초기 구조 세팅 (처음 한 번만)

> 이미 세팅되어 있으면 건너뛰세요

```bash
cd hwaseong-food/backend

# uv 프로젝트 초기화
uv init .

# 패키지 추가
uv add fastapi uvicorn sqlalchemy alembic psycopg2-binary python-dotenv anthropic
```

`pyproject.toml` 에 의존성이 자동으로 기록돼요. (`requirements.txt` 역할)

---

## 4. 환경변수 설정

`backend/` 폴더에 `.env` 파일 생성 (절대 깃에 올리면 안 됨!)

```env
DATABASE_URL=postgresql://유저:비밀번호@localhost:5432/hwaseong_food
CLAUDE_API_KEY=sk-ant-...
KAKAO_API_KEY=...
```

---

## 5. PostgreSQL 로컬 실행

```bash
# macOS (Homebrew)
brew install postgresql@16
brew services start postgresql@16

# DB 생성
psql postgres
CREATE DATABASE hwaseong_food;
\q
```

---

## 6. 서버 실행

```bash
cd hwaseong-food/backend

uv run uvicorn app.main:app --reload
```

브라우저에서 `http://localhost:8000/docs` 열면 API 문서 자동 생성돼요.

---

## 7. 자주 쓰는 uv 명령어

| 명령어 | 설명 |
|--------|------|
| `uv sync` | 의존성 설치 (처음 or pull 후) |
| `uv add 패키지명` | 패키지 추가 |
| `uv remove 패키지명` | 패키지 제거 |
| `uv run 명령어` | 가상환경 안에서 명령어 실행 |
| `uv lock` | lock 파일 갱신 |

---

다음 단계 → [SQLAlchemy 가이드](./sqlalchemy-guide.md)
