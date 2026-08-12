from datetime import datetime

from pydantic import BaseModel, Field


class SignupRequest(BaseModel):
    login_id: str = Field(min_length=4, max_length=50, pattern=r"^[a-zA-Z0-9_]+$")
    password: str = Field(min_length=8, max_length=72)
    nickname: str = Field(min_length=2, max_length=10)


class LoginRequest(BaseModel):
    login_id: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    id: int
    login_id: str
    nickname: str
    is_resident_verified: bool
    resident_expires_at: datetime | None
    points: int

    model_config = {"from_attributes": True}
