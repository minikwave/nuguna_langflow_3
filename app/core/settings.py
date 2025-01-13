import os

class Settings:
    DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./test.db")
    PROMETHEUS_PUSHGATEWAY = os.getenv("PROMETHEUS_PUSHGATEWAY", "http://localhost:9091")
    LANGFLOW_API_KEY = os.getenv("LANGFLOW_API_KEY", "your_default_api_key")

settings = Settings()
