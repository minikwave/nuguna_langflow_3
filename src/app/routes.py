from flask import Blueprint, request, jsonify, render_template, g
from services.langflow_service import call_langflow, call_playground, enable_auto_saving, disable_auto_saving
from services.database import execute_query
from services.file_manager import save_json, load_json, delete_json, list_json_files
from services.admin_service import get_system_status
from services.flow_manager import save_flow, load_flow, list_flows, delete_flow
from services.evaluation.evaluator import PromptEvaluator
from services.langflow.client import LangflowClient
from services.prompt_service import PromptService
from models.database import get_db
from typing import List, Optional
from services.auth_service import AuthService
from datetime import timedelta
from functools import wraps
from services.notification_service import NotificationService
from services.websocket_service import websocket_manager
from fastapi import WebSocket, WebSocketDisconnect
import asyncio
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

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'error': 'No authentication token provided'}), 401
            
        token = auth_header.split(' ')[1]
        db = next(get_db())
        auth_service = AuthService(db)
        
        current_user = auth_service.get_current_user(token)
        if not current_user:
            return jsonify({'error': 'Invalid authentication token'}), 401
            
        g.current_user = current_user
        return f(*args, **kwargs)
    return decorated_function

@api.route('/auth/register', methods=['POST'])
def register():
    """새 사용자 등록"""
    data = request.get_json()
    db = next(get_db())
    
    try:
        user = AuthService(db).create_user(
            email=data['email'],
            password=data['password'],
            username=data['username'],
            full_name=data.get('full_name')
        )
        
        return jsonify({
            'id': user.id,
            'email': user.email,
            'username': user.username
        }), 201
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@api.route('/auth/login', methods=['POST'])
def login():
    """사용자 로그인"""
    data = request.get_json()
    db = next(get_db())
    auth_service = AuthService(db)
    
    user = auth_service.authenticate_user(data['email'], data['password'])
    if not user:
        return jsonify({'error': 'Invalid email or password'}), 401
        
    access_token = auth_service.create_access_token(
        data={"sub": str(user.id)},
        expires_delta=timedelta(minutes=30)
    )
    
    return jsonify({
        'access_token': access_token,
        'token_type': 'bearer',
        'user': {
            'id': user.id,
            'email': user.email,
            'username': user.username
        }
    })

@api.route('/auth/me', methods=['GET'])
@login_required
def get_current_user():
    """현재 로그인한 사용자 정보 조회"""
    user = g.current_user
    return jsonify({
        'id': user.id,
        'email': user.email,
        'username': user.username,
        'full_name': user.full_name,
        'is_superuser': user.is_superuser,
        'created_at': user.created_at.isoformat(),
        'last_login': user.last_login.isoformat() if user.last_login else None
    })

@api.route('/auth/change-password', methods=['POST'])
@login_required
def change_password():
    """비밀번호 변경"""
    data = request.get_json()
    db = next(get_db())
    
    success = AuthService(db).change_password(
        user_id=g.current_user.id,
        current_password=data['current_password'],
        new_password=data['new_password']
    )
    
    if not success:
        return jsonify({'error': 'Invalid current password'}), 400
        
    return jsonify({'message': 'Password changed successfully'})

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

@api.route('/prompts', methods=['POST'])
@login_required
def create_prompt():
    """새 프롬프트 생성"""
    data = request.get_json()
    db = next(get_db())
    
    try:
        prompt = PromptService(db).create_prompt(
            user_id=g.current_user.id,
            title=data['title'],
            description=data['description'],
            content=data['content'],
            expected_sql=data.get('expected_sql'),
            team_id=data.get('team_id'),
            tags=data.get('tags', [])
        )
        
        return jsonify({
            'id': prompt.id,
            'title': prompt.title,
            'description': prompt.description,
            'created_at': prompt.created_at.isoformat()
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@api.route('/prompts/<int:prompt_id>', methods=['GET'])
def get_prompt(prompt_id: int):
    """프롬프트 상세 정보 조회"""
    db = next(get_db())
    prompt = PromptService(db).get_prompt(prompt_id)
    
    if not prompt:
        return jsonify({'error': 'Prompt not found'}), 404
        
    return jsonify({
        'id': prompt.id,
        'title': prompt.title,
        'description': prompt.description,
        'owner': {
            'id': prompt.owner.id,
            'username': prompt.owner.username
        },
        'team': {
            'id': prompt.team.id,
            'name': prompt.team.name
        } if prompt.team else None,
        'tags': [tag.name for tag in prompt.tags],
        'latest_version': {
            'number': prompt.versions[-1].version_number,
            'content': prompt.versions[-1].content,
            'expected_sql': prompt.versions[-1].expected_sql,
            'metrics': {
                'accuracy': prompt.versions[-1].accuracy_score,
                'execution_time': prompt.versions[-1].execution_time_avg,
                'success_rate': prompt.versions[-1].success_rate
            }
        } if prompt.versions else None,
        'created_at': prompt.created_at.isoformat(),
        'updated_at': prompt.updated_at.isoformat()
    })

@api.route('/prompts/<int:prompt_id>/versions', methods=['POST'])
@login_required
def update_prompt(prompt_id: int):
    """프롬프트 업데이트 (새 버전 생성)"""
    data = request.get_json()
    db = next(get_db())
    
    try:
        # 프롬프트 정보 조회
        prompt = PromptService(db).get_prompt(prompt_id)
        
        # 버전 생성
        version = PromptService(db).update_prompt(
            prompt_id=prompt_id,
            user_id=g.current_user.id,
            content=data['content'],
            expected_sql=data.get('expected_sql'),
            changelog=data.get('changelog', '')
        )
        
        # 알림 생성
        NotificationService(db).create_version_notification(
            creator_id=g.current_user.id,
            prompt_owner_id=prompt.owner_id,
            prompt_title=prompt.title,
            version_number=version.version_number
        )
        
        return jsonify({
            'version': version.version_number,
            'content': version.content,
            'expected_sql': version.expected_sql,
            'changelog': version.changelog,
            'created_at': version.created_at.isoformat()
        })
    except ValueError as e:
        return jsonify({'error': str(e)}), 400

@api.route('/prompts/<int:prompt_id>/versions', methods=['GET'])
def get_prompt_history(prompt_id: int):
    """프롬프트 버전 히스토리 조회"""
    db = next(get_db())
    history = PromptService(db).get_prompt_history(prompt_id)
    return jsonify(history)

@api.route('/prompts/<int:prompt_id>/comments', methods=['POST'])
@login_required
def add_comment(prompt_id: int):
    """댓글 추가"""
    data = request.get_json()
    db = next(get_db())
    
    try:
        # 댓글 생성
        comment = PromptService(db).add_comment(
            user_id=g.current_user.id,
            prompt_id=prompt_id,
            content=data['content'],
            version_id=data.get('version_id'),
            parent_id=data.get('parent_id')
        )
        
        # 프롬프트 정보 조회
        prompt = PromptService(db).get_prompt(prompt_id)
        
        # 알림 생성
        NotificationService(db).create_comment_notification(
            comment_author_id=g.current_user.id,
            prompt_owner_id=prompt.owner_id,
            prompt_title=prompt.title,
            comment_content=data['content']
        )
        
        return jsonify({
            'id': comment.id,
            'content': comment.content,
            'author': {
                'id': comment.author.id,
                'username': comment.author.username
            },
            'created_at': comment.created_at.isoformat()
        }), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@api.route('/prompts/search', methods=['GET'])
def search_prompts():
    """프롬프트 검색"""
    db = next(get_db())
    
    query = request.args.get('q')
    tags = request.args.getlist('tags')
    user_id = request.args.get('user_id', type=int)
    team_id = request.args.get('team_id', type=int)
    
    prompts = PromptService(db).search_prompts(
        query=query,
        tags=tags,
        user_id=user_id,
        team_id=team_id
    )
    
    return jsonify([{
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'owner': {
            'id': p.owner.id,
            'username': p.owner.username
        },
        'tags': [tag.name for tag in p.tags],
        'created_at': p.created_at.isoformat()
    } for p in prompts])

@api.route('/notifications', methods=['GET'])
@login_required
def get_notifications():
    """사용자의 알림 목록 조회"""
    db = next(get_db())
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    unread_only = request.args.get('unread_only', False, type=bool)
    
    notifications = NotificationService(db).get_user_notifications(
        user_id=g.current_user.id,
        page=page,
        per_page=per_page,
        unread_only=unread_only
    )
    
    return jsonify(notifications)

@api.route('/notifications/<int:notification_id>/read', methods=['POST'])
@login_required
def mark_notification_as_read(notification_id: int):
    """알림을 읽음 상태로 표시"""
    db = next(get_db())
    success = NotificationService(db).mark_as_read(
        notification_id=notification_id,
        user_id=g.current_user.id
    )
    
    if not success:
        return jsonify({'error': 'Notification not found'}), 404
        
    return jsonify({'message': 'Notification marked as read'})

@api.route('/notifications/read-all', methods=['POST'])
@login_required
def mark_all_notifications_as_read():
    """모든 알림을 읽음 상태로 표시"""
    db = next(get_db())
    count = NotificationService(db).mark_all_as_read(g.current_user.id)
    return jsonify({'message': f'{count} notifications marked as read'})

@api.websocket("/ws/{token}")
async def websocket_endpoint(websocket: WebSocket, token: str):
    """WebSocket 연결 엔드포인트"""
    db = next(get_db())
    auth_service = AuthService(db)
    
    # 토큰으로 사용자 인증
    user = auth_service.get_current_user(token)
    if not user:
        await websocket.close(code=4001)  # Unauthorized
        return
        
    try:
        # WebSocket 연결 수립
        await websocket_manager.connect(websocket, user.id)
        
        # 사용자별 알림 구독 시작
        await websocket_manager.subscribe_to_notifications(user.id)
        
    except WebSocketDisconnect:
        await websocket_manager.disconnect(websocket, user.id)
    except Exception as e:
        print(f"WebSocket error: {str(e)}")
        await websocket_manager.disconnect(websocket, user.id)

@api.route('/notifications/test', methods=['POST'])
@login_required
def test_notification():
    """테스트용 실시간 알림 전송"""
    data = request.get_json()
    db = next(get_db())
    
    notification = NotificationService(db).create_notification(
        user_id=g.current_user.id,
        type='test',
        content=data.get('content', 'Test notification'),
        data=data.get('data')
    )
    
    # WebSocket을 통한 실시간 알림 전송
    asyncio.create_task(
        websocket_manager.send_personal_message(
            {
                'type': notification.type,
                'content': notification.content,
                'data': json.loads(notification.data) if notification.data else None
            },
            g.current_user.id
        )
    )
    
    return jsonify({'message': 'Test notification sent'})
