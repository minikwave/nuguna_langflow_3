from typing import List, Optional, Dict, Any
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Boolean, Text
from sqlalchemy.orm import relationship, Session
from models.database import Base
import json
import asyncio
from services.websocket_service import websocket_manager

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    type = Column(String)  # comment, version, mention, team_invite
    content = Column(Text)
    data = Column(Text)  # JSON 데이터
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # 관계 설정
    user = relationship("User", backref="notifications")

class NotificationService:
    def __init__(self, db: Session):
        self.db = db

    def create_notification(self,
                          user_id: int,
                          type: str,
                          content: str,
                          data: Dict[str, Any] = None) -> Notification:
        """새 알림 생성"""
        notification = Notification(
            user_id=user_id,
            type=type,
            content=content,
            data=json.dumps(data) if data else None
        )
        
        self.db.add(notification)
        self.db.commit()
        
        # TODO: WebSocket을 통한 실시간 알림 전송
        self._send_realtime_notification(notification)
        
        return notification

    def get_user_notifications(self,
                             user_id: int,
                             page: int = 1,
                             per_page: int = 20,
                             unread_only: bool = False) -> List[Dict[str, Any]]:
        """사용자의 알림 목록 조회"""
        query = self.db.query(Notification)\
            .filter(Notification.user_id == user_id)
            
        if unread_only:
            query = query.filter(Notification.is_read == False)
            
        notifications = query.order_by(Notification.created_at.desc())\
            .offset((page - 1) * per_page)\
            .limit(per_page)\
            .all()
            
        return [{
            'id': n.id,
            'type': n.type,
            'content': n.content,
            'data': json.loads(n.data) if n.data else None,
            'is_read': n.is_read,
            'created_at': n.created_at.isoformat()
        } for n in notifications]

    def mark_as_read(self, notification_id: int, user_id: int) -> bool:
        """알림을 읽음 상태로 표시"""
        notification = self.db.query(Notification)\
            .filter(Notification.id == notification_id,
                   Notification.user_id == user_id)\
            .first()
                   
        if not notification:
            return False
            
        notification.is_read = True
        self.db.commit()
        return True

    def mark_all_as_read(self, user_id: int) -> int:
        """사용자의 모든 알림을 읽음 상태로 표시"""
        result = self.db.query(Notification)\
            .filter(Notification.user_id == user_id,
                   Notification.is_read == False)\
            .update({'is_read': True})
                   
        self.db.commit()
        return result

    def create_comment_notification(self,
                                 comment_author_id: int,
                                 prompt_owner_id: int,
                                 prompt_title: str,
                                 comment_content: str) -> Notification:
        """댓글 작성 알림 생성"""
        if comment_author_id == prompt_owner_id:
            return None
            
        return self.create_notification(
            user_id=prompt_owner_id,
            type='comment',
            content=f'New comment on your prompt "{prompt_title}"',
            data={
                'author_id': comment_author_id,
                'comment': comment_content
            }
        )

    def create_version_notification(self,
                                 creator_id: int,
                                 prompt_owner_id: int,
                                 prompt_title: str,
                                 version_number: int) -> Notification:
        """새 버전 생성 알림"""
        if creator_id == prompt_owner_id:
            return None
            
        return self.create_notification(
            user_id=prompt_owner_id,
            type='version',
            content=f'New version (v{version_number}) created for "{prompt_title}"',
            data={
                'creator_id': creator_id,
                'version': version_number
            }
        )

    def create_team_invite_notification(self,
                                     inviter_id: int,
                                     invitee_id: int,
                                     team_name: str) -> Notification:
        """팀 초대 알림"""
        return self.create_notification(
            user_id=invitee_id,
            type='team_invite',
            content=f'You have been invited to join team "{team_name}"',
            data={
                'inviter_id': inviter_id,
                'team_name': team_name
            }
        )

    def _send_realtime_notification(self, notification: Notification):
        """WebSocket을 통한 실시간 알림 전송"""
        asyncio.create_task(
            websocket_manager.send_personal_message(
                {
                    'type': notification.type,
                    'content': notification.content,
                    'data': json.loads(notification.data) if notification.data else None
                },
                notification.user_id
            )
        )
        
        # Redis를 통한 발행
        asyncio.create_task(
            websocket_manager.publish_notification(
                notification.user_id,
                {
                    'type': notification.type,
                    'content': notification.content,
                    'data': json.loads(notification.data) if notification.data else None
                }
            )
        ) 