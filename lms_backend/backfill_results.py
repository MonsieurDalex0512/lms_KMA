from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime
from app.database import DATABASE_URL
from app.models.user import Student, User, UserRole
from app.models.academic_year import Semester, AcademicResult

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def backfill():
    
    active_sem = db.query(Semester).filter(Semester.is_active == True).first()
    if not active_sem:
        active_sem = db.query(Semester).order_by(Semester.start_date.desc()).first()
        
    if not active_sem:
        print("ERROR: No semesters found in DB.")
        return

    print(f"Target Semester: {active_sem.code} ({active_sem.name})")

    students = db.query(Student).all()
    print(f"Checking {len(students)} students...")
    
    count = 0
    for stu in students:
        exists = db.query(AcademicResult).filter(
            AcademicResult.student_id == stu.user_id,
            AcademicResult.semester_id == active_sem.id
        ).first()

        if not exists:
            print(f"Creating default result for Student {stu.student_code} (User {stu.user_id})")
            new_res = AcademicResult(
                student_id=stu.user_id,
                semester_id=active_sem.id,
                gpa=0.0,
                cpa=0.0,
                total_credits=0,
                completed_credits=0,
                failed_credits=0,
                cumulative_credits=0,
                calculated_at=datetime.now()
            )
            db.add(new_res)
            count += 1
            
    db.commit()
    print(f"\nSUCCESS: Created {count} missing academic results.")

if __name__ == "__main__":
    backfill()
