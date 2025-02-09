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

def execute_query(db_path, query, params=None):
    """
    SQL 쿼리를 실행하고 결과를 반환.
    :param db_path: 데이터베이스 파일 경로
    :param query: 실행할 SQL 쿼리
    :param params: 쿼리에 전달할 매개변수 (기본값: None)
    :return: 쿼리 결과 또는 오류 메시지
    """
    connection = sqlite3.connect(db_path)
    cursor = connection.cursor()
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        if query.strip().upper().startswith("SELECT"):
            return cursor.fetchall()  # SELECT 쿼리의 결과 반환
        else:
            connection.commit()  # INSERT, UPDATE, DELETE 쿼리의 경우 변경 사항 적용
            return "Query executed successfully"
    except Exception as e:
        return f"쿼리 실행 오류: {str(e)}"
    finally:
        connection.close()
