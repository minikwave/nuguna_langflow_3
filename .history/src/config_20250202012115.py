import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Database
    SQLALCHEMY_DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///data/app.db')
    
    # Langflow
    LANGFLOW_API_URL = os.getenv('LANGFLOW_API_URL', 'http://localhost:7860')
    LANGFLOW_SUPERUSER = os.getenv('LANGFLOW_SUPERUSER', 'admin')
    LANGFLOW_SUPERUSER_PASSWORD = os.getenv('LANGFLOW_SUPERUSER_PASSWORD', 'admin')
    LANGFLOW_APPLICATION_TOKEN = os.getenv('LANGFLOW_APPLICATION_TOKEN')
    
    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = int(os.getenv('JWT_ACCESS_TOKEN_EXPIRES', 3600)) 