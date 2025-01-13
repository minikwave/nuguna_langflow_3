import streamlit as st
import requests

API_URL = "http://localhost:8000"

st.title("Report Selector")

report_type = st.selectbox("Report Type:", ["source_report", "page_report", "event_report"])
dimensions = st.text_area("Dimensions (JSON format):")
metrics = st.text_area("Metrics (JSON format):")
filters = st.text_area("Filters (JSON format):")

if st.button("Generate Report"):
    response = requests.post(f"{API_URL}/report-data", json={
        "report_type": report_type,
        "dimensions": eval(dimensions),
        "metrics": eval(metrics),
        "filters": eval(filters)
    })
    if response.status_code == 200:
        st.success("Report generated successfully!")
        st.json(response.json())
    else:
        st.error(f"Error: {response.text}")
     