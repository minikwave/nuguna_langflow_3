import unittest
from app.utils.sql_manager import validate_sql, execute_query

class TestSQLQueries(unittest.TestCase):
    def test_validate_sql(self):
        with self.assertRaises(ValueError):
            validate_sql("DROP TABLE users;")
    
    def test_execute_query(self):
        result = execute_query("SELECT 1;", "data/sample_db_1.db")
        self.assertEqual(result, [(1,)])
