from app.langflow.services.workflow_executor import WorkflowExecutor

def test_langflow_workflow_execution():
    """
    Test LangFlow workflow execution from condition parsing to SQL generation and execution.
    """
    # 가상 워크플로우 데이터
    workflow_data = {
        "id": "condition-workflow",
        "nodes": [
            {
                "id": "1",
                "type": "Prompt Input",
                "output": "prompt"
            },
            {
                "id": "2",
                "type": "Condition Parser",
                "plugin": "app.api.services.condition_parser.ConditionParser",
                "input": "prompt",
                "output": ["table", "dimensions", "metrics", "conditions"]
            },
            {
                "id": "3",
                "type": "SQL Generator",
                "plugin": "app.api.services.sql_executor.SQLGenerator",
                "input": ["table", "dimensions", "metrics", "conditions"],
                "output": "sql_query"
            },
            {
                "id": "4",
                "type": "SQL Executor",
                "plugin": "app.api.services.sql_executor.SQLExecutor",
                "input": "sql_query",
                "output": "query_result"
            }
        ]
    }

    # 워크플로우 실행
    executor = WorkflowExecutor()
    inputs = {"prompt": "2024년 12월 정기후원 총액을 알려줘."}
    result = executor.execute_workflow("condition-workflow", inputs, workflow_data)

    # 검증
    assert "query_result" in result, "Workflow execution failed"
    assert result["query_result"], "No results returned from workflow"
    print("LangFlow workflow test passed!")
