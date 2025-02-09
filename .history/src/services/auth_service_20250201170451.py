from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from models.user import User
import os
import bcrypt
from services.cache_service import CacheService

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

class AuthService:
    def __init__(self, db: Session, cache_service: CacheService):
        self.db = db
        self.cache = cache_service
        self.max_login_attempts = 5
        self.lockout_duration = 300  # 5분

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password: str) -> str:
        return pwd_context.hash(password)

    async def check_login_attempts(self, email: str) -> bool:
        """로그인 시도 횟수 확인"""
        key = f"login_attempts:{email}"
        attempts = await self.cache.get(key) or 0
        return int(attempts) < self.max_login_attempts

    async def increment_login_attempts(self, email: str):
        """로그인 시도 횟수 증가"""
        key = f"login_attempts:{email}"
        attempts = await self.cache.get(key) or 0
        await self.cache.set(key, int(attempts) + 1, ttl=self.lockout_duration)

    async def reset_login_attempts(self, email: str):
        """로그인 시도 횟수 초기화"""
        key = f"login_attempts:{email}"
        await self.cache.delete(key)

    async def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """사용자 인증 with 로그인 시도 제한"""
        if not await self.check_login_attempts(email):
            raise TooManyAttemptsError("Too many login attempts. Try again later.")

        user = await self.get_user_by_email(email)
        if user and self.verify_password(password, user.password_hash):
            await self.reset_login_attempts(email)
            return user

        await self.increment_login_attempts(email)
        return None

    def create_access_token(self, user: User) -> str:
        expires = datetime.utcnow() + timedelta(hours=1)
        payload = {
            "sub": str(user.id),
            "email": user.email,
            "exp": expires
        }
        return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

    def verify_token(self, token: str) -> Optional[dict]:
        try:
            return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        except jwt.InvalidTokenError:
            return None

    def get_current_user(self, token: str) -> Optional[User]:
        payload = self.verify_token(token)
        if not payload:
            return None
            
        user_id = payload.get("sub")
        if user_id is None:
            return None
            
        return self.db.query(User).filter(User.id == user_id).first()

    def create_user(self, 
                   email: str, 
                   password: str, 
                   username: str, 
                   full_name: str = None,
                   is_superuser: bool = False) -> User:
        """새 사용자 생성"""
        # 이메일 중복 확인
        if self.db.query(User).filter(User.email == email).first():
            raise ValueError("Email already registered")
            
        # 사용자명 중복 확인
        if self.db.query(User).filter(User.username == username).first():
            raise ValueError("Username already taken")
            
        user = User(
            email=email,
            username=username,
            full_name=full_name,
            hashed_password=self.get_password_hash(password),
            is_superuser=is_superuser
        )
        
        self.db.add(user)
        self.db.commit()
        return user

    def change_password(self, user_id: int, current_password: str, new_password: str) -> bool:
        """비밀번호 변경"""
        user = self.db.query(User).filter(User.id == user_id).first()
        if not user or not self.verify_password(current_password, user.hashed_password):
            return False
            
        user.hashed_password = self.get_password_hash(new_password)
        self.db.commit()
        return True

    def reset_password(self, email: str) -> bool:
        """비밀번호 재설정 (이메일 발송)"""
        user = self.db.query(User).filter(User.email == email).first()
        if not user:
            return False
            
        # TODO: 비밀번호 재설정 이메일 발송 로직 구현
        return True 