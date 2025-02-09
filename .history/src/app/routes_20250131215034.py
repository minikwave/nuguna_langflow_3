from flask import Blueprint, request, jsonify, render_template
from services.langflow_service import call_langflow, call_playground, enable_auto_saving, disable_auto_saving
from services.database import execute_query
from services.file_manager import save_json, load_json, delete_json, list_json_files
from services.admin_service import get_system_status
from services.flow_manager import save_flow, load_flow, list_flows, delete_flow
from services.evaluation.evaluator import PromptEvaluator
from services.langflow.client import LangflowClient
import os
import json

api = Blueprint('api', __name__)
evaluator = PromptEvaluator(os.getenv('DB_PATH', 'data/evaluation.db'))
langflow_client = LangflowClient()

def init_routes(app):
    # Index route
    @app.route("/")
    def index():
        return "Hello, World!"

    # Kakao webhook
    @app.route("/kakao", methods=["POST"])
    def kakao_webhook():
        try:
            data = request.get_json()
            user_input = data.get("userRequest", {}).get("utterance", "")
            session_id = data.get("session_id", "default_session")
            
            # Langflow 호출
            sql_query = call_langflow(user_input, session_id)
            result = execute_query(sql_query)
            return jsonify({"response": result})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    # Projects API
    @app.route("/projects", methods=["GET"])
    def list_projects():
        try:
            projects = list_json_files()
            return jsonify({"projects": projects})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/projects/<name>", methods=["GET"])
    def load_project(name):
        try:
            project = load_json(name)
            return jsonify(project)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/projects", methods=["POST"])
    def save_project():
        try:
            data = request.get_json()
            project_name = data.get("name")
            content = data.get("content")
            save_json(project_name, content)
            return jsonify({"message": f"Project {project_name} saved successfully."})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/projects/<name>", methods=["DELETE"])
    def delete_project(name):
        try:
            delete_json(name)
            return jsonify({"message": f"Project {name} deleted successfully."})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    # Admin page
    @app.route("/admin", methods=["GET"])
    def admin_page():
        try:
            status = get_system_status()
            projects = list_json_files()
            return render_template("admin_template.html", status=status, projects=projects)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    # Playground API
    @app.route("/playground", methods=["GET", "POST"])
    def playground():
        if request.method == "POST":
            try:
                data = request.get_json()
                input_text = data.get("input_text")
                session_id = data.get("session_id", "default_session")
                flow_id = data.get("flow_id", "default_flow")
                api_key = data.get("api_key", None)

                # Langflow API 호출
                result = call_playground(input_text, session_id, flow_id, api_key)
                return jsonify(result)
            except Exception as e:
                return jsonify({"error": str(e)}), 500

        # Playground GUI 렌더링
        return render_template("playground.html")

    # Flows API
    @app.route("/flows/<user_id>", methods=["GET"])
    def get_user_flows(user_id):
        try:
            flows = list_flows(user_id)
            return jsonify({"flows": flows})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/flows/<user_id>/<flow_name>", methods=["GET"])
    def get_user_flow(user_id, flow_name):
        try:
            flow = load_flow(user_id, flow_name)
            return jsonify(flow)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/flows/<user_id>", methods=["POST"])
    def save_user_flow(user_id):
        try:
            data = request.get_json()
            flow_name = data.get("name")
            flow_content = data.get("content")
            file_path = save_flow(user_id, flow_name, flow_content)
            return jsonify({"message": f"Flow saved at {file_path}"})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    @app.route("/flows/<user_id>/<flow_name>", methods=["DELETE"])
    def delete_user_flow(user_id, flow_name):
        try:
            delete_flow(user_id, flow_name)
            return jsonify({"message": f"Flow {flow_name} deleted successfully."})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    # Auto-saving settings
    @app.route("/settings/auto-saving", methods=["POST"])
    def set_auto_saving():
        try:
            data = request.get_json()
            enable = data.get("enable", True)
            if enable:
                enable_auto_saving()
                return jsonify({"message": "Auto-Saving enabled."})
            else:
                disable_auto_saving()
                return jsonify({"message": "Auto-Saving disabled."})
        except Exception as e:
            return jsonify({"error": str(e)}), 500

@api.route('/evaluate', methods=['POST'])
async def evaluate_prompt():
    """프롬프트 평가 엔드포인트"""
    data = request.get_json()
    
    if not all(k in data for k in ['flow_id', 'prompt', 'expected_sql']):
        return jsonify({
            'error': 'Missing required fields: flow_id, prompt, expected_sql'
        }), 400
    
    result = await evaluator.evaluate_prompt(
        flow_id=data['flow_id'],
        prompt=data['prompt'],
        expected_sql=data['expected_sql'],
        test_cases=data.get('test_cases', [])
    )
    
    return jsonify(result)

@api.route('/flows', methods=['GET'])
async def list_flows():
    """사용 가능한 Langflow 워크플로우 목록 조회"""
    flows = await langflow_client.list_flows()
    return jsonify(flows)

@api.route('/flows/<flow_id>', methods=['GET'])
async def get_flow(flow_id):
    """특정 워크플로우 상세 정보 조회"""
    flow = await langflow_client.get_flow(flow_id)
    if not flow:
        return jsonify({'error': 'Flow not found'}), 404
    return jsonify(flow)

@api.route('/flows', methods=['POST'])
async def create_flow():
    """새로운 워크플로우 생성"""
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    flow = await langflow_client.create_flow(data)
    return jsonify(flow), 201

@api.route('/flows/<flow_id>', methods=['DELETE'])
async def delete_flow(flow_id):
    """워크플로우 삭제"""
    success = await langflow_client.delete_flow(flow_id)
    if not success:
        return jsonify({'error': 'Flow not found'}), 404
    return '', 204

@api.route('/results', methods=['GET'])
def get_evaluation_results():
    """평가 결과 조회"""
    import sqlite3
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)
    
    offset = (page - 1) * per_page
    
    with sqlite3.connect(os.getenv('DB_PATH', 'data/evaluation.db')) as conn:
        cursor = conn.cursor()
        
        # 전체 결과 수 조회
        cursor.execute('SELECT COUNT(*) FROM evaluation_results')
        total = cursor.fetchone()[0]
        
        # 페이지네이션된 결과 조회
        cursor.execute('''
            SELECT * FROM evaluation_results 
            ORDER BY timestamp DESC 
            LIMIT ? OFFSET ?
        ''', (per_page, offset))
        
        columns = [description[0] for description in cursor.description]
        results = []
        
        for row in cursor.fetchall():
            result = dict(zip(columns, row))
            # JSON 문자열을 파싱
            if result.get('test_results'):
                result['test_results'] = json.loads(result['test_results'])
            results.append(result)
    
    return jsonify({
        'results': results,
        'total': total,
        'page': page,
        'per_page': per_page,
        'total_pages': (total + per_page - 1) // per_page
    })
