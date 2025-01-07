import unittest
from services.database import initialize_database, get_db_status

class TestDatabase(unittest.TestCase):
    def setUp(self):
        self.db_path = "data/sample_db_1.db"
        initialize_database(self.db_path)
    
    def test_db_connection(self):
        status = get_db_status(self.db_path)
        self.assertEqual(status, "Connected")
