from typing import List, Tuple, Optional
from sqlalchemy.orm import Session
from app.models.academic import Enrollment, Grade, Class
from app.models.academic_year import AcademicResult, Semester
from app.models.user import Student
from app.models.cumulative_result import CumulativeResult

# Bảng quy đổi điểm thang 10 sang thang 4 và chữ
GRADE_CONVERSION = [
    (8.5, 10.0, 4.0, "A"),
    (8.0, 8.4, 3.5, "B+"),
    (7.0, 7.9, 3.0, "B"),
    (6.5, 6.9, 2.5, "C+"),
    (5.5, 6.4, 2.0, "C"),
    (5.0, 5.4, 1.5, "D+"),
    (4.0, 4.9, 1.0, "D"),
    (0.0, 3.9, 0.0, "F"),
]

def convert_score_to_grade_4(score_10: float) -> Tuple[float, str]:
    """
    Quy đổi điểm thang 10 sang thang 4 và chữ
    
    Args:
        score_10: Điểm thang 10 (0-10)
    
    Returns:
        Tuple (điểm thang 4, điểm chữ)
    
    """
    for min_score, max_score, grade_4, letter in GRADE_CONVERSION:
        if min_score <= score_10 <= max_score:
            return grade_4, letter
    return 0.0, "F"

def calculate_final_score(grades: List[Grade]) -> Optional[float]:
    """
    Tính điểm cuối cùng từ các loại điểm (midterm, final, assignment, ...)
    Ưu tiên lấy điểm 'final' nếu có, nếu không lấy điểm đầu tiên
    
    Args:
        grades: Danh sách các Grade objects
    
    Returns:
        Điểm cuối cùng (thang 10) hoặc None nếu không có điểm
    """
    if not grades:
        return None
    
    for grade in grades:
        if grade.grade_type == 'final':
            return grade.score
    
    return grades[0].score

def calculate_semester_gpa(student_id: int, semester_code: str, db: Session) -> Tuple[float, int, int, int]:
    """
    Tính GPA của 1 học kỳ
    
    Công thức: GPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(số_tín_chỉ)
    
    Args:
        student_id: ID của sinh viên
        semester_code: Mã học kỳ (ví dụ: "20222")
        db: Database session
    
    Returns:
        Tuple (gpa, total_credits, completed_credits, failed_credits)
    
    Example:
        Học kỳ 20222:
        - Giải tích 1 (3 tín): 7.5/10 → 3.0 (B)
        - Đại số (3 tín): 5.0/10 → 1.5 (D+)
        - Vật lý (4 tín): 4.0/10 → 1.0 (D)
        
        GPA = (3.0×3 + 1.5×3 + 1.0×4) / (3+3+4) = 17.5 / 10 = 1.75
    """
    enrollments = db.query(Enrollment).join(Class).filter(
        Enrollment.student_id == student_id,
        Class.semester == semester_code
    ).all()
    
    if not enrollments:
        return 0.0, 0, 0, 0
    
    total_weighted_score = 0.0
    total_credits = 0
    completed_credits = 0
    failed_credits = 0
    
    for enrollment in enrollments:
        final_score_10 = calculate_final_score(enrollment.grades)
        
        if final_score_10 is None:
            continue  
        score_4, letter_grade = convert_score_to_grade_4(final_score_10)
        
        credits = enrollment.class_.course.credits
        total_credits += credits
        
        total_weighted_score += score_4 * credits
        
        if score_4 >= 1.0:  
            completed_credits += credits
        else:
            failed_credits += credits
    
    if total_credits == 0:
        return 0.0, 0, 0, 0
    
    gpa = total_weighted_score / total_credits
    return round(gpa, 2), total_credits, completed_credits, failed_credits

def calculate_cumulative_cpa_from_courses(student_id: int, db: Session) -> Tuple[float, int, int, int]:
    """
    Tính CPA tích lũy từ TẤT CẢ các môn học từ đầu khóa
    
    Công thức ĐÚNG: CPA = Σ(điểm_môn_thang4 × tín_chỉ) / Σ(tín_chỉ_đã_đăng_ký)
    
    Args:
        student_id: ID của sinh viên
        db: Database session
    
    Returns:
        Tuple (cpa, total_registered, total_completed, total_failed)
    """
    enrollments = db.query(Enrollment).filter(
        Enrollment.student_id == student_id
    ).all()
    
    total_weighted_score = 0.0
    total_registered = 0
    total_completed = 0
    total_failed = 0
    
    for enrollment in enrollments:
        final_score_10 = calculate_final_score(enrollment.grades)
        
        if final_score_10 is None:
            continue 
        score_4, _ = convert_score_to_grade_4(final_score_10)
        
        credits = enrollment.class_.course.credits
        total_registered += credits
        
        total_weighted_score += score_4 * credits
        
        if score_4 >= 1.0:  
            total_completed += credits
        else:
            total_failed += credits
    
    if total_registered == 0:
        return 0.0, 0, 0, 0
    
    cpa = total_weighted_score / total_registered
    return round(cpa, 2), total_registered, total_completed, total_failed

def update_cumulative_result(student_id: int, db: Session) -> CumulativeResult:
    """
    Cập nhật CPA tích lũy cho sinh viên vào bảng cumulative_results
    
    Args:
        student_id: ID của sinh viên
        db: Database session
    
    Returns:
        CumulativeResult object đã được lưu
    """
    cpa, registered, completed, failed = calculate_cumulative_cpa_from_courses(student_id, db)
    
    cumulative = db.query(CumulativeResult).filter(
        CumulativeResult.student_id == student_id
    ).first()
    
    if cumulative:
        cumulative.cpa = cpa
        cumulative.total_registered_credits = registered
        cumulative.total_completed_credits = completed
        cumulative.total_failed_credits = failed
    else:
        cumulative = CumulativeResult(
            student_id=student_id,
            cpa=cpa,
            total_registered_credits=registered,
            total_completed_credits=completed,
            total_failed_credits=failed
        )
        db.add(cumulative)
    
    db.commit()
    db.refresh(cumulative)
    return cumulative

def calculate_and_save_semester_result(student_id: int, semester_id: int, db: Session) -> AcademicResult:
    """
    Tính toán và lưu kết quả học tập của sinh viên cho 1 học kỳ (chỉ GPA)
    CPA sẽ được tính riêng qua update_cumulative_result()
    
    Args:
        student_id: ID của sinh viên
        semester_id: ID của học kỳ
        db: Database session
    
    Returns:
        AcademicResult object đã được lưu
    """
    semester = db.query(Semester).filter(Semester.id == semester_id).first()
    if not semester:
        raise ValueError(f"Semester {semester_id} not found")
    
    gpa, total_credits, completed_credits, failed_credits = calculate_semester_gpa(
        student_id, semester.code, db
    )
    
    existing_result = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id,
        AcademicResult.semester_id == semester_id
    ).first()
    
    if existing_result:
        existing_result.gpa = gpa
        existing_result.total_credits = total_credits
        existing_result.completed_credits = completed_credits
        existing_result.failed_credits = failed_credits
        db.commit()
        db.refresh(existing_result)
        result = existing_result
    else:
        new_result = AcademicResult(
            student_id=student_id,
            semester_id=semester_id,
            gpa=gpa,
            total_credits=total_credits,
            completed_credits=completed_credits,
            failed_credits=failed_credits
        )
        db.add(new_result)
        db.commit()
        db.refresh(new_result)
        result = new_result
    
    update_cumulative_result(student_id, db)
    
    return result

def calculate_all_students_in_semester(semester_id: int, db: Session) -> int:
    """
    Tính toán kết quả học tập cho tất cả sinh viên trong 1 học kỳ
    
    Args:
        semester_id: ID của học kỳ
        db: Database session
    
    Returns:
        Số lượng sinh viên đã được tính toán
    """
    semester = db.query(Semester).filter(Semester.id == semester_id).first()
    if not semester:
        raise ValueError(f"Semester {semester_id} not found")
    
    student_ids = db.query(Enrollment.student_id).join(Class).filter(
        Class.semester == semester.code
    ).distinct().all()
    
    count = 0
    for (student_id,) in student_ids:
        calculate_and_save_semester_result(student_id, semester_id, db)
        count += 1
    
    return count
