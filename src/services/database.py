import sqlite3
from app.config import Config

def initialize_database(db_path):
    """
    샘플 데이터베이스를 초기화.
    """
    connection = sqlite3.connect(db_path)
    cursor = connection.cursor()
    try:
        cursor.executescript("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            age INTEGER
        );
        INSERT INTO users (name, age) VALUES ('Alice', 25), ('Bob', 30), ('Charlie', 35);
        """)
        connection.commit()
    except Exception as e:
        print(f"Database 초기화 오류: {str(e)}")
    finally:
        connection.close()

def get_db_status(db_path):
    """
    데이터베이스 연결 상태 확인.
    """
    try:
        connection = sqlite3.connect(db_path)
        connection.cursor().execute("SELECT 1;")
        return "Connected"
    except Exception as e:
        return f"오류: {str(e)}"
    finally:
        connection.close()
