from sqlalchemy import create_engine, text
from app.database import DATABASE_URL

def migrate():
    engine = create_engine(DATABASE_URL)
    with engine.connect() as conn:
        try:
            # Add new columns to classes table
            conn.execute(text("ALTER TABLE classes ADD COLUMN IF NOT EXISTS start_week INTEGER"))
            conn.execute(text("ALTER TABLE classes ADD COLUMN IF NOT EXISTS end_week INTEGER"))
            conn.execute(text("ALTER TABLE classes ADD COLUMN IF NOT EXISTS day_of_week INTEGER")) # 2=Monday, 3=Tuesday... or 0=Mon
            conn.execute(text("ALTER TABLE classes ADD COLUMN IF NOT EXISTS start_period INTEGER"))
            conn.execute(text("ALTER TABLE classes ADD COLUMN IF NOT EXISTS end_period INTEGER"))
            
            # Additional text field for human friendly display if needed, but above is enough for logic
            print("Migration successful: Added columns to classes table.")
            conn.commit()
        except Exception as e:
            print(f"Migration failed: {e}")

if __name__ == "__main__":
    migrate()
