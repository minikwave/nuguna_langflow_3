from typing import Dict, Any
import aiohttp
import asyncio
from datetime import datetime
from app.config import Config

class HealthCheck:
    def __init__(self):
        self.services = {
            'langflow': Config.LANGFLOW_API_URL,
            'database': Config.SQLALCHEMY_DATABASE_URL,
            'redis': Config.REDIS_URL
        }
        self.status_cache = {}
        self.cache_ttl = 60  # 60초

    async def check_langflow(self) -> Dict[str, Any]:
        """Langflow 서비스 상태 확인"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.services['langflow']}/health") as response:
                    if response.status == 200:
                        return {"status": "healthy", "latency": response.elapsed.total_seconds()}
                    return {"status": "unhealthy", "error": await response.text()}
        except Exception as e:
            return {"status": "error", "error": str(e)}

    async def check_all(self) -> Dict[str, Any]:
        """모든 서비스 상태 확인"""
        now = datetime.now()
        
        # 캐시된 결과가 있고 TTL이 지나지 않았다면 캐시된 결과 반환
        if self.status_cache and (now - self.status_cache['timestamp']).seconds < self.cache_ttl:
            return self.status_cache['results']

        results = {
            'timestamp': now.isoformat(),
            'services': {}
        }

        # 비동기로 모든 서비스 체크
        tasks = [
            self.check_langflow(),
            self.check_database(),
            self.check_redis()
        ]
        
        service_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for service, result in zip(self.services.keys(), service_results):
            if isinstance(result, Exception):
                results['services'][service] = {
                    'status': 'error',
                    'error': str(result)
                }
            else:
                results['services'][service] = result

        # 결과 캐싱
        self.status_cache = {
            'timestamp': now,
            'results': results
        }

        return results 