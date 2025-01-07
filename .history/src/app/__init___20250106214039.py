```python
from flask import Flask

def create_app(config_object):
    app = Flask(__name__)
    app.config.from_object(config_object)

    # Import routes
    from app.routes import init_routes
    init_routes(app)

    return app