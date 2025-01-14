from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, List
from app.api.services.websocket_manager import ConnectionManager

router = APIRouter()
manager = ConnectionManager()

# WebSocket 연결된 클라이언트를 관리
connected_clients: Dict[str, List[WebSocket]] = {}

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"Message: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@router.websocket("/ws/{channel}")
async def websocket_endpoint(websocket: WebSocket, channel: str):
    """
    WebSocket endpoint for real-time updates.
    """
    await websocket.accept()
    if channel not in connected_clients:
        connected_clients[channel] = []
    connected_clients[channel].append(websocket)

    try:
        while True:
            data = await websocket.receive_text()
            for client in connected_clients[channel]:
                if client != websocket:
                    await client.send_text(data)
    except WebSocketDisconnect:
        connected_clients[channel].remove(websocket)
        if not connected_clients[channel]:
            del connected_clients[channel]
