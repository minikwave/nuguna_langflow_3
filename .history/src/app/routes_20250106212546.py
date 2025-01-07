from flask import request, jsonify, render_template
from app.utils.kakao_template import create_kakao_response
from app.services.langflow_service import call_langflow
from app.services.database import execute_query
from app.services.admin_service import get_system_status

def init_routes(app):
    @app.route("/kakao", methods=["POST"])
    def kakao_webhook():
        data = request.get_json()
        user_input = data.get("userRequest", {}).get("utterance", "")
        sql_query = call_langflow(user_input)
        result = execute_query(sql_query)
        response = create_kakao_response(result)
        return jsonify(response)

    @app.route("/admin", methods=["GET"])
    def admin_page():
        status = get_system_status()
        return render_template("admin_template.html", status=status)
