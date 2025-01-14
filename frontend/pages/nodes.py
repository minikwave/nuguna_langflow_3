import streamlit as st
import requests

def render_nodes():
    st.title("Node Management")

    nodes = requests.get("http://localhost:8000/nodes/").json()

    st.header("Existing Nodes")
    for node in nodes:
        st.write(node)

    st.header("Add a New Node")
    node_name = st.text_input("Node Name")
    node_params = st.text_area("Node Parameters")
    if st.button("Add Node"):
        response = requests.post("http://localhost:8000/nodes/", json={"name": node_name, "params": node_params})
        st.success("Node added successfully!" if response.status_code == 200 else "Failed to add node.")
