from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models.workflow import Workflow
from app.core.database import get_db_session
from app.api.services.workflow_executor import WorkflowExecutor

router = APIRouter()

@router.post("/workflows")
def add_workflow(workflow_id: str, name: str, description: str, workflow_data: dict, db: Session = Depends(get_db_session)):
    """
    워크플로우를 추가하거나 업데이트합니다.
    """
    existing_workflow = db.query(Workflow).filter(Workflow.id == workflow_id).first()
    if existing_workflow:
        existing_workflow.name = name
        existing_workflow.description = description
        existing_workflow.workflow_data = workflow_data
    else:
        new_workflow = Workflow(
            id=workflow_id,
            name=name,
            description=description,
            workflow_data=workflow_data
        )
        db.add(new_workflow)
    db.commit()
    return {"status": "success", "workflow_id": workflow_id}

@router.get("/workflows/{workflow_id}")
def get_workflow(workflow_id: str, db: Session = Depends(get_db_session)):
    """
    특정 워크플로우를 ID로 조회합니다.
    """
    workflow = db.query(Workflow).filter(Workflow.id == workflow_id).first()
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found.")
    return workflow

@router.delete("/workflows/{workflow_id}")
def delete_workflow(workflow_id: str, db: Session = Depends(get_db_session)):
    """
    특정 워크플로우를 삭제합니다.
    """
    workflow = db.query(Workflow).filter(Workflow.id == workflow_id).first()
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found.")
    db.delete(workflow)
    db.commit()
    return {"status": "success", "workflow_id": workflow_id}

@router.get("/workflows")
def list_workflows(db: Session = Depends(get_db_session)):
    """
    데이터베이스의 모든 워크플로우를 나열합니다.
    """
    workflows = db.query(Workflow).all()
    return workflows

@router.post("/workflows/{workflow_id}/execute")
def execute_workflow(workflow_id: str, inputs: dict, db: Session = Depends(get_db_session)):
    """
    워크플로우를 실행합니다.
    """
    workflow = db.query(Workflow).filter(Workflow.id == workflow_id).first()
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found.")
    
    executor = WorkflowExecutor()
    result = executor.execute_workflow(workflow_id, inputs)
    if result.get("status") == "error":
        raise HTTPException(status_code=500, detail=result.get("message"))
    return result



# from typing import List
# from fastapi import WebSocket

# class ConnectionManager:
#     def __init__(self):
#         self.active_connections: List[WebSocket] = []

#     async def connect(self, websocket: WebSocket):
#         await websocket.accept()
#         self.active_connections.append(websocket)

#     def disconnect(self, websocket: WebSocket):
#         self.active_connections.remove(websocket)

#     async def broadcast(self, message: str):
#         for connection in self.active_connections:
#             await connection.send_text(message)
