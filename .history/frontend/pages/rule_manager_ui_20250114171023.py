import streamlit as st
import requests
from utils import set_page_config

set_page_config()

API_URL = "http://localhost:8000"

def render_rule_manager_ui():
    st.title("Rule Manager")

    rule_id = st.text_input("Rule ID:")
    keywords = st.text_area("Keywords (JSON format):")
    table = st.text_input("Table:")
    dimensions = st.text_area("Dimensions (JSON format):")
    metrics = st.text_area("Metrics (JSON format):")

    if st.button("Save Rule"):
        response = requests.post(f"{API_URL}/rules", json={
            "rule_id": rule_id,
            "keywords": eval(keywords),
            "table": table,
            "dimensions": eval(dimensions),
            "metrics": eval(metrics)
        })
        if response.status_code == 200:
            st.success("Rule saved successfully!")
        else:
            st.error(f"Error: {response.text}")


# import streamlit as st
# import requests

# API_URL = "http://localhost:8000"

# st.title("Rule Manager")

# rule_id = st.text_input("Rule ID:")
# keywords = st.text_area("Keywords (JSON format):")
# table = st.text_input("Table:")
# dimensions = st.text_area("Dimensions (JSON format):")
# metrics = st.text_area("Metrics (JSON format):")

# if st.button("Save Rule"):
#     rule_data = {
#         "rule_id": rule_id,
#         "keywords": eval(keywords),
#         "table": table,
#         "dimensions": eval(dimensions),
#         "metrics": eval(metrics),
#     }

#     # Langflow 워크플로우 실행
#     response = requests.post(f"{API_URL}/rules", json=rule_data)
#     if response.status_code == 200:
#         st.success("Rule saved successfully!")
#     else:
#         st.error(f"Error: {response.text}")


# # import streamlit as st
# # import requests

# # API_URL = "http://localhost:8000"

# # st.title("Rule Manager")

# # rule_id = st.text_input("Rule ID:")
# # keywords = st.text_area("Keywords (JSON format):")
# # table = st.text_input("Table:")
# # dimensions = st.text_area("Dimensions (JSON format):")
# # metrics = st.text_area("Metrics (JSON format):")

# # if st.button("Save Rule"):
# #     response = requests.post(f"{API_URL}/rules", json={
# #         "rule_id": rule_id,
# #         "keywords": eval(keywords),
# #         "table": table,
# #         "dimensions": eval(dimensions),
# #         "metrics": eval(metrics)
# #     })
# #     if response.status_code == 200:
# #         st.success("Rule saved successfully!")
# #     else:
# #         st.error(f"Error: {response.text}")
