from langflow_integration import execute_workflow
from vectordb_integration import VectorDBManager
from app.core.settings import settings

class PromptHandler:
    def __init__(self):
        self.langflow_enabled = settings.USE_LANGFLOW
        self.vectordb_enabled = settings.USE_VECTORDDB
        self.hybrid_mode = settings.HYBRID_MODE
        self.vectordb_manager = VectorDBManager() if self.vectordb_enabled else None

    def handle_prompt(self, prompt: str):
        """
        Prompt 처리: Langflow, VectorDB, 또는 하이브리드 처리
        Args:
            prompt (str): 사용자 질문

        Returns:
            dict: Langflow, VectorDB 결과, 또는 둘의 조합
        """
        results = {}
        
        # Langflow 처리
        if self.langflow_enabled:
            workflow_data = {"workflow": {"prompt": prompt}}
            results["langflow_result"] = execute_workflow(workflow_data)

        # VectorDB 처리
        if self.vectordb_enabled:
            results["vectordb_results"] = self.vectordb_manager.query(prompt)

        # 하이브리드 처리 (결과 조합)
        if self.hybrid_mode:
            results["combined_results"] = self._combine_results(
                results.get("langflow_result", {}),
                results.get("vectordb_results", []),
            )

        return results

    def _combine_results(self, langflow_result, vectordb_results):
        """
        Langflow와 VectorDB 결과를 조합
        Args:
            langflow_result (dict): Langflow 결과
            vectordb_results (list): VectorDB 결과

        Returns:
            dict: 조합된 결과
        """
        return {
            "langflow": langflow_result,
            "vectordb": vectordb_results,
        }


# from langflow_integration import execute_workflow
# from vectordb_integration import VectorDBManager
# from app.core.settings import settings

# class PromptHandler:
#     def __init__(self):
#         self.use_langflow = settings.USE_LANGFLOW  # Langflow 활성화 여부
#         self.vectordb_manager = VectorDBManager()  # VectorDB 인스턴스

#     def handle_prompt(self, prompt: str):
#         """
#         Prompt 처리 로직: Langflow 또는 VectorDB 기반으로 응답 생성
#         Args:
#             prompt (str): 사용자 질문

#         Returns:
#             dict: 처리 결과
#         """
#         if self.use_langflow:
#             # Langflow 워크플로우 실행
#             workflow_data = {"workflow": {"prompt": prompt}}
#             return execute_workflow(workflow_data)
#         else:
#             # VectorDB 기반 검색
#             results = self.vectordb_manager.query(prompt)
#             return {"status": "success", "results": results}
        
# class HybridPromptHandler:
#     def __init__(self):
#         self.vectordb_manager = VectorDBManager()

#     def handle_prompt(self, prompt: str):
#         """
#         Prompt 처리: Langflow와 VectorDB 동시 활용
#         Args:
#             prompt (str): 사용자 질문

#         Returns:
#             dict: Langflow와 VectorDB 결과 조합
#         """
#         # Langflow 워크플로우 실행
#         workflow_data = {"workflow": {"prompt": prompt}}
#         langflow_result = execute_workflow(workflow_data)

#         # VectorDB 유사도 검색
#         vectordb_results = self.vectordb_manager.query(prompt)

#         # 결과 병합
#         return {
#             "langflow_result": langflow_result,
#             "vectordb_results": vectordb_results,
#         }
