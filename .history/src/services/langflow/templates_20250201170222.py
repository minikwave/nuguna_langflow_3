from typing import Dict, Any

def create_sql_flow_template() -> Dict[str, Any]:
    """Text-to-SQL 변환을 위한 기본 워크플로우 템플릿"""
    return {
        "name": "Text to SQL Converter",
        "description": "Natural language to SQL query converter",
        "data": {
            "nodes": [
                {
                    "id": "prompt",
                    "type": "PromptTemplate",
                    "position": {"x": 100, "y": 100},
                    "data": {
                        "template": """Given the following question, generate a SQL query:
                        Question: {question}
                        Database schema:
                        {schema}
                        
                        SQL Query:"""
                    }
                },
                {
                    "id": "llm",
                    "type": "LLMChain",
                    "position": {"x": 300, "y": 100},
                    "data": {
                        "model_name": "gpt-3.5-turbo",
                        "temperature": 0
                    }
                },
                {
                    "id": "sql_validator",
                    "type": "SQLValidator",
                    "position": {"x": 500, "y": 100},
                    "data": {
                        "database_url": "{database_url}"
                    }
                }
            ],
            "edges": [
                {
                    "source": "prompt",
                    "target": "llm",
                    "id": "edge-1"
                },
                {
                    "source": "llm",
                    "target": "sql_validator",
                    "id": "edge-2"
                }
            ]
        }
    } 