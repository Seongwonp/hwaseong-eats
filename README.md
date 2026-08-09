# 화성뭐먹지? (hwaseong-eats)

화성시 공공데이터 기반 지역 먹거리 지도 플랫폼

**팀명:** OPUS  
**대회:** 26년 여름학기 AI화성챌린지

## 프로젝트 구조

```
hwaseong-eats/
├── frontend/   # Flutter 앱 (iOS · Android)
├── backend/    # FastAPI 서버
└── docs/       # 개발 가이드 문서
```

## 시작하기

### 백엔드

```bash
cd backend
uv sync
cp .env.example .env   # .env 파일 수정 필요
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

API 문서: http://localhost:8000/docs

### 프론트엔드

```bash
cd frontend
flutter pub get
flutter run
```

## 문서

- [시스템 아키텍처](../시스템아키텍처.md)
- [백엔드 세팅 가이드](docs/backend-setup.md)
- [SQLAlchemy 가이드](docs/sqlalchemy-guide.md)
- [Alembic 마이그레이션 가이드](docs/alembic-guide.md)
