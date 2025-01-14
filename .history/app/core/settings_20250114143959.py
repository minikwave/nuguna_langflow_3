import os

class Settings:
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")
    PROMETHEUS_PUSHGATEWAY = os.getenv("PROMETHEUS_PUSHGATEWAY", "http://localhost:9091")
    LANGFLOW_API_KEY = os.getenv("LANGFLOW_API_KEY", "your_default_api_key")
    LANGFLOW_API_BASE = "http://localhost:7860/api/v1"
    PROMETHEUS_METRICS_LOG = "prometheus_metrics.log"
    PLUGIN_BASE_PATH = "example.plugins"
    USE_LANGFLOW = True  # True면 Langflow 사용, False면 VectorDB 사용

settings = Settings()
