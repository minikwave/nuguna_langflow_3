from fastapi import APIRouter
from app.services.langflow_integration import list_nodes, add_node, delete_node

router = APIRouter()

@router.get("/nodes/")
async def get_nodes():
    return list_nodes()

@router.post("/nodes/")
async def create_node(node_data: dict):
    return add_node(node_data)

@router.delete("/nodes/{node_id}")
async def remove_node(node_id: int):
    return delete_node(node_id)
