from sqlalchemy import Column, String, JSON
from app.core.database import Base

class Workflow(Base):
    __tablename__ = "workflows"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String)
    workflow_data = Column(JSON, nullable=False)
