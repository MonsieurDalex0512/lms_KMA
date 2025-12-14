"""
Script để recalculate và cleanup tất cả AcademicResult
- Xóa các AcademicResult không còn enrollments (total_credits = 0)
- Recalculate lại tất cả semester results cho tất cả students
"""
import sys
import io

# Fix encoding cho Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import Student
from app.models.academic_year import Semester, AcademicResult
from app.utils.academic_calculator import calculate_and_save_semester_result, update_cumulative_result

def recalculate_all_academic_results():
    """
    Recalculate tất cả AcademicResult cho tất cả students và semesters
    - Xóa AcademicResult không còn enrollments
    - Recalculate lại từ enrollments hiện có
    """
    db: Session = SessionLocal()
    
    try:
        # Lấy tất cả students
        students = db.query(Student).all()
        print(f"\n📊 Found {len(students)} students")
        
        # Lấy tất cả semesters
        semesters = db.query(Semester).order_by(Semester.start_date).all()
        print(f"📅 Found {len(semesters)} semesters\n")
        
        total_recalculated = 0
        total_deleted = 0
        total_errors = 0
        errors = []
        
        # Recalculate cho từng student và từng semester
        for student in students:
            print(f"\n👤 Student {student.student_code} (ID: {student.user_id})")
            
            for semester in semesters:
                try:
                    # Recalculate semester result
                    # Function này sẽ tự động xóa AcademicResult nếu total_credits = 0
                    result = calculate_and_save_semester_result(student.user_id, semester.id, db)
                    
                    if result:
                        print(f"   ✅ {semester.code}: GPA={result.gpa}, Credits={result.total_credits}")
                        total_recalculated += 1
                    else:
                        print(f"   🗑️  {semester.code}: Deleted (no enrollments)")
                        total_deleted += 1
                        
                except Exception as e:
                    print(f"   ❌ {semester.code}: Error - {e}")
                    total_errors += 1
                    errors.append(f"Student {student.student_code}, Semester {semester.code}: {str(e)}")
            
            # Update cumulative result (CPA) cho student
            try:
                update_cumulative_result(student.user_id, db)
                print(f"   ✅ Updated cumulative CPA")
            except Exception as e:
                print(f"   ❌ Error updating CPA: {e}")
                errors.append(f"Student {student.student_code} CPA: {str(e)}")
        
        print(f"\n{'='*60}")
        print(f"📊 SUMMARY:")
        print(f"   ✅ Recalculated: {total_recalculated} semester results")
        print(f"   🗑️  Deleted: {total_deleted} empty semester results")
        print(f"   ❌ Errors: {total_errors}")
        
        if errors:
            print(f"\n⚠️  Errors ({len(errors)}):")
            for error in errors[:10]:  # Chỉ hiển thị 10 lỗi đầu
                print(f"   - {error}")
            if len(errors) > 10:
                print(f"   ... and {len(errors) - 10} more errors")
        
        print(f"\n✅ Completed!\n")
        
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("🔄 Starting academic results recalculation...")
    recalculate_all_academic_results()
