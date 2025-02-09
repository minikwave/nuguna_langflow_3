# Text-to-SQL Test Infrastructure

A web-based testing infrastructure for validating and improving text-to-SQL chatbot performance, built using Langflow.

## Features

- **Langflow Integration**: Seamlessly integrate with Langflow for Text-to-SQL processing.
- **Sample Databases**: Multiple sample SQLite databases for testing.
- **Admin Dashboard**: Monitor system status and manage workflows.
- **Automated Testing**: Comprehensive unit and integration tests.
- **Docker Support**: Easily deploy with Docker and Docker Compose.

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/text-to-sql-test-infra.git
   cd text-to-sql-test-infra
Install dependencies:

bash
코드 복사
pip install -r requirements.txt
Start the application:

bash
코드 복사
flask run
Access the app:

API: http://localhost:5000
Admin Dashboard: http://localhost:5000/admin
Environment Variables
Refer to .env.example for the required variables.

Running Tests
Run all tests using pytest:

bash
코드 복사
pytest src/tests
Docker Deployment
Build and run using Docker Compose:

bash
코드 복사
docker-compose up --build
Contributing
Feel free to submit issues or pull requests. Contributions are welcome!

yaml
코드 복사

---

### **6. `requirements.txt`**
Python 의존성 파일.

```plaintext
Flask==2.3.2
requests==2.31.0
pytest==7.4.2
pytest-cov==4.1.0
sqlite==3.38.5
Jinja2==3.1.2
