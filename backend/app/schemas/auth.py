from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator


def _normalize_email(value: str) -> str:
    """대소문자만 다른 주소로 계정이 갈라지는 걸 막는다.

    RFC 상 local part 는 대소문자를 구분하지만 실제로 구분해서 쓰는 메일 서비스는 없다.
    """
    return value.strip().lower()


def _normalize_nickname(value: str) -> str:
    return value.strip()


class SignupRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)
    nickname: str = Field(min_length=2, max_length=10)

    _norm_email = field_validator("email")(lambda cls, v: _normalize_email(v))
    _norm_nick = field_validator("nickname", mode="before")(
        lambda cls, v: _normalize_nickname(v) if isinstance(v, str) else v
    )


class LoginRequest(BaseModel):
    email: EmailStr
    password: str

    _norm = field_validator("email")(lambda cls, v: _normalize_email(v))


class KakaoLoginRequest(BaseModel):
    access_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class NicknameUpdateRequest(BaseModel):
    nickname: str = Field(min_length=2, max_length=10)

    _norm_nick = field_validator("nickname", mode="before")(
        lambda cls, v: _normalize_nickname(v) if isinstance(v, str) else v
    )


class UserResponse(BaseModel):
    id: int
    email: str | None  # 카카오 전용 계정은 이메일이 없을 수 있다
    nickname: str
    is_resident_verified: bool
    resident_expires_at: datetime | None
    points: int

    model_config = {"from_attributes": True}
