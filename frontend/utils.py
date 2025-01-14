import streamlit as st

def set_page_config():
    """
    Set page configuration. Ensure this is the first Streamlit command.
    """
    if not hasattr(st, "_config_set"):
        st.set_page_config(
            page_title="Prompt Collaboration Platform",
            layout="wide",
            initial_sidebar_state="expanded",
            page_icon=":bar_chart:",
        )
        st._config_set = True

# import streamlit as st

# def set_page_config():
#     st.set_page_config(
#         page_title="Prompt Collaboration Platform",
#         layout="wide",
#         initial_sidebar_state="expanded",
#         page_icon=":bar_chart:",
#     )

# def set_page_icon():
#     st.set_page_icon(":bar_chart:")

# def set_page_title():
#     st.set_page_title("Prompt Collaboration Platform")

# def set_page_layout():
#     st.set_layout("wide")

# def set_page_sidebar_state():
#     st.set_sidebar_state("expanded")

