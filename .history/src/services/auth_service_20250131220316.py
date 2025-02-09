from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session
from models.user import User
import os

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        return pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password: str) -> str:
        return pwd_context.hash(password)

    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        user = self.db.query(User).filter(User.email == email).first()
        if not user or not self.verify_password(password, user.hashed_password):
            return None
        
        # 마지막 로그인 시간 업데이트
        user.last_login = datetime.utcnow()
        self.db.commit()
        
        return user

    def create_access_token(self, data: dict, expires_delta: Optional[timedelta] = None) -> str:
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
            
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

    def decode_token(self, token: str) -> Optional[dict]:
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return payload
        except JWTError:
            return None

    def get_current_user(self, token: str) -> Optional[User]:
        payload = self.decode_token(token)
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