from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.models.rule import Rule
from app.core.database import get_db_session

router = APIRouter()

@router.post("/rules")
def add_or_update_rule(rule_id: str, keywords: list, table: str, dimensions: list, metrics: list, db: Session = Depends(get_db_session)):
    """
    Add or update a rule in the database.
    """
    existing_rule = db.query(Rule).filter(Rule.rule_id == rule_id).first()
    if existing_rule:
        existing_rule.keywords = keywords
        existing_rule.table = table
