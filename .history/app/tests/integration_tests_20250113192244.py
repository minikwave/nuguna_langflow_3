from app.api.controllers.prompt_controller import process_prompt

def test_full_workflow_execution():
    """
    Test the full workflow execution from condition parsing to SQL execution.
    """
    prompt = "2024년 12월 소스/매체가 'google'인 정기후원 총액을 알려줘."
    result = process_prompt(prompt)
    assert "sql_query" in result, "SQL query missing"
    assert "query_result" in result, "Query result missing"
    print("Integration test passed!")
