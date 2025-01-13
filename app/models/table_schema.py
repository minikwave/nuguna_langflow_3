from sqlalchemy import Column, String, JSON
from app.core.database import Base

class TableSchema(Base):
    __tablename__ = "table_schemas"

    table_name = Column(String, primary_key=True, index=True)
    schema = Column(JSON, nullable=False)
