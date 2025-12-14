from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.database import DATABASE_URL
from app.models.academic import Class
from app.models.academic_year import Semester

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def diagnose():
    print("--- DIAGNOSING DATA CONSISTENCY ---")
    
    # 1. Get all Semesters
    semesters = db.query(Semester).all()
    sem_codes = {s.code: s for s in semesters}
    print(f"Defined Semesters ({len(semesters)}):")
    for s in semesters:
        print(f"  ID: {s.id}, Code: '{s.code}', Name: '{s.name}'")
        
    # 2. Check Classes
    classes = db.query(Class).all()
    print(f"\nScanning Classes ({len(classes)}):")
    mismatch_count = 0
    valid_count = 0
    
    for c in classes:
        cls_sem = c.semester
        if cls_sem not in sem_codes:
            mismatch_count += 1
            print(f"  [MISMATCH] Class ID {c.id} ({c.code}) has semester '{cls_sem}' -> NO MATCH in Semesters!")
        else:
            valid_count += 1
            
    print(f"\nSummary: {valid_count} Valid Matches, {mismatch_count} Mismatches.")
    
    if mismatch_count > 0:
        print("CONCLUSION: Data mismatch prevents academic result calculation.")
    else:
        print("CONCLUSION: Data codes align. Problem is likely elsewhere (Trigger or Logic).")

if __name__ == "__main__":
    diagnose()
