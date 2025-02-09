from sqlalchemy import create_engine, text
from src.models import Base, User

def seed_database():
    engine = create_engine('postgresql://user:password@localhost:5434/text_to_sql')
    Base.metadata.create_all(engine)
    
    with engine.connect() as conn:
        # Check if admin user exists
        result = conn.execute(text("SELECT * FROM users WHERE username = 'admin'")).fetchone()
        if not result:
            conn.execute(text('''
                INSERT INTO users (username, email)
                VALUES ('admin', 'admin@example.com')
            '''))
            conn.commit()

if __name__ == '__main__':
    seed_database()
