# 볏섬 데이터 소스 정리

화성시 먹거리 지도 앱에 필요한 공공데이터 및 외부 API 목록.

---

## 수집 우선순위

| 순서 | 데이터 | 상태 | 용도 |
|------|--------|------|------|
| 1 | 화성페이 가맹점 (코나카드) | ✅ 완료 | `is_konapay = true` |
| 2 | 경기도 모범음식점 | ❌ 미구현 | `is_mobeom = true` |
| 3 | 전국일반음식점 인허가 | ❌ 미구현 | 마스터 음식점 DB |
| 4 | 착한가격업소 | ❌ 미구현 | 나중에 추가 |
| 5 | 화성시 축제·행사 | 하드코딩 | `festivals` 테이블 |

---

## 1. 화성페이 가맹점 (코나카드)

- **소스**: `search.konacard.co.kr` 내부 API 역분석
- **구현 파일**: `backend/app/services/konapay.py`
- **수집 방식**: POST `/api/v1/payable-merchants`, 화성시 affiliateId=26
- **특이사항**: 좌표 없는 경우가 많아 geocoding 단계에서 채움
- **갱신 주기**: 월 1회 권장 (UPSERT by `konapay_seq`)

공식 파트너 API도 있음 (계약 필요):
- 파트너센터: `openpartner.konacard.co.kr`
- 고객센터: 1899-7997

---

## 2. 경기도 모범음식점 ← 다음 작업

- **소스**: 경기데이터드림
- **URL**: `data.gg.go.kr/portal/data/service/selectServicePage.do?infId=85K5H77PWPLDL7B4TNMK507168`
- **화성시 필터 파라미터**: `sigunFlag=41820`
- **장점**: WGS84 위경도 직접 제공 → 지오코딩 불필요
- **갱신 주기**: 연간
- **구현 방법**: `konapay.py` 패턴 그대로 따라서 `mobeom.py` 작성

주요 필드:

| 필드 | 설명 |
|------|------|
| 업소명 | 상호명 |
| 주메뉴 | 대표 메뉴 |
| 전화번호 | 연락처 |
| 업태명 | 한식/중식 등 |
| 도로명주소 | 주소 |
| 위도 / 경도 | WGS84 좌표 직접 제공 |

---

## 3. 전국일반음식점 인허가 데이터

- **소스**: 공공데이터포털 (data.go.kr)
- **URL**: `data.go.kr/data/15096283/standard.do`
- **화성시 코드**: `opnSfTeamCode=41590`
- **제공 방식**: CSV 파일 다운로드 (매일 갱신) 또는 Open API
- **주의사항**: 좌표가 구 좌표계(EPSG:5174)라 카카오 Geocoding 변환 필요
- **전처리**: `영업상태명=영업` 필터 후 사용

주요 필드:

| 필드 | 설명 |
|------|------|
| 사업장명 | 상호명 |
| 영업상태명 | 영업/휴업/폐업 |
| 업태구분명 | 한식/중식/일식/서양식 등 |
| 도로명전체주소 | 도로명 주소 |
| 소재지전화 | 전화번호 |
| 좌표정보(X/Y) | EPSG:5174 → WGS84 변환 필요 |

---

## 4. 착한가격업소

- **소스**: 공공데이터포털 (data.go.kr)
- **URL**: `data.go.kr/data/3045247/fileData.do`
- **제공 방식**: 분기별 CSV (로그인 불필요)
- **주의사항**: 좌표 없음 → 카카오 Geocoding 변환 필요
- **특징**: 착한가격 메뉴명/가격 최대 4개 포함 → 상세 화면에서 표시 가능

---

## 5. 화성시 축제·행사

현재 `seasonal_event.dart`에 하드코딩 상태. 추후 DB화 시 아래 소스 사용.

### 전국문화축제표준데이터
- **URL**: `data.go.kr/data/15013104/standard.do`
- **갱신**: 분기별
- **특징**: 위도·경도 직접 제공

### 한국관광공사 TourAPI (실시간)
- **URL**: `api.visitkorea.or.kr`
- **파라미터**: `contentTypeId=15` (축제·공연·행사), `areaCode=31` (경기도)
- **특징**: 실시간 업데이트, 26만 건 이상

### 화성시 자체 행사
- 화성특례시 통합예약시스템: `yeyak.hscity.go.kr/1071/3010/festivalList.do`
- 공식 API 없음 → HTML 파싱 필요

---

## 6. 카카오 로컬 API (지오코딩)

주소를 WGS84 좌표로 변환할 때 사용. `geocoding.py`에 구현됨.

| 기능 | 엔드포인트 |
|------|-----------|
| 주소 검색 | `dapi.kakao.com/v2/local/search/address.json` |
| 키워드 검색 | `dapi.kakao.com/v2/local/search/keyword.json` |

- **인증**: `Authorization: KakaoAK {REST_API_KEY}`
- **환경변수**: `KAKAO_API_KEY` (backend `.env`)
- **주의**: 2024.12.01부터 신규 앱은 카카오맵 사용 설정 ON 필요

---

## 참고: 화성시 코드

| 항목 | 코드 |
|------|------|
| 행정구역 코드 | 41590 |
| 경기데이터드림 시군 코드 | 41820 |
| 경기도 광역코드 | 31 |
