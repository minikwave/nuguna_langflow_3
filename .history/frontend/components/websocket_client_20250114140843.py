import asyncio
import websockets

async def websocket_client(uri: str):
    async with websockets.connect(uri) as websocket:
        while True:
            response = await websocket.recv()
            print(f"Received: {response}")
