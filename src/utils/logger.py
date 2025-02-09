import logging
import os
from logging.handlers import RotatingFileHandler

def setup_logger(name, log_file, level=logging.INFO):
    """로거 설정"""
    formatter = logging.Formatter(
        '%(asctime)s %(levelname)s [%(name)s] %(message)s'
    )

    handler = RotatingFileHandler(
        log_file, maxBytes=10000000, backupCount=5
    )
    handler.setFormatter(formatter)

    logger = logging.getLogger(name)
    logger.setLevel(level)
    logger.addHandler(handler)

    return logger

# 로그 디렉토리 생성
os.makedirs('logs', exist_ok=True)

# 로거 초기화
app_logger = setup_logger('app', 'logs/app.log')
langflow_logger = setup_logger('langflow', 'logs/langflow.log') 