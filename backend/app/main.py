import os

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

# Flutter 앱·웹에서 붙는다.
#
# 네이티브 앱은 Origin 헤더를 안 보내므로 이 목록과 무관하게 동작한다. 여기서 거르는 건
# 브라우저에서 뜨는 웹 빌드뿐이다. Netlify 배포 미리보기는 서브도메인이 매번 달라서
# 정규식으로 함께 허용한다.
#
# 와일드카드와 allow_credentials=True 는 브라우저가 거부하는 조합이라 같이 못 쓴다.
# 쿠키 기반 인증을 붙이게 되면 credentials 를 켜고 이 목록만 남긴다.
#
# 급하면 CORS_ORIGINS 환경변수로 덮어쓸 수 있다(쉼표 구분, `*` 면 전면 허용).
_DEFAULT_ORIGINS = [
    "https://hwaseong-eats-98716.netlify.app",
    "https://seongwonp.github.io",
    "http://localhost:8080",   # flutter run -d chrome 기본 포트대
    "http://localhost:3000",
    "http://127.0.0.1:8080",
]
_configured = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
_origins = _configured or _DEFAULT_ORIGINS

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if "*" in _origins else _origins,
    # deploy-preview-3--hwaseong-eats-98716.netlify.app 같은 미리보기 도메인
    allow_origin_regex=r"https://[a-z0-9-]+--hwaseong-eats-98716\.netlify\.app",
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
