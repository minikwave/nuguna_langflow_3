import importlib

def load_plugin(plugin_path: str):
    """플러그인 로드"""
    try:
        module = importlib.import_module(plugin_path)
        return module
    except ImportError:
        return None
