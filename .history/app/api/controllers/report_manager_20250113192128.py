from fastapi import APIRouter, HTTPException, Depends
from app.api.services.sql_executor import SQLGenerator, SQLExecutor
from app.models.rule import Rule
from app.core.database import get_db_session
from sqlalchemy.orm import Session
from app.core.database import get_db_session


router = APIRouter()

@router.post("/report-data")
def extract_report_data(report_type: str, dimensions: list, metrics: list, filters: dict, db: Session = Depends(get_db_session)):
    """
    Extract report data for the given report type.
    """
    # 룰로부터 테이블 확인
    rule = db.query(Rule).filter(Rule.table == report_type).first()
    if not rule:
        raise HTTPException(status_code=404, detail="Report type not found.")

    generator = SQLGenerator()
    sql_query = generator.generate_sql(
        table=rule.table,
        dimensions=dimensions,
        metrics=metrics,
        conditions=filters
    )

    executor = SQLExecutor()
    query_result = executor.execute(sql_query)

    return {
        "sql_query": sql_query,
        "query_result": query_result
    }
