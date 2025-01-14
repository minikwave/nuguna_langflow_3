from prometheus_client import Counter, Summary

# 메트릭 정의
REQUEST_COUNT = Counter("request_count", "Number of processed requests")
REQUEST_LATENCY = Summary("request_latency_seconds", "Latency of requests in seconds")

def increment_request_count():
    """요청 수 증가"""
    REQUEST_COUNT.inc()

def observe_request_latency(latency: float):
    """요청 지연 시간 기록"""
    REQUEST_LATENCY.observe(latency)
