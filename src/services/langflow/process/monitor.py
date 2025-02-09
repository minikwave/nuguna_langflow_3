from dataclasses import dataclass
from datetime import datetime
import psutil

@dataclass
class ProcessStats:
    cpu_percent: float
    memory_percent: float
    uptime: float
    timestamp: datetime

class LangflowProcessMonitor:
    def __init__(self, process):
        self.process = process
        self.stats_history = []

    async def collect_stats(self):
        """프로세스 상태 수집"""
        try:
            process = psutil.Process(self.process.pid)
            stats = ProcessStats(
                cpu_percent=process.cpu_percent(),
                memory_percent=process.memory_percent(),
                uptime=datetime.now().timestamp() - process.create_time(),
                timestamp=datetime.now()
            )
            self.stats_history.append(stats)
            return stats
        except psutil.NoSuchProcess:
            return None 