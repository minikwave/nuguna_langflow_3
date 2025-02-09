from prometheus_client import Counter, Histogram
import time

class MetricsCollector:
    def __init__(self):
        self.sql_conversion_time = Histogram(
            'sql_conversion_seconds',
            'Time spent converting text to SQL'
        )
        self.conversion_errors = Counter(
            'sql_conversion_errors_total',
            'Total number of SQL conversion errors'
        ) 