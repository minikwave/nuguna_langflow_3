import sys
import os

# 프로젝트의 기본 경로를 PYTHONPATH에 추가
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

import streamlit as st
from utils import set_page_config
from components.navbar import render_navbar

# 페이지 구성 설정
set_page_config()

# 네비게이션 바 렌더링
render_navbar()

# 사이드바에서 페이지 선택
menu = st.sidebar.radio(
    "Navigation",
    ["Dashboard", "Nodes", "Workflows", "History", "Langflow Integration"]
)

# 페이지 렌더링
if menu == "Dashboard":
    from pages.1_Dashboard import render_dashboard
    render_dashboard()
elif menu == "Nodes":
    from pages.2_Nodes import render_nodes
    render_nodes()
elif menu == "Workflows":
    from pages.3_Workflows import render_workflows
    render_workflows()
elif menu == "History":
    from pages.4_History import render_history
    render_history()
elif menu == "Langflow Integration":
    from pages.5_Langflow import render_langflow
    render_langflow()



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
#     from pages.1_Dashboard import render_dashboard
#     render_dashboard()
# elif menu == "Nodes":
#     from pages.2_Nodes import render_nodes
#     render_nodes()
# elif menu == "Workflows":
#     from pages.3_Workflows import render_workflows
#     render_workflows()
# elif menu == "History":
#     from pages.4_History import render_history
#     render_history()
# elif menu == "Langflow Integration":
#     from pages.5_Langflow import render_langflow
#     render_langflow()


# # import streamlit as st
# # from utils import set_page_config
# # from components.navbar import render_navbar

# # # 페이지 구성 설정
# # set_page_config()

# # # 네비게이션 바 렌더링
# # render_navbar()

# # # 사이드바에서 페이지 선택
# # menu = st.sidebar.radio("Navigation", ["Dashboard", "Nodes", "Workflows"])

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
