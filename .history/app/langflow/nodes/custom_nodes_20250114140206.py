from langflow.interface import Node

class CustomSQLNode(Node):
    def execute(self, params):
        query = f"SELECT * FROM {params['table']} WHERE {params['condition']}"
        return {"query": query}

class CustomReportNode(Node):
    def execute(self, params):
        return {"report": f"Generated report for {params['target']}"}
