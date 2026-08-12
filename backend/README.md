# 백엔드

화성시 먹거리 지도 API. FastAPI + SQLAlchemy + PostgreSQL.

```
운영 서버   https://hwaseong-eats-api.onrender.com
API 문서    https://hwaseong-eats-api.onrender.com/docs
```

---

## 빠른 시작

```bash
cd backend

uv sync                                  # 의존성 설치
cp .env.example .env                     # 환경변수 (아래 참고)
uv run alembic upgrade head              # 테이블 생성
uv run uvicorn app.main:app --reload     # 서버 실행
```

`http://localhost:8000/docs` 에서 Swagger UI로 바로 호출해 볼 수 있다.

### 환경변수

| 키 | 필수 | 용도 |
|---|---|---|
| `DATABASE_URL` | ✅ | `postgresql://user:pw@host:5432/hwaseong_food` |
| `JWT_SECRET` | ✅ | 토큰 서명 키. `python -c "import secrets; print(secrets.token_urlsafe(48))"` |
| `KAKAO_API_KEY` | 수집 시만 | 카카오 로컬 REST API 키 |

`.env` 는 `.gitignore` 에 있다. 절대 커밋하지 말 것.

---

## API

### 음식점

| | 경로 | 설명 |
|---|---|---|
| `GET` | `/restaurants` | 목록 조회 |
| `GET` | `/restaurants/{id}` | 단건 조회 |

**쿼리 파라미터**

| 이름 | 예 | 설명 |
|---|---|---|
| `is_konapay` | `true` | 화성페이 가맹점만 |
| `is_mobeom` | `true` | 모범음식점만 |
| `category` | `일반음식점` | 업종 |
| `tag` | `카공픽` | 태그 (아직 데이터 없음) |
| `q` | `본죽` | 상호명 검색 |
| `food_only` | `true` (기본) | 음식 업종만 |
| `lat`, `lng` | `37.2014`, `127.0985` | 현재 위치. 주면 거리순 정렬 |
| `radius_km` | `1` | 반경. `lat`/`lng` 과 함께 써야 함 |
| `limit`, `offset` | `100`, `0` | 페이지네이션 (최대 500) |

```bash
# 화성페이 되는 모범음식점
curl "$API/restaurants?is_konapay=true&is_mobeom=true"

# 동탄역 반경 1km, 가까운 순
curl "$API/restaurants?lat=37.2014&lng=127.0985&radius_km=1"
```

`lat`/`lng` 을 주면 응답에 `distance_km` 이 채워지고 가까운 순으로 정렬된다.

**응답에 평균 별점과 식사평 수가 함께 온다.** 지도 카드의 `★ 4.6 (122)` 용이다.

```json
{ "id": 2, "name": "본죽", "lat": 37.19, "lng": 127.09,
  "avg_rating": 4.6, "review_count": 122, ... }
```

별점을 안 남긴 식사평도 있어서 **평균은 별점이 있는 것만, 개수는 전체**를 센다.
식사평이 없으면 `avg_rating` 은 `null`, `review_count` 는 `0`.

### 인증

| | 경로 | 설명 |
|---|---|---|
| `POST` | `/auth/signup` | 이메일 + 비밀번호 + 닉네임 → 토큰 |
| `POST` | `/auth/login` | → 토큰 |
| `GET` | `/auth/me` | 내 정보 |
| `POST` | `/auth/verify` | 화성주민 인증 (6개월 유효) |
| `GET` | `/auth/me/points` | 포인트 적립·사용 내역 |
| `POST` | `/auth/me/points/exchange` | 화성페이 전환 |

토큰은 `Authorization: Bearer <token>` 헤더로 보낸다. 유효기간 14일.

```bash
TOKEN=$(curl -s -X POST "$API/auth/signup" -H 'Content-Type: application/json' \
  -d '{"email":"me@example.com","password":"hwaseong1234","nickname":"화성인"}' \
  | jq -r .access_token)

curl "$API/auth/me" -H "Authorization: Bearer $TOKEN"
```

로그인은 분당 5회, 가입은 분당 3회, 포인트 전환은 분당 10회로 제한된다. 넘으면 `429`.

### 포인트

```bash
# 내역 (적립은 delta 양수, 사용은 음수)
curl "$API/auth/me/points" -H "Authorization: Bearer $TOKEN"

# 화성페이 전환 — 1,000P 단위, 1P = 1원
curl -X POST "$API/auth/me/points/exchange" -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' -d '{"points":1000}'
```

잔액이 모자라면 `400`, 1,000P 단위가 아니면 `422`.
실제 화성페이 지급 연동은 없다. 포인트 차감과 내역 기록까지만 한다.

### 식사평

| | 경로 | 설명 |
|---|---|---|
| `POST` | `/reviews` | 등록. 화성인증이면 +500P |
| `GET` | `/reviews` | 조회 (`restaurant_id`, `certified_only`) |
| `GET` | `/reviews/me` | 내 식사평 |
| `DELETE` | `/reviews/{id}` | 삭제. 적립분 회수 |

**화성인증 식사평** = 주민인증이 살아 있고 + 영수증 인증까지 된 경우. 이때만 500P가 붙는다.
한 사람이 같은 가게에 두 번 쓰면 `409`.

---

## 데이터

`restaurants` 48,606건. 세 곳에서 모았다.

| 출처 | 건수 | 비고 |
|---|---|---|
| 코나페이 (경기지역화폐) | 48,574 | 내부 API 호출 |
| 모범음식점 (공공데이터 15153027) | 95 | 겹치면 `is_mobeom` 만 세움 |
| 소상공인 상가정보 (15083033) | — | 좌표 채우는 용도 |

두 데이터를 하나로 뭉치지 않고 `is_konapay` / `is_mobeom` 플래그를 세운다.
지도에서 칩 조합만으로 필터가 떨어지게 하기 위해서다.

### 좌표

`geocode_status` 가 출처와 신뢰도를 함께 담는다.

| 값 | 뜻 |
|---|---|
| `sangga` | 상가정보 좌표. 가장 믿을 만함 |
| `verified` | 카카오 장소 검색에서 상호명까지 확인 |
| `ok` | 카카오 좌표. 상호명 대조 안 함 |
| `konapay` | 코나페이 원본. 정밀도 낮음 |
| `unverified` | 도로 중심점 수준. **API 응답에서 제외** |
| `pending` / `failed` | 좌표 없음 |

`unverified` 907건은 데이터를 지우지 않고 조회에서만 뺀다.
기준은 `app/core/constants.py` 의 `VISIBLE_GEOCODE_STATUSES` 하나로 통제된다.

### 수집 스크립트

```bash
uv run python -m app.services.konapay        # 코나페이 (약 3분)
uv run python -m app.services.mobeom         # 모범음식점 병합
uv run python -m app.services.sangga         # 상가정보 좌표 (data/ 에 zip 필요)
uv run python -m app.services.geocoding      # 카카오 지오코딩 (약 18분)
uv run python -m app.services.geocode_refine # 겹친 좌표 재검증
```

전부 여러 번 돌려도 안전하다. 코나페이는 원본 키 기준 UPSERT, 모범음식점은 이미 있으면
플래그만 세운다.

`sangga` 는 [공공데이터포털 15083033](https://www.data.go.kr/data/15083033/fileData.do)
의 zip 을 `backend/data/` 에 넣어두면 경기 CSV(369MB)를 풀지 않고 스트리밍으로 읽는다.

---

## 테스트

```bash
uv run pytest              # 전체 108개
uv run pytest tests/test_matching.py   # DB 없이 도는 31개
```

DB가 없으면 DB를 쓰는 테스트는 자동으로 건너뛴다.

---

## 구조

```
app/
├── core/
│   ├── constants.py   업종·좌표상태·리워드 기준. 모든 모듈이 여기를 본다
│   ├── security.py    bcrypt 해싱, JWT
│   ├── deps.py        로그인 사용자 주입
│   ├── ratelimit.py   slowapi
│   └── http.py        외부 API 재시도·백오프
├── models/            SQLAlchemy 테이블
├── schemas/           요청·응답 형식
├── routers/           restaurants, auth, reviews
├── services/          수집·지오코딩·포인트
├── database.py
└── main.py
```

---

## 배포

Render(싱가포르, 무료). `feat/backend` 에 푸시하면 자동 재배포된다.

```
Build   pip install uv && uv sync --frozen
Start   uv run alembic upgrade head && uv run uvicorn app.main:app --host 0.0.0.0 --port $PORT
```

마이그레이션은 빌드가 아니라 기동 시점에 돈다. 빌드 단계에는 DB가 없을 수 있다.

**무료 인스턴스는 15분 유휴 시 잠든다.** 첫 요청이 30초~1분 걸리므로 발표 전에 한 번
깨워둘 것.

---

## 알아둘 것

**무료 PostgreSQL 이 2026-09-11 에 만료된다.** 본선(9/17)보다 먼저다.
9월 초에 새 DB를 만들어 옮기거나 유료로 올려야 한다. 덤프가 2MB 남짓이라 몇 분이면 된다.

**`restaurants.tags` 가 전부 비어 있다.** 프론트 지도의 `#카공픽 #10대픽 #혼밥 #가성비`
필터칩을 누르면 빈 화면이 나온다. 공공데이터에 없는 정보라 따로 채워야 한다.

**로컬과 운영 DB의 로케일이 다르다.** 로컬은 `C`, Render는 `en_US.UTF8` 이다.
한글 정렬 순서와 `pg_trgm` 동작이 달라서, 검색 성능은 로컬에서 재면 안 된다.
(운영에서 상호명 검색 314ms → 0.3ms)

**`/auth/verify` 는 데모 스텁이다.** 호출하면 누구나 화성주민이 된다.
실제 주민등록 확인 연동은 없다.
