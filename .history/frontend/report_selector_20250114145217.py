import streamlit as st
import requests
from langflow import execute_workflow

API_URL = "http://localhost:8000"

st.title("Report Selector")

report_type = st.selectbox("Report Type:", ["source_report", "page_report", "event_report"])
dimensions = st.text_area("Dimensions (JSON format):")
metrics = st.text_area("Metrics (JSON format):")
filters = st.text_area("Filters (JSON format):")

if st.button("Generate Report"):
    # Langflow 워크플로우 실행
    workflow_data = {
        "workflow": {
            "report_type": report_type,
            "dimensions": eval(dimensions),
            "metrics": eval(metrics),
            "filters": eval(filters),
        }
    }
    workflow_result = execute_workflow(workflow_data)

    # VectorDB에 결과 저장
    if workflow_result.get("status") == "success":
        st.success("Report generated successfully!")
        st.json(workflow_result.get("output"))

        # VectorDB에 저장 API 호출
        response = requests.post(f"{API_URL}/vectordb/store", json={"data": workflow_result.get("output")})
        if response.status_code == 200:
            st.success("Report saved to VectorDB!")
        else:
            st.error(f"Error saving to VectorDB: {response.text}")
    else:
        st.error("Failed to generate report!")


# import streamlit as st
# import requests

# API_URL = "http://localhost:8000"

# st.title("Report Selector")

# report_type = st.selectbox("Report Type:", ["source_report", "page_report", "event_report"])
# dimensions = st.text_area("Dimensions (JSON format):")
# metrics = st.text_area("Metrics (JSON format):")
# filters = st.text_area("Filters (JSON format):")

# if st.button("Generate Report"):
#     response = requests.post(f"{API_URL}/report-data", json={
#         "report_type": report_type,
#         "dimensions": eval(dimensions),
#         "metrics": eval(metrics),
#         "filters": eval(filters)
#     })
#     if response.status_code == 200:
#         st.success("Report generated successfully!")
#         st.json(response.json())
#     else:
#         st.error(f"Error: {response.text}")
     