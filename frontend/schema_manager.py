import streamlit as st
import requests

API_URL = "http://localhost:8000"

st.title("Table Schema Manager")

table_name = st.text_input("Table Name:")
schema = st.text_area("Schema (JSON format):")

if st.button("Save Schema"):
    response = requests.post(f"{API_URL}/table-schema", json={"table_name": table_name, "schema": eval(schema)})
    if response.status_code == 200:
        st.success("Schema saved successfully!")
    else:
        st.error(f"Error: {response.text}")
