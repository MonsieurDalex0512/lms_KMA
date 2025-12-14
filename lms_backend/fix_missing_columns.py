from sqlalchemy import text
from app.database import engine

def add_missing_columns():
    columns = [
        ("start_week", "INTEGER"),
        ("end_week", "INTEGER"),
        ("day_of_week", "INTEGER"),
        ("start_period", "INTEGER"),
        ("end_period", "INTEGER")
    ]
    
    with engine.connect() as connection:
        with connection.begin():
            for col_name, col_type in columns:
                try:
                    print(f"Adding column {col_name}...")
                    connection.execute(text(f"ALTER TABLE classes ADD COLUMN {col_name} {col_type}"))
                    print(f"Successfully added {col_name} column to classes table.")
                except Exception as e:
                    print(f"Error adding column {col_name} (might already exist): {e}")

if __name__ == "__main__":
    add_missing_columns()
