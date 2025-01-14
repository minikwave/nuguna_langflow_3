from fastapi import APIRouter
from app.api.services.workflow_manager import load_workflow, execute_workflow

router = APIRouter()

@router.get("/workflow/{workflow_id}")
async def fetch_workflow(workflow_id: str):
    return load_workflow(workflow_id)

@router.post("/workflow/execute/")
async def run_workflow(data: dict):
    return execute_workflow(data)
