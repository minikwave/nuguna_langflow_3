import streamlit as st

def render_navbar():
    st.markdown(
        """
        <style>
        .navbar {
            background-color: #f8f9fa;
            padding: 10px;
            font-size: 18px;
        }
        </style>
        <div class="navbar">
            <b>Prompt Collaboration Platform</b>
        </div>
        """,
        unsafe_allow_html=True,
    )
