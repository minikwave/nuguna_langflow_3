import sqlite3

def validate_sql(query):
    if "DROP" in query.upper():
        raise ValueError("위험한 SQL 쿼리입니다.")
    return query

def execute_query(query, db_path):
    connection = sqlite3.connect(db_path)
    cursor = connection.cursor()
    try:
        cursor.execute(query)
        return cursor.fetchall()
    except Exception as e:
        return f"쿼리 오류: {str(e)}"
    finally:
        connection.close()
