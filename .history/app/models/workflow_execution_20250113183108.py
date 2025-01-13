from sqlalchemy import Column, String, Integer, DateTime, JSON
from app.core.database import Base
from datetime import datetime

class WorkflowExecution(Base):
    __tablename__ = "workflow_executions"

    id = Column(Integer, primary_key=True, index=True)
    workflow_id = Column(String, index=True)
    execution_data = Column(JSON)
    response_time_ms = Column(Integer)
    timestamp = Column(DateTime, default=datetime.now)
