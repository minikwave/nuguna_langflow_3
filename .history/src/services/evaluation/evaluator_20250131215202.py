from typing import Dict, Any, List
from datetime import datetime
import json
import sqlite3
from ..langflow.client import LangflowClient

class PromptEvaluator:
    def __init__(self, db_path: str):
        self.db_path = db_path
        self.langflow_client = LangflowClient()

    async def evaluate_prompt(self, 
                            flow_id: str, 
                            prompt: str, 
                            expected_sql: str,
                            test_cases: List[Dict[str, Any]] = None) -> Dict[str, Any]:
        """
        평가 메트릭:
        1. SQL 구문 정확성
        2. 실행 시간
        3. 결과 일치도
        4. 에러 발생 여부
        """
        start_time = datetime.now()
        
        try:
            # Langflow 실행
            result = await self.langflow_client.execute_flow(
                flow_id=flow_id,
                inputs={"prompt": prompt}
            )
            
            execution_time = (datetime.now() - start_time).total_seconds()
            
            # SQL 구문 분석
            generated_sql = result.get("generated_sql", "")
            sql_accuracy = self._compare_sql(generated_sql, expected_sql)
            
            # 테스트 케이스 실행
            test_results = []
            if test_cases:
                test_results = self._run_test_cases(generated_sql, test_cases)
            
            evaluation_result = {
                "prompt": prompt,
                "generated_sql": generated_sql,
                "expected_sql": expected_sql,
                "execution_time": execution_time,
                "sql_accuracy": sql_accuracy,
                "test_results": test_results,
                "error": None,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            evaluation_result = {
                "prompt": prompt,
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
        
        # 결과 저장
        self._save_evaluation_result(evaluation_result)
        
        return evaluation_result

    def _compare_sql(self, generated_sql: str, expected_sql: str) -> float:
        """SQL 구문 유사도 비교"""
        # TODO: 구현 필요 - 현재는 간단한 문자열 비교만 수행
        if generated_sql.lower() == expected_sql.lower():
            return 1.0
        return 0.0

    def _run_test_cases(self, sql: str, test_cases: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """테스트 케이스 실행"""
        results = []
        
        with sqlite3.connect(self.db_path) as conn:
            for test_case in test_cases:
                try:
                    cursor = conn.cursor()
                    cursor.execute(sql)
                    actual_result = cursor.fetchall()
                    
                    results.append({
                        "test_case": test_case,
                        "success": True,
                        "actual_result": actual_result,
                        "error": None
                    })
                except Exception as e:
                    results.append({
                        "test_case": test_case,
                        "success": False,
                        "actual_result": None,
                        "error": str(e)
                    })
                
        return results

    def _save_evaluation_result(self, result: Dict[str, Any]):
        """평가 결과를 데이터베이스에 저장"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # 테이블이 없으면 생성
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS evaluation_results (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    prompt TEXT,
                    generated_sql TEXT,
                    expected_sql TEXT,
                    execution_time REAL,
                    sql_accuracy REAL,
                    test_results TEXT,
                    error TEXT,
                    timestamp DATETIME
                )
            """)
            
            cursor.execute("""
                INSERT INTO evaluation_results 
                (prompt, generated_sql, expected_sql, execution_time, sql_accuracy, test_results, error, timestamp)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                result["prompt"],
                result.get("generated_sql"),
                result.get("expected_sql"),
                result.get("execution_time"),
                result.get("sql_accuracy"),
                json.dumps(result.get("test_results")),
                result.get("error"),
                result["timestamp"]
            ))
            
            conn.commit() 