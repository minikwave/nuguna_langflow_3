from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.models.workflow import Workflow
from app.core.database import get_db_session

router = APIRouter()

@router.post("/workflows")
def add_workflow(workflow_id: str, name: str, description: str, workflow_data: dict, db: Session = Depends(get_db_session)):
    """
    Add or update a workflow in the database.
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
    Fetch a specific workflow by ID.
    """
    workflow = db.query(Workflow).filter(Workflow.id == workflow_id).first()
    if not workflow:
        raise HTTPException(status_code=404, detail="Workflow not found.")
    return workflow
