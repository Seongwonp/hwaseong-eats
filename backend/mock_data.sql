-- 볏섬 로컬 개발용 목 데이터
-- 사용법: psql -U postgres -d hwaseong_eats -f mock_data.sql
--
-- 주의: 이 파일을 실행하기 전에 alembic 마이그레이션이 완료되어야 합니다.
--   cd backend && uv run alembic upgrade head
--
-- 비밀번호 해시 생성 (pgcrypto 확장 사용)
-- 모든 테스트 계정 비밀번호: test1234

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ──────────────────────────────────────────────
-- 기존 목 데이터 초기화 (ID 9000001 이상만 삭제)
-- ──────────────────────────────────────────────
DELETE FROM point_history WHERE user_id IN (SELECT id FROM users WHERE id >= 9000001);
DELETE FROM reviews WHERE user_id IN (SELECT id FROM users WHERE id >= 9000001);
DELETE FROM reviews WHERE restaurant_id >= 9000001;
DELETE FROM restaurants WHERE id >= 9000001;
DELETE FROM seasonal_events WHERE id >= 9000001;
DELETE FROM users WHERE id >= 9000001;

-- ──────────────────────────────────────────────
-- 테스트 사용자
-- ──────────────────────────────────────────────
INSERT INTO users (id, email, password_hash, nickname, is_resident_verified, resident_verified_at, resident_expires_at, points) VALUES
  (9000001, 'test1@byeotsseom.com',
   crypt('test1234', gen_salt('bf', 10)),
   '화성테스터',
   true,
   NOW() - INTERVAL '1 month',
   NOW() + INTERVAL '5 months',
   1500),
  (9000002, 'test2@byeotsseom.com',
   crypt('test1234', gen_salt('bf', 10)),
   '동탄미식가',
   true,
   NOW() - INTERVAL '2 months',
   NOW() + INTERVAL '4 months',
   500),
  (9000003, 'test3@byeotsseom.com',
   crypt('test1234', gen_salt('bf', 10)),
   '봉담나그네',
   false,
   NULL,
   NULL,
   0)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────
-- 음식점 (화성시 실제 주소 기반)
-- ──────────────────────────────────────────────
INSERT INTO restaurants (
  id, name, address, phone,
  lat, lng, geocode_status,
  category, is_konapay, is_mobeom,
  tags
) VALUES
  -- 동탄 지역
  (9000001, '화성순두부찌개 동탄점',
   '경기도 화성시 효행구 봉담읍 와우로 51',
   '031-5183-3939',
   37.2001, 127.0735, 'verified',
   '한식', true, true,
   ARRAY['가성비', '혼밥']),

  (9000002, '카페테리아',
   '경기도 화성시 효행구 봉담읍 와우로 72',
   '031-5183-1234',
   37.2045, 127.0780, 'verified',
   '카페', true, false,
   ARRAY['카공족', '10대 픽']),

  (9000003, '맘스터치 봉담점',
   '경기도 화성시 효행구 동화길 51',
   '031-5183-3939',
   37.1823, 127.0212, 'verified',
   '패스트푸드', true, false,
   ARRAY['가성비', '10대 픽']),

  (9000004, '동탄 육회비빔밥',
   '경기도 화성시 동탄대로 101',
   '031-8003-4567',
   37.2134, 127.0898, 'verified',
   '한식', false, true,
   ARRAY['가성비', '혼밥', '화성 로컬']),

  (9000005, '봉담 왕갈비탕',
   '경기도 화성시 봉담읍 봉담로 200',
   '031-298-5678',
   37.1820, 127.0215, 'verified',
   '한식', true, true,
   ARRAY['가성비']),

  (9000006, '향남 해물찜',
   '경기도 화성시 향남읍 발안로 55',
   '031-352-6789',
   37.1240, 126.9882, 'verified',
   '해산물', false, true,
   ARRAY['카공족', '화성 로컬']),

  (9000007, '남양 해장국',
   '경기도 화성시 남양읍 남양로 130',
   '031-356-7890',
   37.1800, 126.8905, 'verified',
   '한식', true, false,
   ARRAY['혼밥', '가성비']),

  (9000008, '동탄 스시오마카세',
   '경기도 화성시 동탄대로 556',
   '031-8004-1111',
   37.2067, 127.0721, 'verified',
   '일식', false, false,
   ARRAY['10대 픽']),

  (9000009, '황계 닭갈비',
   '경기도 화성시 황계동 황계로 88',
   '031-8003-2222',
   37.2200, 127.0560, 'verified',
   '한식', true, false,
   ARRAY['카공족', '가성비']),

  (9000010, '새솔동 편의 김밥',
   '경기도 화성시 새솔동 솔빛로 15',
   '031-8003-3333',
   37.2310, 127.0650, 'verified',
   '분식', true, false,
   ARRAY['혼밥', '가성비', '10대 픽'])

ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────
-- 식사평 (리뷰)
-- ──────────────────────────────────────────────
INSERT INTO reviews (
  id, restaurant_id, user_id,
  tags, rating, comment,
  is_receipt_verified, earned_points,
  created_at
) VALUES
  (9000001, 9000001, 9000001,
   ARRAY['가성비', '혼밥'], 5,
   '국물이 깔끔하고 순두부가 너무 맛있었습니다! 김치도 맛있어서 다음에 또 오고싶어요!!',
   true, 500,
   NOW() - INTERVAL '3 months'),

  (9000002, 9000002, 9000001,
   ARRAY['카공족', '10대 픽'], 4,
   '조용하고 분위기 좋아요. 아이스 라떼를 먹었는데 고소하고 부드러워요.',
   true, 500,
   NOW() - INTERVAL '4 months'),

  (9000003, 9000004, 9000002,
   ARRAY['혼밥', '가성비'], 5,
   '육회비빔밥이 정말 맛있어요. 재료가 신선하고 양도 많아요.',
   true, 500,
   NOW() - INTERVAL '2 months'),

  (9000004, 9000005, 9000002,
   ARRAY['가성비'], 4,
   '갈비탕 국물이 진하고 고기가 부드러워요. 점심에 딱 좋습니다.',
   false, 0,
   NOW() - INTERVAL '1 month'),

  (9000005, 9000001, 9000002,
   ARRAY['가성비', '혼밥'], 5,
   '두 번째 방문인데 역시 맛있네요. 단골이 될 것 같아요.',
   true, 500,
   NOW() - INTERVAL '2 weeks')

ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────
-- 포인트 내역
-- ──────────────────────────────────────────────
INSERT INTO point_history (id, user_id, delta, reason, created_at) VALUES
  (9000001, 9000001, 500, '식사평 작성', NOW() - INTERVAL '3 months'),
  (9000002, 9000001, 500, '식사평 작성', NOW() - INTERVAL '4 months'),
  (9000003, 9000001, 500, '주민인증 보너스', NOW() - INTERVAL '5 months'),
  (9000004, 9000001, -1000, '화성페이 전환', NOW() - INTERVAL '2 months'),
  (9000005, 9000002, 500, '식사평 작성', NOW() - INTERVAL '2 months'),
  (9000006, 9000002, 500, '식사평 작성', NOW() - INTERVAL '1 month')
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────
-- 절기·명절·축제
-- ──────────────────────────────────────────────
INSERT INTO seasonal_events (
  id, name, event_type,
  start_date, end_date,
  food_keyword, location, lat, lng, radius_km,
  description
) VALUES
  -- 절기
  (9000001, '입추', '절기',
   '2026-08-07', '2026-08-07',
   '삼계탕', NULL, NULL, NULL, NULL,
   '가을이 시작되는 절기. 삼계탕으로 더위를 이겨냅니다.'),

  (9000002, '처서', '절기',
   '2026-08-23', '2026-08-23',
   '전복죽', NULL, NULL, NULL, NULL,
   '더위가 가시는 절기. 전복죽으로 원기를 보충합니다.'),

  (9000003, '백로', '절기',
   '2026-09-08', '2026-09-08',
   '햅쌀밥', NULL, NULL, NULL, NULL,
   '이슬이 내리는 절기. 햅쌀로 지은 밥이 제격입니다.'),

  (9000004, '추석', '명절',
   '2026-09-25', '2026-09-27',
   '송편', NULL, NULL, NULL, NULL,
   '한가위 명절. 온 가족이 모여 송편을 빚습니다.'),

  (9000005, '한로', '절기',
   '2026-10-08', '2026-10-08',
   '국화전', NULL, NULL, NULL, NULL,
   '차가운 이슬이 맺히는 절기. 국화전으로 계절을 즐깁니다.'),

  -- 화성시 축제
  (9000006, '화성 뱃놀이 축제',
   '축제',
   '2026-09-12', '2026-09-14',
   '해산물', '경기도 화성시 서신면 궁평항로 1049',
   37.1620, 126.6803, 5.0,
   '궁평항에서 열리는 화성시 대표 해산물 축제.'),

  (9000007, '동탄 푸드 페스티벌',
   '축제',
   '2026-10-03', '2026-10-05',
   '길거리음식', '경기도 화성시 동탄대로 354',
   37.2067, 127.0721, 3.0,
   '동탄 광장에서 열리는 먹거리 축제. 다양한 화성 맛집이 참여합니다.'),

  (9000008, '향남 농산물 축제',
   '축제',
   '2026-10-17', '2026-10-18',
   '쌀', '경기도 화성시 향남읍 발안로 55',
   37.1240, 126.9882, 2.0,
   '향남 지역 농산물과 먹거리를 한자리에서.')

ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────
-- 확인 쿼리
-- ──────────────────────────────────────────────
SELECT '사용자' AS 테이블, COUNT(*) AS 건수 FROM users WHERE id >= 9000001
UNION ALL
SELECT '음식점', COUNT(*) FROM restaurants WHERE id >= 9000001
UNION ALL
SELECT '리뷰', COUNT(*) FROM reviews WHERE id >= 9000001
UNION ALL
SELECT '포인트 내역', COUNT(*) FROM point_history WHERE id >= 9000001
UNION ALL
SELECT '절기·축제', COUNT(*) FROM seasonal_events WHERE id >= 9000001;
