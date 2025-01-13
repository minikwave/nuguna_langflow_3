from app.api.services.plugin_loader import load_plugin
from app.core.settings import settings

class WorkflowExecutor:
    def execute_workflow(self, workflow_id: str, inputs: dict, workflow_data: dict):
        """
        Execute a workflow based on the workflow data.
        """
        output = inputs
        for node in workflow_data.get("nodes", []):
            plugin_path = node["plugin"]
            plugin_class = load_plugin(plugin_path)
            plugin_instance = plugin_class()
            output = plugin_instance.process(output.get(node["input"]))

        # Push results to Prometheus
        self.push_to_prometheus(workflow_id, output)

        return output

    def push_to_prometheus(self, workflow_id: str, output: dict):
        """
        Push workflow execution metrics to Prometheus.
        """
        metrics_data = f"""
        workflow_execution_result{{workflow_id="{workflow_id}"}} {len(output)}
        """
        with open("prometheus_metrics.log", "a") as f:
            f.write(metrics_data)
