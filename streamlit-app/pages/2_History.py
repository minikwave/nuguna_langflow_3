import streamlit as st
import requests

st.title("History Viewer")
response = requests.get("http://localhost:8000/api/history/")
if response.status_code == 200:
    history = response.json()
    for index, item in enumerate(history):
        st.write(f"{index + 1}. {item}")
else:
    st.error("Failed to fetch history.")
