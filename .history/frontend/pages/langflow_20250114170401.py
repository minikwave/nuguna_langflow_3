import streamlit as st
import requests

def render_langflow():
    st.title("Langflow Integration")
    st.markdown("Langflow는 강력한 워크플로우 GUI를 제공합니다.")

    if st.button("Open Langflow GUI"):
        st.markdown("[Langflow GUI](http://localhost:7860)")

    st.header("Test Langflow Workflow")
    workflow_json = st.text_area("Paste your workflow JSON here", height=300)

    if st.button("Test Workflow"):
        try:
            response = requests.post(
                "http://localhost:7860/api/v1/workflows", json={"workflow": workflow_json}
            )
            if response.status_code == 200:
                st.success("Workflow executed successfully!")
                st.json(response.json())
            else:
                st.error(f"Error executing workflow: {response.text}")
        except requests.exceptions.RequestException as e:
            st.error(f"Request failed: {e}")


# import streamlit as st
# import requests

# def render_langflow():
#     st.title("Langflow Integration")

#     st.markdown(
#         """
#         Langflow는 강력한 워크플로우 GUI를 제공합니다.
#         아래 버튼을 클릭하여 Langflow GUI를 열거나, JSON 기반의 워크플로우를 테스트하세요.
#         """
#     )

#     # Langflow GUI 열기
#     if st.button("Open Langflow GUI"):
#         st.markdown("[Langflow GUI](http://localhost:7860)")

#     # JSON 워크플로우 테스트
#     st.header("Test Langflow Workflow")
#     workflow_json = st.text_area("Paste your workflow JSON here", height=300)
#     if st.button("Test Workflow"):
#         try:
#             response = requests.post(
#                 "http://localhost:7860/api/v1/workflows", json={"workflow": workflow_json}
#             )
#             if response.status_code == 200:
#                 st.success("Workflow executed successfully!")
#                 st.json(response.json())
#             else:
#                 st.error(f"Error executing workflow: {response.text}")
#         except requests.exceptions.RequestException as e:
#             st.error(f"Request failed: {e}")
