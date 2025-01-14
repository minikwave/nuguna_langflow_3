import streamlit as st
import requests

def render_history():
    st.title("History Viewer")
    history = requests.get("http://localhost:8000/history/").json()
    for record in history:
        st.write(record)
