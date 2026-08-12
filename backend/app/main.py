from fastapi import Depends, FastAPI, Response, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from sqlalchemy.orm import Session
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.ratelimit import limiter
from app.database import get_db
from app.routers import auth, festivals, restaurants, reviews

app = FastAPI(title="화성 먹거리 지도 API")

# 인증 엔드포인트에 @limiter.limit 을 붙이려면 앱에 limiter 가 물려 있어야 한다.
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Flutter 앱·웹에서 붙는다. 배포 시 도메인으로 좁힐 것.
# 와일드카드와 allow_credentials=True 는 브라우저가 거부하는 조합이라 같이 못 쓴다.
# 쿠키 기반 인증을 붙이게 되면 allow_origins 를 실제 도메인으로 바꾸고 credentials 를 켠다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(restaurants.router, prefix="/restaurants", tags=["restaurants"])
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
app.include_router(festivals.router, prefix="/festivals", tags=["festivals"])


@app.get("/health")
def health(response: Response, db: Session = Depends(get_db)):
    """DB 연결까지 확인한다.

    앱만 살아 있고 DB 가 죽은 상태는 서비스가 안 되는 것과 같은데, 쿼리를 안 해보면
    200 을 돌려주게 되어 장애를 못 잡는다. Render 헬스체크도 이 경로를 본다.
    """
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "degraded", "database": "unreachable"}

    return {"status": "ok", "database": "ok"}
