from flask import Flask
from app.routes import init_routes
from app.config import Config

app = Flask(__name__)
app.config.from_object(Config)

# 라우트 초기화
init_routes(app)

@app.route("/")
def index():
    return "Hello, World!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
