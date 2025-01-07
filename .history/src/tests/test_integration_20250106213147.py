import unittest
from app.main import app
from services.database import initialize_database, execute_query

class TestIntegration(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        initialize_database("data/sample_db_1.db")
    
    def test_kakao_webhook(self):
        response = self.client.post("/kakao", json={
            "userRequest": {"utterance": "Show all users"}
        })
        self.assertEqual(response.status_code, 200)
        self.assertIn("쿼리 결과", response.get_json()["template"]["outputs"][0]["simpleText"]["text"])
    
    def test_admin_page(self):
        response = self.client.get("/admin")
        self.assertEqual(response.status_code, 200)
        self.assertIn("Langflow Status", response.get_data(as_text=True))
