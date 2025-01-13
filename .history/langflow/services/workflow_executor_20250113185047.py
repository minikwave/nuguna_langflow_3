from app.api.services.plugin_loader import load_plugin

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
        return output
