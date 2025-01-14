from langflow_integration import execute_workflow
from vectordb_integration import VectorDBManager
from app.core.settings import settings

class PromptHandler:
    def __init__(self):
        self.use_langflow = settings.USE_LANGFLOW  # Langflow 활성화 여부
        self.vectordb_manager = VectorDBManager()  # VectorDB 인스턴스

    def handle_prompt(self, prompt: str):
        """
        Prompt 처리 로직: Langflow 또는 VectorDB 기반으로 응답 생성
        Args:
            prompt (str): 사용자 질문

        Returns:
            dict: 처리 결과
        """
        if self.use_langflow:
            # Langflow 워크플로우 실행
            workflow_data = {"workflow": {"prompt": prompt}}
            return execute_workflow(workflow_data)
        else:
            # VectorDB 기반 검색
            results = self.vectordb_manager.query(prompt)
            return {"status": "success", "results": results}
