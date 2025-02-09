import os
import json

PROJECTS_DIR = "data/projects"

def save_json(name, content):
    """Save a project JSON."""
    if not os.path.exists(PROJECTS_DIR):
        os.makedirs(PROJECTS_DIR)
    with open(os.path.join(PROJECTS_DIR, f"{name}.json"), "w") as f:
        json.dump(content, f)

def load_json(name):
    """Load a project JSON."""
    try:
        with open(os.path.join(PROJECTS_DIR, f"{name}.json"), "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"error": f"Project {name} not found."}

def list_json_files():
    """List all project files."""
    if not os.path.exists(PROJECTS_DIR):
        return []
    return [f[:-5] for f in os.listdir(PROJECTS_DIR) if f.endswith(".json")]

def delete_json(name):
    """Delete a project JSON."""
    try:
        os.remove(os.path.join(PROJECTS_DIR, f"{name}.json"))
    except FileNotFoundError:
        pass


# import os
# import json

# PROJECTS_DIR = "data/projects"

# def save_json(name, content):
#     if not os.path.exists(PROJECTS_DIR):
#         os.makedirs(PROJECTS_DIR)
#     with open(os.path.join(PROJECTS_DIR, f"{name}.json"), "w") as f:
#         json.dump(content, f)

# def load_json(name):
#     try:
#         with open(os.path.join(PROJECTS_DIR, f"{name}.json"), "r") as f:
#             return json.load(f)
#     except FileNotFoundError:
#         return {"error": f"Project {name} not found."}

# def delete_json(name):
#     try:
#         os.remove(os.path.join(PROJECTS_DIR, f"{name}.json"))
#     except FileNotFoundError:
#         pass

# def list_json_files():
#     if not os.path.exists(PROJECTS_DIR):
#         return []
#     return [f[:-5] for f in os.listdir(PROJECTS_DIR) if f.endswith(".json")]
