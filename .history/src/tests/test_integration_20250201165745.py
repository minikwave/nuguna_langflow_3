import unittest
from app.main import app
from services.database import initialize_database, execute_query
from services.websocket import create_test_websocket
from services.notifications import create_test_notification

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

class TestNotificationSystem(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.websocket = create_test_websocket()
        
    def test_notification_delivery(self):
        # 알림 전송 테스트
        notification = create_test_notification()
        response = self.websocket.send_notification(notification)
        self.assertEqual(response.status_code, 200)
        
    def test_notification_read_status(self):
        # 알림 읽음 상태 테스트
        notification_id = create_test_notification().id
        response = self.client.post(f'/api/notifications/{notification_id}/read')
        self.assertEqual(response.status_code, 200)
