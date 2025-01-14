from langchain.vectorstores import FAISS
from langchain.embeddings import OpenAIEmbeddings
import os

class VectorDBManager:
    def __init__(self, db_path="vectordb"):
        self.db_path = db_path
        self.vectorstore = self._load_or_initialize_db()

    def _load_or_initialize_db(self):
        if os.path.exists(self.db_path):
            return FAISS.load_local(self.db_path)
        return FAISS(OpenAIEmbeddings(), [])

    def add_prompt(self, prompt: str, response: str):
        """Prompt와 응답을 VectorDB에 추가"""
        self.vectorstore.add_texts([prompt], metadatas=[{"response": response}])

    def query(self, query_text: str):
        """VectorDB 검색"""
        return self.vectorstore.similarity_search(query_text, k=3)
