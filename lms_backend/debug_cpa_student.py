"""
Script debug: Kiểm tra CPA của sinh viên ID 1
"""
from app.database import get_db
from app.models.user import Student
from app.models.academic import Enrollment, Grade, Class, Course
from app.models.academic_year import AcademicResult, Semester
from app.models.cumulative_result import CumulativeResult
from app.utils.academic_calculator import calculate_cumulative_cpa_from_courses, convert_score_to_grade_4, calculate_final_score

def debug_student_cpa(student_id: int):
    db = next(get_db())
    
    print(f"\n=== DEBUG STUDENT {student_id} CPA ===\n")
    
    # 1. Check cumulative_results table
    cumulative = db.query(CumulativeResult).filter(
        CumulativeResult.student_id == student_id
    ).first()
    
    if cumulative:
        print(f"✓ CumulativeResult exists:")
        print(f"  CPA: {cumulative.cpa}")
        print(f"  Total credits: {cumulative.total_registered_credits}")
    else:
        print("✗ CumulativeResult NOT FOUND - Table may not exist or no data")
    
    # 2. Check all enrollments and grades
    enrollments = db.query(Enrollment).filter(
        Enrollment.student_id == student_id
    ).all()
    
    print(f"\n📚 Total enrollments: {len(enrollments)}\n")
    
    total_weighted = 0.0
    total_credits = 0
    
    for enrollment in enrollments:
        course = enrollment.class_.course
        semester = enrollment.class_.semester
        
        final_score = calculate_final_score(enrollment.grades)
        if final_score:
            score_4, letter = convert_score_to_grade_4(final_score)
            credits = course.credits
            
            total_credits += credits
            total_weighted += score_4 * credits
            
            print(f"  {course.code} ({course.name}) - Kỳ {semester}")
            print(f"    Điểm 10: {final_score}, Điểm 4: {score_4} ({letter})")
            print(f"    Tín chỉ: {credits}, Weighted: {score_4 * credits}")
    
    if total_credits > 0:
        manual_cpa = total_weighted / total_credits
        print(f"\n🧮 Manual CPA calculation:")
        print(f"  Total weighted: {total_weighted}")
        print(f"  Total credits: {total_credits}")
        print(f"  CPA: {manual_cpa:.2f}")
    
    # 3. Check academic_results by semester
    print(f"\n📊 Academic Results by semester:")
    results = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id
    ).join(Semester).order_by(Semester.start_date).all()
    
    for result in results:
        print(f"  {result.semester.code}: GPA={result.gpa}, CPA={result.cpa}")
    
    # 4. Recalculate using function
    print(f"\n🔄 Recalculating CPA...")
    cpa, registered, completed, failed = calculate_cumulative_cpa_from_courses(student_id, db)
    print(f"  Calculated CPA: {cpa}")
    print(f"  Registered: {registered}, Completed: {completed}, Failed: {failed}")
    
    db.close()

if __name__ == "__main__":
    debug_student_cpa(1)
