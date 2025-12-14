"""
Script: Tạo table cumulative_results và init data
"""
from sqlalchemy import create_engine, inspect
from app.database import get_db, engine, Base
from app.models.cumulative_result import CumulativeResult
from app.models.user import Student
from app.utils.academic_calculator import calculate_cumulative_cpa_from_courses

def create_tables():
    """Tạo tất cả tables"""
    print("Creating all tables...")
    Base.metadata.create_all(bind=engine)
    print("✓ Tables created")

def check_table_exists():
    """Kiểm tra table cumulative_results có tồn tại không"""
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    
    print(f"\n📋 Existing tables: {tables}\n")
    
    if 'cumulative_results' in tables:
        print("✓ Table cumulative_results EXISTS")
        return True
    else:
        print("✗ Table cumulative_results NOT FOUND")
        return False

def init_cumulative_results():
    """Khởi tạo CPA cho tất cả sinh viên"""
    db = next(get_db())
    
    students = db.query(Student).all()
    print(f"\nInitializing CPA for {len(students)} students...\n")
    
    for student in students:
        try:
            cpa, registered, completed, failed = calculate_cumulative_cpa_from_courses(student.user_id, db)
            
            existing = db.query(CumulativeResult).filter(
                CumulativeResult.student_id == student.user_id
            ).first()
            
            if existing:
                existing.cpa = cpa
                existing.total_registered_credits = registered
                existing.total_completed_credits = completed
                existing.total_failed_credits = failed
                print(f"  ↻ Updated student {student.student_code}: CPA={cpa}")
            else:
                new_record = CumulativeResult(
                    student_id=student.user_id,
                    cpa=cpa,
                    total_registered_credits=registered,
                    total_completed_credits=completed,
                    total_failed_credits=failed
                )
                db.add(new_record)
                print(f"  + Created student {student.student_code}: CPA={cpa}")
            
            db.commit()
        except Exception as e:
            print(f"  ✗ Error for student {student.student_code}: {e}")
            db.rollback()
    
    print("\n✓ Initialization complete")
    db.close()

if __name__ == "__main__":
    print("=== Setup Cumulative Results ===\n")
    
    # Step 1: Create tables
    create_tables()
    
    # Step 2: Check if table exists
    exists = check_table_exists()
    
    # Step 3: Initialize data
    if exists:
        init_cumulative_results()
    else:
        print("\n✗ Cannot initialize - table not found")
