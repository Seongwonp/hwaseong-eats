# 시스템 아키텍처 — 화성뭐먹지?

**팀명:** OPUS  
**분류:** 소상공인 및 지역경제형 — 지역먹거리정보플랫폼  
**역할:** 이재운(기획·발표) / 최상훈(디자인) / 박성원(프론트엔드·API연결) / 곽기원(백엔드)  
**미팅:** Discord

---

## 1. 전체 구조

```
┌─────────────────────────────────┐
│         Flutter App             │
│   (iOS / Android 크로스플랫폼)    │
└────────────────┬────────────────┘
                 │ HTTP / REST API
┌────────────────▼────────────────┐
│         FastAPI Server          │
│  (Python 3.11+, Uvicorn)        │
├─────────────────────────────────┤
│  SQLAlchemy ORM + Alembic 마이그레이션  │
└────────────────┬────────────────┘
                 │
┌────────────────▼────────────────┐
│         PostgreSQL              │
└─────────────────────────────────┘
```

---

## 2. 기술 스택

| 영역 | 기술 | 비고 |
|------|------|------|
| 모바일 앱 | Flutter (Dart) | iOS · Android 동시 지원 |
| 백엔드 | Python FastAPI | 비동기, REST API |
| 패키지 관리 | uv | requirements.txt 대체, Rust 기반 초고속 |
| ORM | SQLAlchemy | DB 모델 관리 |
| 마이그레이션 | Alembic | 스키마 버전 관리 |
| 데이터베이스 | PostgreSQL | 메인 DB |
| 지도 | 카카오맵 API | Flutter 플러그인 연동 |
| AI | Claude API (Anthropic) | 공공데이터 가게명 매칭·정제 |
| 주소 변환 | 카카오 Geocoding API | 주소 → 좌표 변환 |

---

## 3. Flutter 앱 구조

```
lib/
├── main.dart
├── screens/
│   ├── map_screen.dart          # 메인 지도 화면
│   ├── restaurant_detail.dart   # 음식점 상세
│   ├── review_screen.dart       # 화성인증 리뷰 작성
│   ├── reward_screen.dart       # 포인트·리워드
│   └── festival_calendar.dart   # 축제·절기 달력
├── widgets/
│   ├── filter_chips.dart        # 화성페이·절기·축제 필터
│   ├── restaurant_card.dart     # 음식점 카드
│   └── marker_layer.dart        # 지도 마커 (색상 규칙 적용)
├── models/
│   ├── restaurant.dart
│   ├── review.dart
│   └── festival.dart
└── services/
    ├── api_service.dart         # FastAPI 통신
    └── kakao_map_service.dart   # 카카오맵 연동
```

**마커 색상 규칙**

| 색상 | 의미 | 표시 조건 |
|------|------|-----------|
| 파랑 | 일반 음식점 | 상시 |
| 초록 | 화성페이 가맹점 | 상시 |
| 빨강 | 절기 추천 | 기념일 ±3일 |
| 보라 | 축제 주변 업소 | 축제 기간 중 |

---

## 4. FastAPI 백엔드 구조

```
app/
├── main.py
├── database.py              # DB 연결 설정
├── models/                  # SQLAlchemy 모델
│   ├── restaurant.py
│   ├── review.py
│   ├── user.py
│   ├── reward.py
│   └── festival.py
├── schemas/                 # Pydantic 요청·응답 스키마
│   ├── restaurant.py
│   ├── review.py
│   └── reward.py
├── routers/                 # API 엔드포인트
│   ├── restaurants.py
│   ├── reviews.py
│   ├── rewards.py
│   ├── festivals.py
│   └── auth.py
└── services/
    ├── data_pipeline.py     # 공공데이터 수집·정제
    ├── llm_matching.py      # Claude API 가게명 매칭
    └── geocoding.py         # 주소 → 좌표 변환
```

**주요 API 엔드포인트**

| Method | 경로 | 기능 |
|--------|------|------|
| GET | `/restaurants` | 필터 조건별 음식점 조회 |
| GET | `/restaurants/{id}` | 음식점 상세 |
| GET | `/restaurants/nearby` | 현재 위치 기반 주변 음식점 |
| POST | `/reviews` | 리뷰 작성 (영수증 인증 포함) |
| GET | `/festivals` | 축제·절기 목록 |
| GET | `/festivals/today` | 오늘 날짜 기준 절기·축제 |
| POST | `/auth/verify` | 화성 주민 인증 |
| GET | `/rewards` | 포인트 조회 |
| POST | `/rewards/convert` | 화성페이 전환 |

---

## 5. 데이터베이스 주요 테이블

```
restaurants
├── id
├── name              # 통합 정제된 상호명
├── address
├── lat / lng         # 좌표
├── category          # 음식 카테고리
├── is_hwaseong_pay   # 화성페이 가맹 여부
├── source            # 데이터 출처 (모범음식점·착한가격 등)
└── created_at

reviews
├── id
├── restaurant_id
├── user_id
├── content
├── attributes        # 매운맛·양·대표메뉴 등 속성
├── is_verified       # 화성인증 여부
└── created_at

festivals
├── id
├── name
├── type              # 축제 or 절기
├── start_date
├── end_date
├── lat / lng         # 축제 위치
└── radius_km         # 강조 반경

rewards
├── id
├── user_id
├── points
└── updated_at
```

---

## 6. 데이터 파이프라인 (AI 활용)

공공데이터에서 같은 가게가 출처마다 다르게 표기되는 문제를 3단계로 해결

```
공공데이터 수집
(모범음식점 / 착한가격업소 / 로컬푸드직매장)
        ↓
1단계: 규칙 기반 정제
       (주), ㈜ 제거 / 지점명 분리 / 공백 정규화
        ↓
2단계: 좌표 기반 후보 압축
       카카오 Geocoding → 50m 이내 후보군 추출
        ↓
3단계: LLM 판정 (Claude API)
       애매한 쌍만 동일 가게 여부 최종 판정
        ↓
PostgreSQL 통합 마스터 DB 저장
```

---

## 7. Git 레포지토리 구조

### 모노레포 (단일 레포) 사용

프론트·백엔드를 하나의 레포로 관리해 팀원이 클론 한 번으로 전체 코드 접근 가능

```
hwaseong-food/                  ← GitHub 레포 (단일)
├── frontend/                   # Flutter 앱
│   ├── lib/
│   ├── pubspec.yaml
│   └── android/ ios/
├── backend/                    # FastAPI 서버
│   ├── app/
│   ├── alembic/
│   └── requirements.txt
└── README.md
```

### 브랜치 전략

```
main        ← 최종 안정본 (발표·제출용)
dev         ← 통합 개발 브랜치
feat/기능명  ← 기능 개발 후 dev로 PR
```

**규칙**
- 직접 `main` 에 푸시 금지, 반드시 PR로 머지
- 기능 완성 → `dev` PR → 확인 후 → `main` 머지

### 배포 (Render)

- Render 설정에서 `Root Directory` → `backend/` 로 지정
- `pyproject.toml` 기반 uv 자동 인식해서 배포

---

## 8. 디자인 워크플로우

**Figma → Flutter 분리 방식 채택**

| 역할 | 담당자 | 작업 |
|------|--------|------|
| 디자인 | 최상훈 | Figma로 화면 설계 및 시안 제작 |
| 구현 | 박성원 | Figma 시안 보고 Flutter 위젯 구현 |

**이유:** 디자이너가 Flutter(Dart)를 새로 배우는 시간보다 Figma 화면을 더 뽑는 게 팀 전체 효율에 유리

**Figma 전달 기준**
- 컴포넌트별 Export (카드·마커·필터칩 등)
- 색상·폰트·간격 값 명시
- 화면별 플로우 연결

---

## 9. 디자인 스펙 (Flutter 구현 기준)

| 항목 | 값 |
|------|-----|
| 기준 기기 | iPhone 17 (402 × 874), 반응형 |
| 액센트 컬러 | `#FF4F00` (화성 오렌지) |
| 배경 | `#FFFEFB` (웜 크림) |
| 본문 글자 | `#201515` (커피 잉크) |
| 폰트 | Noto Serif KR (400 / 700) |
| 모서리 반경 | 12px 통일 |
