history_store = []

def get_history():
    return history_store

def save_to_history(data: dict):
    history_store.append(data)
    return {"status": "success"}
