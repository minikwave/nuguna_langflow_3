import asyncio
from services.langflow.client import LangflowClient
from services.langflow.templates import create_sql_flow_template
from services.langflow.components.sql_validator import SQLValidator

async def initialize_langflow():
    """Langflow 초기 설정"""
    client = LangflowClient()
    
    # 로그인 및 토큰 획득
    token = await client.login()
    
    # 커스텀 컴포넌트 등록
    await client.create_component({
        "code": SQLValidator.__code__,
        "name": "SQLValidator",
        "display_name": SQLValidator.display_name,
        "description": SQLValidator.description
    })
    
    # 기본 워크플로우 템플릿 생성
    template = create_sql_flow_template()
    flow = await client.create_flow(template)
    
    print(f"Langflow initialization completed. Flow ID: {flow['id']}")

if __name__ == "__main__":
    asyncio.run(initialize_langflow()) 