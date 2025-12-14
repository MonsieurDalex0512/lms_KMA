from sqlalchemy import text
from app.database import engine

def add_phone_number_column():
    with engine.connect() as connection:
        with connection.begin():
            try:
                connection.execute(text("ALTER TABLE users ADD COLUMN phone_number VARCHAR"))
                print("Successfully added phone_number column to users table.")
            except Exception as e:
                print(f"Error adding column (might already exist): {e}")

if __name__ == "__main__":
    add_phone_number_column()
