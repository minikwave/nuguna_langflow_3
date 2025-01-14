import json

def load_workflow(workflow_path):
    with open(workflow_path, 'r') as f:
        return json.load(f)

def save_workflow(workflow_path, workflow_data):
    with open(workflow_path, 'w') as f:
        json.dump(workflow_data, f, indent=4)
