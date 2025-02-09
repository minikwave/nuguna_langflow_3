from typing import Dict, Any
import sqlite3
from langflow import CustomComponent

class SQLValidator(CustomComponent):
    display_name = "SQL Validator"
    description = "Validates and executes SQL queries"

    def __init__(self):
        super().__init__()
        self.database_url = None

    def build_config(self) -> Dict[str, Any]:
        return {
            "database_url": {
                "type": "string",
                "required": True,
                "placeholder": "sqlite:///path/to/db.sqlite"
            },
            "max_rows": {
                "type": "integer",
                "default": 100,
                "required": False
            }
        }

    async def execute(self, query: str, params: Dict[str, Any] = None) -> Dict[str, Any]:
        try:
            conn = sqlite3.connect(self.database_url)
            cursor = conn.cursor()
            
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            columns = [description[0] for description in cursor.description]
            rows = cursor.fetchall()
            
            return {
                "success": True,
                "columns": columns,
                "rows": rows,
                "row_count": len(rows)
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
        finally:
            conn.close() 