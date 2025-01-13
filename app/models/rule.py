from sqlalchemy import Column, String, JSON
from app.core.database import Base

class Rule(Base):
    __tablename__ = "rules"

    rule_id = Column(String, primary_key=True, index=True)
    keywords = Column(JSON, nullable=False)
    table = Column(String, nullable=False)
    dimensions = Column(JSON, nullable=False)
    metrics = Column(JSON, nullable=False)
