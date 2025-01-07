import unittest
from services.langflow_service import call_langflow

class TestLangflow(unittest.TestCase):
    def test_call_langflow(self):
        response = call_langflow("Show all users in the database.")
        self.assertIn("SELECT", response.upper())
