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
        existing_rule.dimensions = dimensions
        existing_rule.metrics = metrics
    else:
        new_rule = Rule(
            rule_id=rule_id,
            keywords=keywords,
            table=table,
            dimensions=dimensions,
            metrics=metrics
        )
        db.add(new_rule)
    db.commit()
    return {"status": "success", "rule_id": rule_id}

@router.get("/rules/{rule_id}")
def get_rule(rule_id: str, db: Session = Depends(get_db_session)):
    """
    Fetch a specific rule by ID.
    """
    rule = db.query(Rule).filter(Rule.rule_id == rule_id).first()
    if not rule:
        raise HTTPException(status_code=404, detail="Rule not found.")
    return rule
