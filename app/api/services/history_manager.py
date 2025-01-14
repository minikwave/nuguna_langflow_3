import datetime

# 히스토리 저장소 (임시 메모리 기반, 실제로는 DB와 연결 필요)
history_store = []

def get_history():
    """히스토리 목록 반환"""
    return history_store

def save_to_history(data: dict):
    """새로운 히스토리 항목 저장"""
    timestamp = datetime.datetime.now().isoformat()
    history_entry = {"timestamp": timestamp, "data": data}
    history_store.append(history_entry)
    return {"status": "success", "entry": history_entry}
