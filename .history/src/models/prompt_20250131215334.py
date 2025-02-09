from datetime import datetime
from typing import Optional, List
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Table, Text, Float
from sqlalchemy.orm import relationship
from .database import Base

# 프롬프트-태그 연결 테이블
prompt_tags = Table('prompt_tags', Base.metadata,
    Column('prompt_id', Integer, ForeignKey('prompts.id')),
    Column('tag_id', Integer, ForeignKey('tags.id'))
)

class Prompt(Base):
    __tablename__ = "prompts"

    id = Column(Integer, primary_key=True)
    title = Column(String, index=True)
    description = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    owner_id = Column(Integer, ForeignKey("users.id"))
    team_id = Column(Integer, ForeignKey("teams.id"), nullable=True)
    is_public = Column(Boolean, default=False)
    
    # 관계 설정
    owner = relationship("User", back_populates="prompts")
    versions = relationship("PromptVersion", back_populates="prompt", order_by="PromptVersion.version_number")
    comments = relationship("Comment", back_populates="prompt")
    tags = relationship("Tag", secondary=prompt_tags, back_populates="prompts")
    team = relationship("Team", back_populates="prompts")

class PromptVersion(Base):
    __tablename__ = "prompt_versions"

    id = Column(Integer, primary_key=True)
    prompt_id = Column(Integer, ForeignKey("prompts.id"))
    version_number = Column(Integer)
    content = Column(Text)
    expected_sql = Column(Text, nullable=True)
    changelog = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    creator_id = Column(Integer, ForeignKey("users.id"))
    
    # 성능 메트릭
    accuracy_score = Column(Float, nullable=True)
    execution_time_avg = Column(Float, nullable=True)
    success_rate = Column(Float, nullable=True)
    
    # 관계 설정
    prompt = relationship("Prompt", back_populates="versions")
    creator = relationship("User", back_populates="prompt_versions")
    evaluations = relationship("Evaluation", back_populates="prompt_version")
    comments = relationship("Comment", back_populates="prompt_version")

class Comment(Base):
    __tablename__ = "comments"

    id = Column(Integer, primary_key=True)
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    author_id = Column(Integer, ForeignKey("users.id"))
    prompt_id = Column(Integer, ForeignKey("prompts.id"))
    prompt_version_id = Column(Integer, ForeignKey("prompt_versions.id"), nullable=True)
    parent_id = Column(Integer, ForeignKey("comments.id"), nullable=True)
    
    # 관계 설정
    author = relationship("User", back_populates="comments")
    prompt = relationship("Prompt", back_populates="comments")
    prompt_version = relationship("PromptVersion", back_populates="comments")
    replies = relationship("Comment", backref=backref("parent", remote_side=[id]))

class Tag(Base):
    __tablename__ = "tags"

    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True, index=True)
    
    # 관계 설정
    prompts = relationship("Prompt", secondary=prompt_tags, back_populates="tags")

class Team(Base):
    __tablename__ = "teams"

    id = Column(Integer, primary_key=True)
    name = Column(String, unique=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    members = relationship("TeamMember", back_populates="team")
    prompts = relationship("Prompt", back_populates="team")

class TeamMember(Base):
    __tablename__ = "team_members"

    id = Column(Integer, primary_key=True)
    team_id = Column(Integer, ForeignKey("teams.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    role = Column(String)  # admin, member, viewer
    joined_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    team = relationship("Team", back_populates="members")
    user = relationship("User", back_populates="team_memberships") 