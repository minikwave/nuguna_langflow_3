import streamlit as st
import requests

# def render_dashboard():
#     st.title("Dashboard")
#     prompt = st.text_area("Enter your prompt", height=200)
#     if st.button("Generate SQL"):
#         response = requests.post("http://localhost:8000/api/prompt/", json={"prompt": prompt})
#         st.code(response.json().get("sql_query", "Error generating SQL"))

import pandas as pd

def render_dashboard():
    st.title("Dashboard")
    prompt = st.text_area("Enter your prompt", height=200)
    if st.button("Generate SQL"):
        response = requests.post("http://localhost:8000/api/prompt/", json={"prompt": prompt})
        sql_query = response.json().get("sql_query", "Error generating SQL")
        st.code(sql_query)

        # Example SQL Result
        data = {"Column1": [1, 2, 3], "Column2": ["A", "B", "C"]}
        df = pd.DataFrame(data)
        st.dataframe(df)
