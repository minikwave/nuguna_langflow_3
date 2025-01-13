from app.core.database import Base, engine, SessionLocal
from app.models.table_schema import TableSchema
from app.models.rule import Rule
from app.models.workflow import Workflow

def initialize_database():
    """
    Initialize the database by creating tables and inserting initial data.
    """
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # 초기 테이블 스키마 데이터 삽입
        table_schemas = [
            TableSchema(
                table_name="source_report",
                schema={
                    "event_date": "STRING",
                    "source_medium": "STRING",
                    "regular_donation": "INT64",
                    "temporary_donation": "INT64",
                    "begin_checkout": "INT64",
                    "session": "INT64"
                }
            ),
            TableSchema(
                table_name="page_report",
                schema={
                    "event_date": "STRING",
                    "page_title": "STRING",
                    "pageview": "INT64",
                    "average_engagement_time_per_user": "FLOAT64"
                }
            )
        ]
        db.add_all(table_schemas)

        # 초기 룰 데이터 삽입
        rules = [
            Rule(
                rule_id="rule_1",
                keywords=["정기후원", "일시후원"],
                table="source_report",
                dimensions=["event_date"],
                metrics=["regular_donation", "temporary_donation"]
            ),
            Rule(
                rule_id="rule_2",
                keywords=["소스/매체", "전환율"],
                table="source_report",
                dimensions=["source_medium"],
                metrics=["begin_checkout", "session"]
            )
        ]
        db.add_all(rules)

        # 초기 워크플로우 데이터 삽입
        workflows = [
            Workflow(
                id="condition-workflow",
                name="Condition-Based Query Workflow",
                description="워크플로우 조건에 따라 SQL을 생성하고 실행.",
                workflow_data={
                    "nodes": [
                        {"id": "1", "type": "Prompt Input", "output": "prompt"},
                        {"id": "2", "type": "Condition Parser", "plugin": "app.api.services.condition_parser.ConditionParser", "input": "prompt", "output": ["table", "dimensions", "metrics", "conditions"]},
                        {"id": "3", "type": "SQL Generator", "plugin": "app.api.services.sql_executor.SQLGenerator", "input": ["table", "dimensions", "metrics", "conditions"], "output": "sql_query"},
                        {"id": "4", "type": "SQL Executor", "plugin": "app.api.services.sql_executor.SQLExecutor", "input": "sql_query", "output": "query_result"}
                    ]
                }
            )
        ]
        db.add_all(workflows)

        db.commit()
        print("Database initialized with tables and initial data.")
    finally:
        db.close()

if __name__ == "__main__":
    initialize_database()
