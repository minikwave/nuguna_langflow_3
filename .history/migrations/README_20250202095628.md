# Database Migrations

This directory contains database migration scripts.

## Usage
- Create new migration: `alembic revision -m "description"`
- Run migrations: `alembic upgrade head`
- Rollback: `alembic downgrade -1` 