import sqlite3

class SQLGenerator:
    def generate_sql(self, table: str, dimensions: list, metrics: list, conditions: dict):
        """
        Generate SQL query based on table, dimensions, metrics, and conditions.
        """
        dimension_clause = ", ".join(dimensions)
        metric_clause = ", ".join([f"SUM({metric}) AS total_{metric}" for metric in metrics])
        condition_clause = " AND ".join([f"{key} = '{value}'" for key, value in conditions.items()])

        sql_query = f"""
        SELECT {dimension_clause}, {metric_clause}
        FROM {table}
        WHERE {condition_clause}
        GROUP BY {dimension_clause};
        """
        return sql_query

class SQLExecutor:
    def execute(self, sql_query: str):
        """
        Execute the SQL query and return the results.
        """
        conn = sqlite3.connect("test.db")
        cursor = conn.cursor()
        cursor.execute(sql_query)
        columns = [desc[0] for desc in cursor.description]
        results = [dict(zip(columns, row)) for row in cursor.fetchall()]
        conn.close()
        return results
