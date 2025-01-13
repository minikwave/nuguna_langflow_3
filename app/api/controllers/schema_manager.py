from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from app.models.table_schema import TableSchema
from app.core.database import get_db_session

router = APIRouter()

@router.post("/table-schema")
def add_or_update_table_schema(table_name: str, schema: dict, db: Session = Depends(get_db_session)):
    """
    Add or update a table schema in the database.
    """
    existing_schema = db.query(TableSchema).filter(TableSchema.table_name == table_name).first()
    if existing_schema:
        existing_schema.schema = schema
    else:
        new_schema = TableSchema(table_name=table_name, schema=schema)
        db.add(new_schema)
    db.commit()
    return {"status": "success", "table_name": table_name}

@router.get("/table-schema/{table_name}")
def get_table_schema(table_name: str, db: Session = Depends(get_db_session)):
    """
    Fetch the schema for a specific table.
    """
    schema = db.query(TableSchema).filter(TableSchema.table_name == table_name).first()
    if not schema:
        raise HTTPException(status_code=404, detail="Table schema not found.")
    return schema
