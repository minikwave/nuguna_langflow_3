from contextlib import asynccontextmanager
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession
from .connection import AsyncDatabaseManager

class DatabaseSessionManager:
    def __init__(self):
        self.db = AsyncDatabaseManager()

    @asynccontextmanager
    async def session(self) -> AsyncGenerator[AsyncSession, None]:
        """데이터베이스 세션 컨텍스트 매니저"""
        session: AsyncSession = self.db.SessionLocal()
        try:
            yield session
            await session.commit()
        except Exception as e:
            await session.rollback()
            raise
        finally:
            await session.close()

    async def cleanup(self):
        """데이터베이스 연결 정리"""
        await self.db.engine.dispose()

db_manager = DatabaseSessionManager() 