from flask import Flask
from flask_cors import CORS
from src.routes import api_bp
from src.config import Config
from src.models import Base
from sqlalchemy import create_engine

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)
    
    CORS(app)
    
    engine = create_engine(app.config['SQLALCHEMY_DATABASE_URI'])
    Base.metadata.bind = engine
    
    app.register_blueprint(api_bp, url_prefix='/api')
    
    return app 