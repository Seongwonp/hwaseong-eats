# 볏섬

> 화성시 공공데이터 기반 지역 먹거리 지도 플랫폼  
> 26년 여름학기 AI화성챌린지 — 팀 OPUS

---

## 프로젝트 소개

화성시에 사는 사람은 근처에 뭐가 있는지 모르고, 놀러 온 사람은 축제 와서 결국 편의점에서 먹는다.  
두 사람의 서로 다른 문제를 하나의 지도로 푼다.

**볏섬**은 화성시 향토음식 **볏섬떡**에서 이름을 따왔다.  
볏섬떡은 마도면 금당골에서 풍농을 기원하며 만들어 먹던 전통 음식으로,  
떡방아 찧는 토끼를 주황색 마스코트로 삼아 화성(Mars)의 붉은 행성 색과도 자연스럽게 연결된다.

- 화성페이 가맹점을 지도에서 바로 확인
- 말복이면 삼계탕, 축제 기간이면 주변 맛집 자동 추천
- 화성 주민이 직접 남긴 인증 리뷰로 신뢰 확보

---

## 팀

| 이름 | 역할 |
|------|------|
| 이재운 | 기획 · 발표 |
| 최상훈 | 디자인 (Figma) |
| 박성원 | 프론트엔드 · API 연결 |
| 곽기원 | 백엔드 |

**미팅:** Discord

---

## 기술 스택

| 영역 | 기술 |
|------|------|
| 모바일 | Flutter (iOS · Android) |
| 백엔드 | Python FastAPI |
| 패키지 관리 | uv |
| ORM | SQLAlchemy + Alembic |
| DB | PostgreSQL |
| 지도 | 카카오맵 API |
| AI | Claude API (공공데이터 정제) |
| 배포 | Render (백엔드) |

---

## 디자인 시스템

| 항목 | 값 |
|------|-----|
| 액센트 | `#FF4F00` (화성 오렌지) |
| 배경 | `#FFFEFB` (웜 크림) |
| 본문 | `#201515` (커피 잉크) |
| 폰트 | Noto Serif KR 400 / 700 |
| 모서리 반경 | 12px 통일 |

---

## 프로젝트 구조

```
hwaseong-eats/
├── frontend/                   # Flutter 앱
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/               # 테마, 상수
│   │   ├── screens/            # 화면
│   │   ├── widgets/            # 공통 위젯
│   │   ├── models/             # 데이터 모델
│   │   ├── services/           # API 통신
│   │   └── providers/          # Riverpod 상태관리
│   ├── CLAUDE.md               # AI 협업 가이드
│   └── pubspec.yaml
├── backend/                    # FastAPI 서버
│   ├── app/
│   │   ├── models/             # SQLAlchemy 모델
│   │   ├── schemas/            # Pydantic 스키마
│   │   ├── routers/            # API 엔드포인트
│   │   └── services/           # 비즈니스 로직
│   ├── alembic/                # DB 마이그레이션
│   ├── pyproject.toml          # uv 패키지 관리
│   └── .env.example
└── docs/                       # 개발 가이드
```

---

## 시작하기

### 백엔드

```bash
cd backend

# 1. 의존성 설치
uv sync

# 2. 환경변수 설정
cp .env.example .env
# .env 파일 열어서 DB URL, API 키 입력

# 3. DB 마이그레이션
uv run alembic upgrade head

# 4. 서버 실행
uv run uvicorn app.main:app --reload
```

API 문서: http://localhost:8000/docs

### 프론트엔드

```bash
cd frontend

# 1. 의존성 설치
flutter pub get

# 2. 환경변수 설정
cp .env.example .env
# .env 파일 열어서 API 키 입력

# 3. 앱 실행
flutter run
```

---

## 브랜치 전략

```
main        ← 최종 안정본 (발표·제출용)
dev         ← 통합 개발
feat/기능명  ← 기능 개발 후 dev로 PR
```

- `main` 에 직접 푸시 금지, 반드시 PR로 머지
- 기능 완성 → `dev` PR → 확인 후 → `main` 머지

---

## 문서

- [시스템 아키텍처](docs/시스템아키텍처.md)
- [백엔드 세팅 가이드](docs/backend-setup.md)
- [SQLAlchemy 가이드](docs/sqlalchemy-guide.md)
- [Alembic 마이그레이션 가이드](docs/alembic-guide.md)
- [백엔드 CRUD 가이드](docs/backend-crud.md)
