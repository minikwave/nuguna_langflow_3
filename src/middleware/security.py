from functools import wraps
from flask import request, jsonify, current_app
import jwt
from datetime import datetime, timedelta

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        if not api_key:
            return jsonify({'error': 'API 키가 필요합니다'}), 401
        
        if api_key != current_app.config['API_KEY']:
            return jsonify({'error': '유효하지 않은 API 키입니다'}), 403
            
        return f(*args, **kwargs)
    return decorated

def generate_jwt_token(user_id: int) -> str:
    """JWT 토큰 생성"""
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=1),
        'iat': datetime.utcnow()
    }
    return jwt.encode(
        payload,
        current_app.config['JWT_SECRET_KEY'],
        algorithm='HS256'
    )

class RateLimiter:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.default_limit = 100  # 기본 요청 제한
        self.window = 3600  # 1시간

    async def is_rate_limited(self, key: str, limit: int = None) -> bool:
        """속도 제한 확인"""
        current = await self.redis.incr(f"ratelimit:{key}")
        if current == 1:
            await self.redis.expire(f"ratelimit:{key}", self.window)
        
        return current > (limit or self.default_limit) 