from app.api.services.sql_executor import SQLGenerator, SQLExecutor

def test_sql_generation():
    """
    Test SQL query generation.
    """
    generator = SQLGenerator()
    sql_query = generator.generate_sql(
        table="source_report",
        dimensions=["source_medium"],
        metrics=["regular_donation"],
        conditions={"event_date": "2024-12"}
    )
    expected_sql = """
    SELECT source_medium, SUM(regular_donation) AS total_regular
    FROM source_report
    WHERE event_date = '2024-12'
    GROUP BY source_medium;
    """
    assert sql_query.strip() == expected_sql.strip(), "SQL generation failed"

def test_sql_execution():
    """
    Test SQL query execution.
    """
    executor = SQLExecutor()
    sql_query = """
    SELECT source_medium, SUM(regular_donation) AS total_regular
    FROM source_report
    WHERE event_date = '2024-12'
    GROUP BY source_medium;
    """
    result = executor.execute(sql_query)
    assert isinstance(result, list), "Execution result should be a list"
