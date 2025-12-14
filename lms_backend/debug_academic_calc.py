from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import Base, DATABASE_URL
from app.models.academic import Class, Enrollment, Grade
from app.models.academic_year import Semester, AcademicResult, AcademicYear
from app.models.user import Student
from app.utils.academic_calculator import calculate_and_save_semester_result

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def debug():
    print("--- CHECKING ACADEMIC RESULTS IN DB ---")
    results = db.query(AcademicResult).all()
    print(f"Total AcademicResults found: {len(results)}")
    for r in results:
        # Get semester info
        sem = db.query(Semester).get(r.semester_id)
        # Get student info
        stu = db.query(Student).get(r.student_id)
        print(f"  [Result ID: {r.id}] StudentID: {r.student_id}, Sem: {sem.code if sem else 'Unknown'}, GPA: {r.gpa}, CPA: {r.cpa}")
        
    print("\n--- CHECKING STUDENTS ---")
    students = db.query(Student).limit(5).all()
    for s in students:
         print(f"  Student UserID: {s.user_id}, Code: {s.student_code}")

if __name__ == "__main__":
    debug()
