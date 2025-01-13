from fastapi import APIRouter, HTTPException
from app.api.services.condition_parser import ConditionParser
from app.api.services.sql_executor import SQLGenerator, SQLExecutor

router = APIRouter()

@router.post("/process-prompt")
def process_prompt(prompt: str):
    """
    Process user prompt to parse conditions, generate SQL, and execute query.
    """
    parser = ConditionParser()
    conditions = parser.parse_conditions(prompt)

    generator = SQLGenerator()
    sql_query = generator.generate_sql(
        table="source_report",
        dimensions=["source_medium"],
        metrics=["regular_donation"],
        conditions=conditions
    )

    executor = SQLExecutor()
    query_result = executor.execute(sql_query)

    return {
        "sql_query": sql_query,
        "query_result": query_result
    }
