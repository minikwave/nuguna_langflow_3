import streamlit as st
import requests

st.set_page_config(page_title="Prompt Collaboration Platform", layout="wide")

st.title("Prompt Collaboration Platform")
st.sidebar.title("Navigation")
menu = st.sidebar.radio("Go to", ["Dashboard", "History", "Settings"])

if menu == "Dashboard":
    st.header("Dashboard")
    prompt = st.text_area("Enter your prompt", height=200)
    if st.button("Generate SQL"):
        response = requests.post("http://localhost:8000/api/prompt/", json={"prompt": prompt})
        st.code(response.json().get("sql_query", "Error generating SQL"))
elif menu == "History":
    st.header("History Viewer")
    history = requests.get("http://localhost:8000/api/history/").json()
    for item in history:
        st.write(item)
elif menu == "Settings":
    st.header("Settings")
    st.write("Manage your configurations and rules.")
