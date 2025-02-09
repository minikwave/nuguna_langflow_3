from flask import Flask
from flask.cli import ScriptInfo
from dotenv import load_dotenv
import os
from .routes import api

load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # 설정
    app.config.from_mapping(
        SECRET_KEY=os.getenv('SECRET_KEY', 'dev'),
        DB_PATH=os.getenv('DB_PATH', 'data/evaluation.db'),
        LANGFLOW_API_URL=os.getenv('LANGFLOW_API_URL', 'http://langflow:7860')
    )
    
    # Blueprint 등록
    app.register_blueprint(api, url_prefix='/api')
    
    return app

app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
