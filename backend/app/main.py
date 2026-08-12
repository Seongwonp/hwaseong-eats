from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.core.ratelimit import limiter
from app.routers import auth, restaurants, reviews

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


@app.get("/health")
def health():
    return {"status": "ok"}
