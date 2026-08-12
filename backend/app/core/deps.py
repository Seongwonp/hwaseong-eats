"""요청에서 로그인한 사용자를 꺼내는 의존성."""

from __future__ import annotations

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_access_token
from app.database import get_db
from app.models import User

# auto_error=False 로 두면 헤더가 없을 때도 여기서 401 문구를 통일해 줄 수 있다.
bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "로그인이 필요합니다")

    user_id = decode_access_token(credentials.credentials)
    if user_id is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "토큰이 유효하지 않습니다")

    user = db.get(User, user_id)
    if user is None:
        # 토큰은 멀쩡한데 계정이 사라진 경우
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "계정을 찾을 수 없습니다")
    return user


def require_verified_resident(user: User = Depends(get_current_user)) -> User:
    """화성 주민 인증이 살아 있어야 통과. 리뷰 작성·리워드에 건다."""
    from datetime import datetime, timezone

    if not user.is_resident_verified:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "화성주민 인증이 필요합니다")

    expires = user.resident_expires_at
    if expires and expires < datetime.now(timezone.utc):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "화성주민 인증이 만료되었습니다. 다시 인증해 주세요"
        )
    return user
