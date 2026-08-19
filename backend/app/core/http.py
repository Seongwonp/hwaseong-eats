"""외부 API 호출 공통 처리.

수집·지오코딩이 수만 건을 도는 동안 네트워크가 한 번 끊기거나 호출 제한에 걸리면
작업 전체가 죽는다. 재시도와 백오프를 여기 모아둔다.
"""

from __future__ import annotations

import time

import httpx

RETRY_STATUSES = (429, 500, 502, 503, 504)


def request_with_retry(
    client: httpx.Client,
    method: str,
    url: str,
    *,
    retries: int = 3,
    backoff: float = 1.0,
    **kwargs,
) -> httpx.Response:
    """실패하면 지수 백오프로 재시도한다.

    429 는 Retry-After 헤더를 우선 따른다. 마지막 시도까지 실패하면 예외를 올린다.
    """
    last_exc: Exception | None = None

    for attempt in range(retries):
        wait = backoff * (2**attempt)
        try:
            res = client.request(method, url, **kwargs)
        except httpx.HTTPError as e:
            last_exc = e
            if attempt == retries - 1:
                raise
            time.sleep(wait)
            continue

        if res.status_code in RETRY_STATUSES and attempt < retries - 1:
            retry_after = res.headers.get("Retry-After")
            try:
                wait = float(retry_after) if retry_after else wait
            except ValueError:
                pass
            time.sleep(wait)
            continue

        return res

    if last_exc:
        raise last_exc
    return res
