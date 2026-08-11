from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="화성 먹거리 지도 API")

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


@app.get("/health")
def health():
    return {"status": "ok"}
