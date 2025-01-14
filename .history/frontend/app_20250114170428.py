import streamlit as st
from utils import set_page_config
from components.navbar import render_navbar
import importlib

# 페이지 구성 설정
set_page_config()

# 네비게이션 바 렌더링
render_navbar()

# 사이드바에서 페이지 선택
menu = st.sidebar.radio(
    "Navigation",
    [
        "Dashboard",
        "Nodes",
        "Workflows",
        "History",
        "Langflow Integration",
        "Report Selector",
        "Rule Manager",
        "Schema Manager",
    ]
)

# 페이지 렌더링
def load_page(page_name):
    try:
        page = importlib.import_module(f"pages.{page_name.lower().replace(' ', '_')}")
        page_function = getattr(page, f"render_{page_name.lower().replace(' ', '_')}")
        page_function()
    except ModuleNotFoundError:
        st.error(f"Page '{page_name}' not found.")

load_page(menu)


# import streamlit as st
# from utils import set_page_config
# from components.navbar import render_navbar

# # 페이지 구성 설정
# set_page_config()

# # 네비게이션 바 렌더링
# render_navbar()

# # 사이드바에서 페이지 선택
# menu = st.sidebar.radio(
#     "Navigation",
#     ["Dashboard", "Nodes", "Workflows", "History", "Langflow Integration"]
# )

# # 페이지 렌더링
# if menu == "Dashboard":
#     from pages.dashboard import render_dashboard
#     render_dashboard()
# elif menu == "Nodes":
#     from pages.nodes import render_nodes
#     render_nodes()
# elif menu == "Workflows":
#     from pages.workflows import render_workflows
#     render_workflows()
# elif menu == "History":
#     from pages.history import render_history
#     render_history()
# elif menu == "Langflow Integration":
#     from pages.langflow import render_langflow
#     render_langflow()


# # import streamlit as st
# # from utils import set_page_config
# # from components.navbar import render_navbar

# # # 페이지 구성 설정
# # set_page_config()

# # # 네비게이션 바 렌더링
# # render_navbar()

# # # 사이드바에서 페이지 선택
# # menu = st.sidebar.radio(
# #     "Navigation",
# #     ["Dashboard", "Nodes", "Workflows", "History", "Langflow Integration"]
# # )

# # # 페이지 렌더링
# # if menu == "Dashboard":
# #     from pages.1_Dashboard import render_dashboard
# #     render_dashboard()
# # elif menu == "Nodes":
# #     from pages.2_Nodes import render_nodes
# #     render_nodes()
# # elif menu == "Workflows":
# #     from pages.3_Workflows import render_workflows
# #     render_workflows()
# # elif menu == "History":
# #     from pages.4_History import render_history
# #     render_history()
# # elif menu == "Langflow Integration":
# #     from pages.5_Langflow import render_langflow
# #     render_langflow()


# # # import streamlit as st
# # # from utils import set_page_config
# # # from components.navbar import render_navbar

# # # # 페이지 구성 설정
# # # set_page_config()

# # # # 네비게이션 바 렌더링
# # # render_navbar()

# # # # 사이드바에서 페이지 선택
# # # menu = st.sidebar.radio("Navigation", ["Dashboard", "Nodes", "Workflows"])

# # # # 페이지 렌더링
# # # if menu == "Dashboard":
# # #     from pages.1_Dashboard import render_dashboard
# # #     render_dashboard()
# # # elif menu == "Nodes":
# # #     from pages.2_Nodes import render_nodes
# # #     render_nodes()
# # # elif menu == "Workflows":
# # #     from pages.3_Workflows import render_workflows
# # #     render_workflows()
