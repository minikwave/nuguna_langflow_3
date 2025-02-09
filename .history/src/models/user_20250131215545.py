from datetime import datetime
from typing import Optional, List
from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True, index=True)
    username = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    full_name = Column(String)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login = Column(DateTime, nullable=True)
    
    # 관계 설정
    prompts = relationship("Prompt", back_populates="owner")
    comments = relationship("Comment", back_populates="author")
    prompt_versions = relationship("PromptVersion", back_populates="creator")
    team_memberships = relationship("TeamMember", back_populates="user")
    
    def __repr__(self):
        return f"<User {self.username}>" 