import os

class Settings:
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")
    PROMETHEUS_PUSHGATEWAY = os.getenv("PROMETHEUS_PUSHGATEWAY", "http://localhost:9091")
    LANGFLOW_API_KEY = os.getenv("LANGFLOW_API_KEY", "your_default_api_key")
    LANGFLOW_API_BASE = os.getenv("LANGFLOW_API_BASE", "http://localhost:7860/api/v1")
    PROMETHEUS_METRICS_LOG = "prometheus_metrics.log"
    PLUGIN_BASE_PATH = "example.plugins"

    # 모드 설정
    USE_LANGFLOW = os.getenv("USE_LANGFLOW", "true").lower() == "true"
    USE_VECTORDDB = os.getenv("USE_VECTORDB", "true").lower() == "true"
    HYBRID_MODE = USE_LANGFLOW and USE_VECTORDDB  # 둘 다 활성화된 경우 하이브리드 모드

settings = Settings()
