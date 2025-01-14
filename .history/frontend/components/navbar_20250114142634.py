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
            <b>Prompt Collaboration Platform</b> |
            <a href="http://localhost:7860" target="_blank">Langflow GUI</a>
        </div>
        """,
        unsafe_allow_html=True,
    )


# import streamlit as st

# def render_navbar():
#     st.markdown(
#         """
#         <style>
#         .navbar {
#             background-color: #f8f9fa;
#             padding: 10px;
#             font-size: 18px;
#         }
#         </style>
#         <div class="navbar">
#             <b>Prompt Collaboration Platform</b> |
#             <a href="http://localhost:7860" target="_blank">Langflow GUI</a>
#         </div>
#         """,
#         unsafe_allow_html=True,
#     )
