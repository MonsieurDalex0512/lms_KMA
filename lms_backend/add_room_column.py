from app.database import engine
from sqlalchemy import text

def add_room_column():
    with engine.connect() as conn:
        try:
            conn.execute(text("ALTER TABLE classes ADD COLUMN room VARCHAR"))
            conn.commit()
            print("Successfully added 'room' column to 'classes' table.")
        except Exception as e:
            print(f"Error adding column (maybe it already exists): {e}")

if __name__ == "__main__":
    add_room_column()
