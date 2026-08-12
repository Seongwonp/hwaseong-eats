"""비밀번호 해싱.

MD5·SHA1 은 물론이고 SHA256 같은 범용 해시도 쓰면 안 된다. 빠른 해시는 GPU 로
초당 수십억 번 대입이 가능해서 유출 시 사실상 평문이다. bcrypt 는 의도적으로
느리고 salt 를 자동으로 붙인다.

passlib 대신 bcrypt 를 직접 쓴다. passlib 1.7.4 는 bcrypt 4.x 의 __about__ 제거를
따라가지 못해 경고를 뿜고, 유지보수도 사실상 멈춰 있다.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt
from dotenv import load_dotenv

load_dotenv()

# 12 라운드 = 검증 1회에 대략 0.2~0.3초. 로그인 지연과 무차별 대입 방어의 절충점.
ROUNDS = 12

# bcrypt 는 72바이트를 넘는 입력을 조용히 잘라낸다. 잘린 뒤에 같아지는 비밀번호가
# 생기므로 넘기지 않고 막는다.
MAX_PASSWORD_BYTES = 72


class PasswordTooLongError(ValueError):
    pass


def hash_password(password: str) -> str:
    encoded = password.encode("utf-8")
    if len(encoded) > MAX_PASSWORD_BYTES:
        raise PasswordTooLongError(
            f"비밀번호는 {MAX_PASSWORD_BYTES}바이트를 넘을 수 없습니다"
        )
    return bcrypt.hashpw(encoded, bcrypt.gensalt(rounds=ROUNDS)).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    """해시가 깨져 있어도 예외를 올리지 않고 False 를 준다."""
    try:
        return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False


# ── 액세스 토큰 ──────────────────────────────────────────────

JWT_ALGORITHM = "HS256"
TOKEN_TTL = timedelta(days=14)  # 해커톤 데모라 길게 잡는다. 갱신 흐름을 안 만들기 위함


def _secret() -> str:
    secret = os.getenv("JWT_SECRET")
    if not secret:
        raise RuntimeError("JWT_SECRET 이 없습니다. backend/.env 를 확인하세요.")
    return secret


def create_access_token(user_id: int) -> str:
    now = datetime.now(timezone.utc)
    payload = {"sub": str(user_id), "iat": now, "exp": now + TOKEN_TTL}
    return jwt.encode(payload, _secret(), algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> int | None:
    """유효하면 user_id, 아니면 None. 만료·위조를 구분해서 알려주지 않는다."""
    try:
        payload = jwt.decode(token, _secret(), algorithms=[JWT_ALGORITHM])
        return int(payload["sub"])
    except (jwt.InvalidTokenError, KeyError, ValueError):
        return None
