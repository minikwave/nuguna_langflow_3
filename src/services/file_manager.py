import os
import json

PROJECTS_DIR = "data/projects"

def save_project(session_id, project_name, content):
    """Save a project JSON."""
    user_dir = os.path.join(PROJECTS_DIR, session_id)
    os.makedirs(user_dir, exist_ok=True)
    with open(os.path.join(user_dir, f"{project_name}.json"), "w") as f:
        json.dump(content, f)

def load_project(session_id, project_name):
    """Load a project JSON."""
    try:
        with open(os.path.join(PROJECTS_DIR, session_id, f"{project_name}.json"), "r") as f:
            return json.load(f)
    except FileNotFoundError:
        return {"error": f"Project {project_name} not found for session {session_id}."}

def list_projects(session_id):
    """List all project files for a session."""
    user_dir = os.path.join(PROJECTS_DIR, session_id)
    if not os.path.exists(user_dir):
        return []
    return [f[:-5] for f in os.listdir(user_dir) if f.endswith(".json")]

def delete_project(session_id, project_name):
    """Delete a project JSON."""
    try:
        os.remove(os.path.join(PROJECTS_DIR, session_id, f"{project_name}.json"))
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
