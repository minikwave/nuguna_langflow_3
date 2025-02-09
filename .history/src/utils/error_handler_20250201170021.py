import logging
from functools import wraps
from flask import jsonify
from typing import Type, Callable
import traceback

# 로거 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

class AppError(Exception):
    def __init__(self, message: str, status_code: int = 500):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)

def handle_error(error_class: Type[Exception]) -> Callable:
    def decorator(f: Callable) -> Callable:
        @wraps(f)
        async def decorated_function(*args, **kwargs):
            try:
                return await f(*args, **kwargs)
            except error_class as e:
                logger.error(f"Error in {f.__name__}: {str(e)}")
                logger.error(traceback.format_exc())
                return jsonify({
                    'error': str(e),
                    'type': error_class.__name__
                }), getattr(e, 'status_code', 500)
        return decorated_function
    return decorator 