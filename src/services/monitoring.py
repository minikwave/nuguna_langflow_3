from prometheus_client import Counter, Histogram, Gauge
from typing import Dict, Any
import time

class MetricsCollector:
    def __init__(self):
        self.sql_conversion_time = Histogram(
            'sql_conversion_seconds',
            'Time spent converting text to SQL',
            ['flow_id', 'status']
        )
        self.conversion_errors = Counter(
            'sql_conversion_errors_total',
            'Total number of SQL conversion errors',
            ['error_type']
        )
        
        self.active_users = Gauge(
            'active_users_total',
            'Number of currently active users'
        )
        self.db_connection_pool = Gauge(
            'db_connection_pool',
            'Database connection pool statistics',
            ['state']
        )
        self.cache_hits = Counter(
            'cache_hits_total',
            'Total number of cache hits'
        )
        self.cache_misses = Counter(
            'cache_misses_total',
            'Total number of cache misses'
        )

    async def collect_system_metrics(self):
        """시스템 메트릭 수집"""
        import psutil
        
        # CPU 사용량
        self.cpu_usage.set(psutil.cpu_percent())
        
        # 메모리 사용량
        memory = psutil.virtual_memory()
        self.memory_usage.set(memory.percent)
        
        # 디스크 사용량
        disk = psutil.disk_usage('/')
        self.disk_usage.set(disk.percent) 