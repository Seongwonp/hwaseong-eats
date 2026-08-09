# CLAUDE.md — 화성뭐먹지? Flutter 프로젝트

## 프로젝트 개요

화성시 공공데이터 기반 지역 먹거리 지도 앱.
**해커톤 프로젝트**로, 완성도보다 핵심 기능 동작에 집중한다.

- 대회: 26년 여름학기 AI화성챌린지
- 예선: 8월 중 / 본선: 9월 17일
- 백엔드: FastAPI (Render 배포) — `API_BASE_URL` 환경변수로 연결

---

## 기술 스택 & 패키지 역할

| 패키지 | 용도 |
|--------|------|
| `flutter_riverpod` | 전역 상태 관리 |
| `go_router` | 화면 라우팅 |
| `dio` | HTTP API 통신 (`lib/services/api_service.dart`) |
| `kakao_map_plugin` | 지도 렌더링 |
| `flutter_dotenv` | `.env` 환경변수 로드 |
| `google_fonts` | NotoSerifKR 폰트 |

---

## 디자인 시스템

**절대 임의로 색상, 폰트, 모서리 반경을 바꾸지 말 것.**  
모든 값은 `lib/core/theme.dart` 의 `AppColors` / `AppTheme` 를 사용한다.

| 항목 | 값 |
|------|-----|
| 액센트 | `AppColors.primary` (#FF4F00) |
| 배경 | `AppColors.background` (#FFFEFB) |
| 본문 | `AppColors.textPrimary` (#201515) |
| 폰트 | NotoSerifKR 400 / 700 |
| 모서리 반경 | 12px 통일 |

### 지도 마커 색상 규칙

| 색상 | 상수 | 조건 |
|------|------|------|
| 파랑 | `AppColors.markerDefault` | 일반 음식점 (상시) |
| 초록 | `AppColors.markerPay` | 화성페이 가맹점 (상시) |
| 빨강 | `AppColors.markerSeasonal` | 절기 추천 (기념일 ±3일) |
| 보라 | `AppColors.markerFestival` | 축제 주변 (축제 기간만) |

기간이 끝난 마커는 반드시 사라지게 처리할 것.

---

## 폴더 구조

```
lib/
├── core/
│   ├── theme.dart        # AppColors, AppTheme
│   └── constants.dart    # ApiConstants, AppConstants
├── screens/              # 화면 단위
├── widgets/              # 재사용 위젯
├── models/               # JSON 파싱 데이터 클래스
├── services/
│   └── api_service.dart  # Dio 기반 API 통신
└── providers/            # Riverpod Provider
```

---

## 구현 우선순위 (해커톤 기준)

데모에서 보여줄 수 있는 것부터 만든다.

1. **지도 화면** — 카카오맵 + 마커 표시
2. **화성페이 필터** — 칩 탭 한 번으로 필터링
3. **절기 배너** — 오늘 날짜 기준 자동 표시
4. **음식점 상세** — 카드 탭 시 상세 정보
5. **리뷰 작성** — 화성인증 리뷰
6. **리워드** — 포인트 조회·전환
7. **축제 달력** — 축제 기간 연동

---

## 코딩 규칙

- 상태관리는 반드시 **Riverpod Provider** 사용. StatefulWidget 남발 금지.
- API 호출은 반드시 `lib/services/api_service.dart` 를 통해서만.
- 하드코딩 금지 — 색상은 `AppColors`, URL은 `ApiConstants`, 숫자는 `AppConstants`.
- 주석은 WHY가 명확할 때만. 코드가 self-explanatory하면 주석 불필요.
- 해커톤이므로 완벽한 에러 처리보다 **핵심 기능 동작**을 우선한다.

---

## 해커톤 제약 조건

- 과도한 추상화, 제네릭, 헬퍼 함수 금지. 단순하고 직접적으로.
- 아직 백엔드가 완성되지 않은 기능은 **목 데이터(mock data)** 로 UI 먼저 구현.
- 별점 시스템 없음 — 기획서 참고. 속성(매운맛·양·대표메뉴)으로만 기록.
- 회원가입 화면 없음 — 앱 실행 시 바로 지도 진입.
