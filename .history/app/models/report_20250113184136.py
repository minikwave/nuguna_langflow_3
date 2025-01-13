from sqlalchemy import Column, String, JSON
from app.core.database import Base

class Report(Base):
    __tablename__ = "reports"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String)
    report_data = Column(JSON, nullable=False)
