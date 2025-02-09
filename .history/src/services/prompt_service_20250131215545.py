from typing import List, Optional, Dict, Any
from sqlalchemy.orm import Session
from datetime import datetime
from models.prompt import Prompt, PromptVersion, Comment, Tag, Team, TeamMember
from models.user import User

class PromptService:
    def __init__(self, db: Session):
        self.db = db

    def create_prompt(self, 
                     user_id: int, 
                     title: str, 
                     description: str, 
                     content: str,
                     expected_sql: Optional[str] = None,
                     team_id: Optional[int] = None,
                     tags: List[str] = None) -> Prompt:
        """새로운 프롬프트 생성"""
        prompt = Prompt(
            title=title,
            description=description,
            owner_id=user_id,
            team_id=team_id
        )
        self.db.add(prompt)
        self.db.flush()

        # 초기 버전 생성
        version = PromptVersion(
            prompt_id=prompt.id,
            version_number=1,
            content=content,
            expected_sql=expected_sql,
            changelog="Initial version",
            creator_id=user_id
        )
        self.db.add(version)

        # 태그 처리
        if tags:
            for tag_name in tags:
                tag = self.db.query(Tag).filter(Tag.name == tag_name).first()
                if not tag:
                    tag = Tag(name=tag_name)
                    self.db.add(tag)
                prompt.tags.append(tag)

        self.db.commit()
        return prompt

    def get_prompt(self, prompt_id: int) -> Optional[Prompt]:
        """프롬프트 조회"""
        return self.db.query(Prompt).filter(Prompt.id == prompt_id).first()

    def update_prompt(self, 
                     prompt_id: int, 
                     user_id: int, 
                     content: str,
                     expected_sql: Optional[str] = None,
                     changelog: str = "") -> PromptVersion:
        """프롬프트 업데이트 (새 버전 생성)"""
        prompt = self.get_prompt(prompt_id)
        if not prompt:
            raise ValueError("Prompt not found")

        # 권한 확인
        if not self._can_edit_prompt(user_id, prompt):
            raise ValueError("Permission denied")

        # 새 버전 번호 계산
        latest_version = max([v.version_number for v in prompt.versions])
        
        version = PromptVersion(
            prompt_id=prompt.id,
            version_number=latest_version + 1,
            content=content,
            expected_sql=expected_sql,
            changelog=changelog,
            creator_id=user_id
        )
        
        self.db.add(version)
        self.db.commit()
        return version

    def add_comment(self, 
                   user_id: int, 
                   prompt_id: int, 
                   content: str,
                   version_id: Optional[int] = None,
                   parent_id: Optional[int] = None) -> Comment:
        """댓글 추가"""
        comment = Comment(
            content=content,
            author_id=user_id,
            prompt_id=prompt_id,
            prompt_version_id=version_id,
            parent_id=parent_id
        )
        
        self.db.add(comment)
        self.db.commit()
        return comment

    def get_prompt_history(self, prompt_id: int) -> List[Dict[str, Any]]:
        """프롬프트 버전 히스토리 조회"""
        versions = self.db.query(PromptVersion)\
            .filter(PromptVersion.prompt_id == prompt_id)\
            .order_by(PromptVersion.version_number.desc())\
            .all()
            
        return [{
            "version": v.version_number,
            "content": v.content,
            "expected_sql": v.expected_sql,
            "changelog": v.changelog,
            "creator": v.creator.username,
            "created_at": v.created_at,
            "metrics": {
                "accuracy": v.accuracy_score,
                "execution_time": v.execution_time_avg,
                "success_rate": v.success_rate
            }
        } for v in versions]

    def search_prompts(self, 
                      query: str = None, 
                      tags: List[str] = None,
                      user_id: Optional[int] = None,
                      team_id: Optional[int] = None) -> List[Prompt]:
        """프롬프트 검색"""
        q = self.db.query(Prompt)
        
        if query:
            q = q.filter(Prompt.title.ilike(f"%{query}%") | 
                        Prompt.description.ilike(f"%{query}%"))
        
        if tags:
            q = q.filter(Prompt.tags.any(Tag.name.in_(tags)))
            
        if user_id:
            q = q.filter(Prompt.owner_id == user_id)
            
        if team_id:
            q = q.filter(Prompt.team_id == team_id)
            
        return q.all()

    def _can_edit_prompt(self, user_id: int, prompt: Prompt) -> bool:
        """프롬프트 편집 권한 확인"""
        if prompt.owner_id == user_id:
            return True
            
        if prompt.team_id:
            member = self.db.query(TeamMember)\
                .filter(TeamMember.team_id == prompt.team_id,
                       TeamMember.user_id == user_id,
                       TeamMember.role.in_(['admin', 'member']))\
                .first()
            return bool(member)
            
        return False 