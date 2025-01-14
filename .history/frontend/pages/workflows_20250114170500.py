import streamlit as st
import requests
from components.navbar import render_navbar
render_navbar()

def render_workflows():
    st.title("Workflow Tester")

    workflow_id = st.text_input("Workflow ID")
    if st.button("Load Workflow"):
        try:
            workflow = requests.get(f"http://localhost:8000/workflow/{workflow_id}").json()
            st.json(workflow)
        except Exception as e:
            st.error(f"Error loading workflow: {e}")

    st.header("Execute Workflow")
    execution_data = st.text_area("Execution Data")
    if st.button("Run Workflow"):
        try:
            result = requests.post(
                "http://localhost:8000/workflow/execute/",
                json={"data": execution_data}
            )
            st.write(result.json())
        except Exception as e:
            st.error(f"Error executing workflow: {e}")


# import streamlit as st
# import requests

# def render_workflows():
#     st.title("Workflow Tester")

#     workflow_id = st.text_input("Workflow ID")
#     if st.button("Load Workflow"):
#         workflow = requests.get(f"http://localhost:8000/workflow/{workflow_id}").json()
#         st.json(workflow)

#     st.header("Execute Workflow")
#     execution_data = st.text_area("Execution Data")
#     if st.button("Run Workflow"):
#         result = requests.post("http://localhost:8000/workflow/execute/", json={"data": execution_data})
#         st.write(result.json())
