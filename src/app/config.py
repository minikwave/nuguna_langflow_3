import os

class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "supersecretkey")
    DATABASE_1_URI = os.getenv("DATABASE_1_URI", "sqlite:///data/sample_db_1.db")
    DATABASE_2_URI = os.getenv("DATABASE_2_URI", "sqlite:///data/sample_db_2.db")
    LANGFLOW_API_URL = os.getenv("LANGFLOW_API_URL", "http://localhost:7860")
    KAKAO_API_KEY = os.getenv("KAKAO_API_KEY", "your_kakao_api_key")
    LOG_FILE = os.getenv("LOG_FILE", "logs/app.log")
