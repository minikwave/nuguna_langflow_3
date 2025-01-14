from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.api.services.workflow_manager import WorkflowManager
from app.api.services.websocket_manager import WebSocketManager
from app.api.services.history_manager import get_history, save_to_history

app = FastAPI()
workflow_manager = WorkflowManager()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/workflows/{workflow_id}/execute")
async def execute_workflow(workflow_id: str, inputs: dict):
    result = workflow_manager.execute_workflow(workflow_id, inputs)
    if "error" in result:
        raise HTTPException(status_code=400, detail=result["message"])
    save_to_history({"workflow_id": workflow_id, "inputs": inputs, "output": result["output"]})
    return result

@app.get("/api/history/")
async def history():
    return get_history()


# from fastapi import FastAPI
# from fastapi.middleware.cors import CORSMiddleware

# app = FastAPI()

# # CORS 설정
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# @app.post("/api/prompt/")
# async def process_prompt(prompt: str):
#     # 프롬프트를 SQL로 변환
#     sql_query = f"SELECT * FROM table WHERE condition = '{prompt}'"
#     return {"sql_query": sql_query}

# @app.get("/api/history/")
# async def get_history():
#     # 임시 히스토리 데이터
#     return ["Prompt 1 -> SQL 1", "Prompt 2 -> SQL 2"]
