from typing import Any, Optional
import redis
from app.config import Config

class CacheService:
    def __init__(self):
        self.redis = redis.Redis.from_url(Config.REDIS_URL)
        self.default_ttl = 3600  # 1시간
        
    async def get(self, key: str) -> Optional[Any]:
        value = await self.redis.get(key)
        return value.decode() if value else None
        
    async def set(self, key: str, value: Any, ttl: int = None):
        await self.redis.set(key, value, ex=ttl or self.default_ttl) 