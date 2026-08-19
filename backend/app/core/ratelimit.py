"""요청 제한.

로그인·회원가입은 무차별 대입 표적이라 IP 단위로 횟수를 묶어둔다.
엔드포인트에 @limiter.limit(LOGIN_LIMIT) 을 붙여 쓴다.

주의: 기본 저장소가 프로세스 메모리라 워커를 여러 개 띄우면 워커마다 따로 센다.
Render 에서 인스턴스를 늘리게 되면 Redis 백엔드로 바꿔야 한다.
"""

from __future__ import annotations

from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

# 로그인 실패를 반복해서 비밀번호를 찾아내는 걸 막는 선.
LOGIN_LIMIT = "5/minute"
SIGNUP_LIMIT = "3/minute"

# 포인트 전환은 잔액을 실제로 깎는다. 실수든 악의든 연타를 막는다.
EXCHANGE_LIMIT = "10/minute"

# 닉네임 변경 — DB 쓰기 연타 방지
NICKNAME_LIMIT = "10/minute"

# 주민인증 — 호출마다 인증 만료일을 6개월 뒤로 미룬다. 연타를 막는다.
VERIFY_LIMIT = "5/minute"
