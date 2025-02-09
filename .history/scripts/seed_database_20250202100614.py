from sqlalchemy import create_engine
from sqlalchemy.sql import text
import os
from dotenv import load_dotenv

load_dotenv()

def seed_database():
    """초기 데이터 생성"""
    engine = create_engine(os.getenv('DATABASE_URL'))
    
    with engine.connect() as conn:
        # 예제 데이터 삽입
        conn.execute(text("""
        -- 여기에 초기 데이터 SQL 작성
        INSERT INTO users (username, email) 
        VALUES ('admin', 'admin@example.com');
        """))
        conn.commit()

if __name__ == "__main__":
    seed_database() 