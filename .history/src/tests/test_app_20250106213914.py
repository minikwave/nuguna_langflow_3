import unittest
from app.main import app

class TestApp(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()

    def test_kakao_webhook(self):
        response = self.client.post("/kakao", json={"userRequest": {"utterance": "Show all users"}})
        self.assertEqual(response.status_code, 200)
        self.assertIn("쿼리 결과", response.get_json()["template"]["outputs"][0]["simpleText"]["text"])
