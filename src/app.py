from flask import Flask
from flask_cors import CORS
from src.models import Base
from sqlalchemy import create_engine

def create_app():
    app = Flask(__name__)
    CORS(app)
    
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://user:password@localhost:5433/text_to_sql'
    
    # 데이터베이스 초기화
    engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
    Base.metadata.bind = engine
    
    return app
