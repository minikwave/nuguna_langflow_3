import requests
from app.api.services.plugin_loader import load_plugin
from app.core.settings import settings

LANGFLOW_API_BASE = "http://localhost:7860/api/v1"


class WorkflowManager:
    def __init__(self):
        pass

    def execute_workflow(self, workflow_id: str, inputs: dict):
        """
        Langflow API를 통해 워크플로우를 실행하거나 직접 로컬에서 실행.
        Args:
            workflow_id (str): 워크플로우 ID
            inputs (dict): 워크플로우 입력값

        Returns:
            dict: 워크플로우 실행 결과 또는 오류 메시지
        """
        # 1. Langflow에서 워크플로우 로드
        workflow_data = self.load_workflow(workflow_id)
        if "error" in workflow_data:
            return workflow_data

        # 2. 노드 실행을 통한 워크플로우 처리
        output = self._process_nodes(inputs, workflow_data)

        # 3. Prometheus에 메트릭 기록
        self._push_to_prometheus(workflow_id, output)

        return {"status": "success", "output": output}

    def load_workflow(self, workflow_id: str):
        """
        Langflow 워크플로우 로드
        Args:
            workflow_id (str): 로드할 워크플로우 ID

        Returns:
            dict: 워크플로우 데이터 또는 오류 메시지
        """
        try:
            response = requests.get(f"{LANGFLOW_API_BASE}/workflows/{workflow_id}")
            if response.status_code == 200:
                return response.json()
            else:
                return {"status": "error", "message": response.text}
        except requests.exceptions.RequestException as e:
            return {"status": "error", "message": str(e)}

    def _process_nodes(self, inputs: dict, workflow_data: dict):
        """
        워크플로우 데이터를 기반으로 노드 실행
        Args:
            inputs (dict): 초기 입력값
            workflow_data (dict): Langflow에서 로드한 워크플로우 데이터

        Returns:
            dict: 실행 결과
        """
        output = inputs
        for node in workflow_data.get("nodes", []):
            plugin_path = node.get("plugin")
            plugin_class = load_plugin(plugin_path)
            if plugin_class is None:
                return {"status": "error", "message": f"Plugin not found: {plugin_path}"}
            plugin_instance = plugin_class()
            output = plugin_instance.process(output.get(node.get("input")))

        return output

    def _push_to_prometheus(self, workflow_id: str, output: dict):
        """
        Prometheus 메트릭 로깅
        Args:
            workflow_id (str): 워크플로우 ID
            output (dict): 워크플로우 결과
        """
        metrics_data = f"""
        workflow_execution_result{{workflow_id="{workflow_id}"}} {len(output)}
        """
        with open("prometheus_metrics.log", "a") as f:
            f.write(metrics_data)


# from app.api.services.plugin_loader import load_plugin
# from app.core.settings import settings

# class WorkflowExecutor:
#     def execute_workflow(self, workflow_id: str, inputs: dict, workflow_data: dict):
#         """
#         Execute a workflow based on the workflow data.
#         """
#         output = inputs
#         for node in workflow_data.get("nodes", []):
#             plugin_path = node["plugin"]
#             plugin_class = load_plugin(plugin_path)
#             plugin_instance = plugin_class()
#             output = plugin_instance.process(output.get(node["input"]))

#         # Push results to Prometheus
#         self.push_to_prometheus(workflow_id, output)

#         return output

#     def push_to_prometheus(self, workflow_id: str, output: dict):
#         """
#         Push workflow execution metrics to Prometheus.
#         """
#         metrics_data = f"""
#         workflow_execution_result{{workflow_id="{workflow_id}"}} {len(output)}
#         """
#         with open("prometheus_metrics.log", "a") as f:
#             f.write(metrics_data)
