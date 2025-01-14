from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/api/prompt/")
async def process_prompt(prompt: str):
    # 프롬프트를 SQL로 변환
    sql_query = f"SELECT * FROM table WHERE condition = '{prompt}'"
    return {"sql_query": sql_query}

@app.get("/api/history/")
async def get_history():
    # 임시 히스토리 데이터
    return ["Prompt 1 -> SQL 1", "Prompt 2 -> SQL 2"]
