import streamlit as st
import pandas as pd
from app.api.services.prompt_handler import PromptHandler

def render_dashboard():
    st.title("Dashboard")

    # 현재 모드 확인
    hybrid_mode = st.checkbox("Enable Hybrid Mode (Langflow + VectorDB)", value=False)

    prompt = st.text_area("Enter your prompt:", height=200)

    if st.button("Submit"):
        handler = PromptHandler()
        
        # 하이브리드 모드 활성화
        handler.langflow_enabled = hybrid_mode
        handler.vectordb_enabled = hybrid_mode

        results = handler.handle_prompt(prompt)

        # Langflow 결과 표시
        if handler.langflow_enabled:
            st.header("Langflow Result")
            st.json(results.get("langflow_result"))

        # VectorDB 결과 표시
        if handler.vectordb_enabled:
            st.header("VectorDB Results")
            st.json(results.get("vectordb_results"))

        # 하이브리드 결과 표시
        if hybrid_mode:
            st.header("Combined Results")
            st.json(results.get("combined_results"))

        # SQL 결과 표시
        st.header("SQL Result Example")
        sql_example = {"Column1": [1, 2, 3], "Column2": ["A", "B", "C"]}
        df = pd.DataFrame(sql_example)
        st.dataframe(df)



# import streamlit as st
# import pandas as pd
# from app.api.services.prompt_handler import HybridPromptHandler

# def render_dashboard():
#     st.title("Dashboard")

#     # Langflow와 VectorDB 동시 활용 옵션
#     hybrid_mode = st.checkbox("Enable Hybrid Mode (Langflow + VectorDB)", value=True)

#     # 프롬프트 입력
#     prompt = st.text_area("Enter your prompt", height=200)

#     if st.button("Submit"):
#         handler = HybridPromptHandler()
#         if hybrid_mode:
#             result = handler.handle_prompt(prompt)
#         else:
#             result = {"langflow_result": handler.handle_prompt(prompt)["langflow_result"]}

#         # Langflow 결과 표시
#         st.header("Langflow Result")
#         st.json(result.get("langflow_result"))

#         # VectorDB 결과 표시
#         if hybrid_mode:
#             st.header("VectorDB Results")
#             st.json(result.get("vectordb_results"))

#         # SQL 결과 표시
#         st.header("SQL Result Example")
#         sql_example = {"Column1": [1, 2, 3], "Column2": ["A", "B", "C"]}
#         df = pd.DataFrame(sql_example)
#         st.dataframe(df)


# # import streamlit as st
# # import requests

# # # def render_dashboard():
# # #     st.title("Dashboard")
# # #     prompt = st.text_area("Enter your prompt", height=200)
# # #     if st.button("Generate SQL"):
# # #         response = requests.post("http://localhost:8000/api/prompt/", json={"prompt": prompt})
# # #         st.code(response.json().get("sql_query", "Error generating SQL"))

# # import pandas as pd

# # def render_dashboard():
# #     st.title("Dashboard")
# #     prompt = st.text_area("Enter your prompt", height=200)
# #     if st.button("Generate SQL"):
# #         response = requests.post("http://localhost:8000/api/prompt/", json={"prompt": prompt})
# #         sql_query = response.json().get("sql_query", "Error generating SQL")
# #         st.code(sql_query)

# #         # Example SQL Result
# #         data = {"Column1": [1, 2, 3], "Column2": ["A", "B", "C"]}
# #         df = pd.DataFrame(data)
# #         st.dataframe(df)
