from typing import Any, Optional, List
import json
from redis.asyncio import Redis
from app.config import Config

class CacheService:
    def __init__(self):
        self.redis = Redis.from_url(
            Config.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
        self.default_ttl = 3600

    async def get_or_set(self, key: str, getter_func, ttl: int = None) -> Any:
        """캐시된 값 조회 또는 새로 설정"""
        value = await self.get(key)
        if value is None:
            value = await getter_func()
            if value is not None:
                await self.set(key, value, ttl)
        return value

    async def invalidate_pattern(self, pattern: str):
        """패턴에 매칭되는 모든 키 삭제"""
        keys = await self.redis.keys(pattern)
        if keys:
            await self.redis.delete(*keys)

    async def get_many(self, keys: List[str]) -> List[Any]:
        """여러 키의 값을 한 번에 조회"""
        pipeline = self.redis.pipeline()
        for key in keys:
            pipeline.get(key)
        values = await pipeline.execute()
        return [json.loads(v) if v else None for v in values]

    async def get(self, key: str) -> Optional[Any]:
        value = await self.redis.get(key)
        return value.decode() if value else None
        
    async def set(self, key: str, value: Any, ttl: int = None):
        await self.redis.set(key, value, ex=ttl or self.default_ttl) 