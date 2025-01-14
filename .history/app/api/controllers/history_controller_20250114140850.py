from fastapi import APIRouter
from app.services.history_manager import get_history, save_to_history

router = APIRouter()

@router.get("/history/")
async def fetch_history():
    return get_history()

@router.post("/history/")
async def record_history(data: dict):
    return save_to_history(data)
