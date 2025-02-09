from alembic import command
from alembic.config import Config
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class MigrationManager:
    def __init__(self, db_url: str):
        self.db_url = db_url
        self.alembic_cfg = self._create_alembic_config()

    def _create_alembic_config(self) -> Config:
        """Alembic 설정 생성"""
        base_path = Path(__file__).parent.parent
        alembic_cfg = Config()
        alembic_cfg.set_main_option("script_location", str(base_path / "migrations"))
        alembic_cfg.set_main_option("sqlalchemy.url", self.db_url)
        return alembic_cfg

    async def run_migrations(self) -> None:
        """마이그레이션 실행"""
        try:
            command.upgrade(self.alembic_cfg, "head")
            logger.info("Database migrations completed successfully")
        except Exception as e:
            logger.error(f"Migration failed: {e}")
            raise 