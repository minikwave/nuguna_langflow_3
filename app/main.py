from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST, Counter
# from app.api.services.workflow_manager import WorkflowManager
from app.api.services.workflow_manager import router as workflow_router
from app.api.services.websocket_manager import ConnectionManager
from app.api.services.history_manager import get_history, save_to_history

app = FastAPI()
# workflow_manager = WorkflowManager()
websocket_manager = ConnectionManager()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# @app.post("/api/workflows/{workflow_id}/execute")
# async def execute_workflow(workflow_id: str, inputs: dict):
#     result = workflow_manager.execute_workflow(workflow_id, inputs)
#     if "error" in result:
#         raise HTTPException(status_code=400, detail=result["message"])
#     save_to_history({"workflow_id": workflow_id, "inputs": inputs, "output": result["output"]})
#     return result

# Prometheus 메트릭 설정
REQUEST_COUNT = Counter("request_count", "Total number of requests")

@app.middleware("http")
async def count_requests(request, call_next):
    REQUEST_COUNT.inc()
    response = await call_next(request)
    return response

@app.get("/metrics")
async def metrics():
    """
    Prometheus가 수집할 메트릭 데이터 반환.
    """
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

# 워크플로우 라우터 등록
app.include_router(workflow_router, prefix="/api/workflows", tags=["Workflows"])

@app.get("/api/history/")
async def history():
    return get_history()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket_manager.connect(websocket)
    try:
        while True:
            data = await websocket.receive_text()
            await websocket_manager.broadcast(data)
    except:
        websocket_manager.disconnect(websocket)

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
