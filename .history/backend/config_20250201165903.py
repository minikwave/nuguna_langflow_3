import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SQLALCHEMY_DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///data/app.db')
    LANGFLOW_API_URL = os.getenv('LANGFLOW_API_URL', 'http://localhost:7860')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = 3600  # 1시간 