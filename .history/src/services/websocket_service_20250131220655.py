import asyncio
from typing import Dict, Set, Any
import json
from datetime import datetime
import aioredis
from fastapi import WebSocket, WebSocketDisconnect

class WebSocketManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = {}
        self.redis = None
    
    async def connect(self, websocket: WebSocket, user_id: int):
        """새로운 WebSocket 연결 설정"""
        await websocket.accept()
        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()
        self.active_connections[user_id].add(websocket)

    async def disconnect(self, websocket: WebSocket, user_id: int):
        """WebSocket 연결 해제"""
        self.active_connections[user_id].remove(websocket)
        if not self.active_connections[user_id]:
            del self.active_connections[user_id]

    async def send_personal_message(self, message: Dict[str, Any], user_id: int):
        """특정 사용자에게 메시지 전송"""
        if user_id in self.active_connections:
            message_data = {
                "type": message["type"],
                "content": message["content"],
                "data": message.get("data"),
                "timestamp": datetime.utcnow().isoformat()
            }
            
            for connection in self.active_connections[user_id]:
                try:
                    await connection.send_json(message_data)
                except WebSocketDisconnect:
                    await self.disconnect(connection, user_id)

    async def broadcast(self, message: Dict[str, Any], exclude_user: int = None):
        """모든 연결된 클라이언트에게 메시지 브로드캐스트"""
        message_data = {
            "type": message["type"],
            "content": message["content"],
            "data": message.get("data"),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        for user_id, connections in self.active_connections.items():
            if exclude_user and user_id == exclude_user:
                continue
                
            for connection in connections:
                try:
                    await connection.send_json(message_data)
                except WebSocketDisconnect:
                    await self.disconnect(connection, user_id)

    async def init_redis(self):
        """Redis 연결 초기화"""
        if not self.redis:
            self.redis = await aioredis.create_redis_pool('redis://localhost')

    async def publish_notification(self, user_id: int, notification: Dict[str, Any]):
        """Redis를 통해 알림 발행"""
        if not self.redis:
            await self.init_redis()
            
        channel = f"notifications:{user_id}"
        await self.redis.publish(channel, json.dumps(notification))

    async def subscribe_to_notifications(self, user_id: int):
        """사용자별 알림 구독"""
        if not self.redis:
            await self.init_redis()
            
        channel = f"notifications:{user_id}"
        channel = await self.redis.subscribe(channel)
        
        try:
            while True:
                message = await channel[0].get()
                if message:
                    notification = json.loads(message.decode())
                    await self.send_personal_message(notification, user_id)
        except Exception as e:
            print(f"Subscription error: {str(e)}")
        finally:
            await self.redis.unsubscribe(channel)

websocket_manager = WebSocketManager() 