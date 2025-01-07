from flask import request, jsonify, render_template
from app.services.langflow_service import call_langflow, call_playground
from app.services.database import execute_query
from app.services.file_manager import save_json, load_json, delete_json, list_json_files
from app.services.admin_service import get_system_status
from app.services.flow_manager import save_flow, load_flow, list_flows, delete_flow

def init_routes(app):
    @app.route("/kakao", methods=["POST"])
    def kakao_webhook():
        data = request.get_json()
        user_input = data.get("userRequest", {}).get("utterance", "")
        session_id = data.get("session_id", "default_session")
        
        # Langflow 호출
        sql_query = call_langflow(user_input, session_id)
        result = execute_query(sql_query)
        return jsonify({"response": result})

    @app.route("/projects", methods=["GET"])
    def list_projects():
        projects = list_json_files()
        return jsonify({"projects": projects})

    @app.route("/projects/<name>", methods=["GET"])
    def load_project(name):
        project = load_json(name)
        return jsonify(project)

    @app.route("/projects", methods=["POST"])
    def save_project():
        data = request.get_json()
        project_name = data.get("name")
        content = data.get("content")
        save_json(project_name, content)
        return jsonify({"message": f"Project {project_name} saved successfully."})

    @app.route("/projects/<name>", methods=["DELETE"])
    def delete_project(name):
        delete_json(name)
        return jsonify({"message": f"Project {name} deleted successfully."})

    @app.route("/admin", methods=["GET"])
    def admin_page():
        status = get_system_status()
        projects = list_json_files()
        return render_template("admin_template.html", status=status, projects=projects)
    
    @app.route("/playground", methods=["GET", "POST"])
    def playground():
        if request.method == "POST":
            data = request.get_json()
            input_text = data.get("input_text")
            session_id = data.get("session_id", "default_session")
            flow_id = data.get("flow_id", "default_flow")
            api_key = data.get("api_key", None)

            # Langflow API 호출
            result = call_playground(input_text, session_id, flow_id, api_key)
            return jsonify(result)

        # Playground GUI 렌더링
        return render_template("playground.html")
    
        @app.route("/flows/<user_id>", methods=["GET"])
    def get_user_flows(user_id):
        """사용자 Flow 목록 조회."""
        flows = list_flows(user_id)
        return jsonify({"flows": flows})

    @app.route("/flows/<user_id>/<flow_name>", methods=["GET"])
    def get_user_flow(user_id, flow_name):
        """특정 Flow 로드."""
        flow = load_flow(user_id, flow_name)
        return jsonify(flow)

    @app.route("/flows/<user_id>", methods=["POST"])
    def save_user_flow(user_id):
        """새 Flow 저장."""
        data = request.get_json()
        flow_name = data.get("name")
        flow_content = data.get("content")
        file_path = save_flow(user_id, flow_name, flow_content)
        return jsonify({"message": f"Flow saved at {file_path}"})

    @app.route("/flows/<user_id>/<flow_name>", methods=["DELETE"])
    def delete_user_flow(user_id, flow_name):
        """Flow 삭제."""
        delete_flow(user_id, flow_name)
        return jsonify({"message": f"Flow {flow_name} deleted."})
    
# from flask import request, jsonify, render_template
# from app.utils.kakao_template import create_kakao_response
# from app.services.langflow_service import call_langflow
# from app.services.database import execute_query
# from app.services.admin_service import get_system_status

# def init_routes(app):
#     @app.route("/kakao", methods=["POST"])
#     def kakao_webhook():
#         data = request.get_json()
#         user_input = data.get("userRequest", {}).get("utterance", "")
#         sql_query = call_langflow(user_input)
#         result = execute_query(sql_query)
#         response = create_kakao_response(result)
#         return jsonify(response)

#     @app.route("/admin", methods=["GET"])
#     def admin_page():
#         status = get_system_status()
#         return render_template("admin_template.html", status=status)
