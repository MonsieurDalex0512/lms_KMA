
from sqlalchemy import create_engine, text
from app.core.config import settings

def migrate():
    engine = create_engine(settings.DATABASE_URL)
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT TRUE"))
            print("Successfully added is_active column")
            conn.commit()
        except Exception as e:
            print(f"Error (maybe column exists): {e}")

if __name__ == "__main__":
    migrate()
