from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from sqlalchemy import desc, or_
from app.models.user import Student, User, Lecturer
from app.models.academic import Department, Course, Class, Enrollment, Grade
from app.models.academic_year import AcademicYear, Semester, AcademicResult
from app.models.cumulative_result import CumulativeResult
from app.utils.academic_calculator import calculate_and_save_semester_result, update_cumulative_result
from app.schemas.user import UserCreate, UserUpdate
from app.models.enums import UserRole
from app.crud.user import create_user


def get_academic_results_by_semester(semester_id: int, db: Session, skip: int = 0, limit: int = 100):
    results = db.query(AcademicResult).filter(
        AcademicResult.semester_id == semester_id
    ).offset(skip).limit(limit).all()
    
    return [
        {
            "student_id": r.student_id,
            "student_code": r.student.student_code,
            "full_name": r.student.user.full_name,
            "gpa": r.gpa,
            "cpa": r.cpa,
            "total_credits": r.total_credits,
            "completed_credits": r.completed_credits,
            "failed_credits": r.failed_credits,
            "cumulative_credits": r.cumulative_credits,
            "semester_code": r.semester.code,
            "semester_name": r.semester.name
        }
        for r in results
    ]

def get_student_all_results(student_id: int, db: Session):
    student = db.query(Student).join(User).filter(Student.user_id == student_id).first()
    if not student:
        return None
    
    semester_results = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id
    ).join(Semester).order_by(Semester.start_date).all()
    
    cumulative = db.query(CumulativeResult).filter(
        CumulativeResult.student_id == student_id
    ).first()
    
    semesters = [
        {
            "semester_id": r.semester_id,
            "semester_code": r.semester.code,
            "semester_name": r.semester.name,
            "gpa": r.gpa,
            "total_credits": r.total_credits,
            "completed_credits": r.completed_credits,
            "failed_credits": r.failed_credits
        }
        for r in semester_results
    ]
    
    return {
        "student_id": student_id,
        "student_code": student.student_code,
        "full_name": student.user.full_name,
        "semester_results": semesters,
        "cumulative_cpa": cumulative.cpa if cumulative else 0.0,
        "total_registered_credits": cumulative.total_registered_credits if cumulative else 0,
        "total_completed_credits": cumulative.total_completed_credits if cumulative else 0,
        "total_failed_credits": cumulative.total_failed_credits if cumulative else 0
    }

def recalculate_all_cpa(db: Session):
    students = db.query(Student).all()
    count_success = 0
    count_error = 0
    errors = []
    
    for student in students:
        try:
            update_cumulative_result(student.user_id, db)
            count_success += 1
        except Exception as e:
            count_error += 1
            errors.append(f"Student {student.student_code}: {str(e)}")
    
    return {
        "message": "CPA recalculation completed",
        "total_students": len(students),
        "success": count_success,
        "errors": count_error,
        "error_details": errors[:10]
    }

def create_lecturer(db: Session, user_in: UserCreate):
    if user_in.role != UserRole.LECTURER:
         raise ValueError("Role must be lecturer")
         
    if db.query(User).filter(User.username == user_in.username).first():
        raise ValueError("Username already registered")
        
    user = create_user(db, user_in)
    lecturer_profile = Lecturer(
        user_id=user.id, 
        lecturer_code=f"LEC{user.id}",
        department_id=user_in.department_id
    )
    db.add(lecturer_profile)
    db.commit()
    return user

def list_lecturers(db: Session, skip: int = 0, limit: int = 100):
    lecturers = db.query(User).filter(User.role == UserRole.LECTURER).offset(skip).limit(limit).all()
    
    result = []
    for lec in lecturers:
        lec_dict = {
            "id": lec.id,
            "username": lec.username,
            "email": lec.email,
            "full_name": lec.full_name,
            "phone_number": lec.phone_number,
            "role": lec.role,
            "student_code": None,
            "department_name": lec.lecturer.department.name if lec.lecturer and lec.lecturer.department else None,
            "is_active": True
        }
        result.append(lec_dict)
    return result

def update_lecturer(db: Session, user_id: int, user_in: UserUpdate):
    db_user = db.query(User).filter(User.id == user_id, User.role == UserRole.LECTURER).first()
    if not db_user:
        return None
    
    if user_in.full_name:
        db_user.full_name = user_in.full_name
    if user_in.email:
        db_user.email = user_in.email
    if user_in.phone_number:
        db_user.phone_number = user_in.phone_number
    
    if user_in.department_id is not None and db_user.lecturer:
        db_user.lecturer.department_id = user_in.department_id
    
    db.commit()
    db.refresh(db_user)
    return db_user

def list_students(db: Session, skip: int = 0, limit: int = 100):
    students = db.query(User).filter(User.role == UserRole.STUDENT).offset(skip).limit(limit).all()
    result = []
    for stu in students:
        stu_dict = {
            "id": stu.id,
            "username": stu.username,
            "email": stu.email,
            "full_name": stu.full_name,
            "phone_number": stu.phone_number,
            "role": stu.role,
            "student_code": stu.student.student_code if stu.student else None,
            "department_name": stu.student.department.name if stu.student and stu.student.department else None,
            "is_active": stu.is_active
        }
        result.append(stu_dict)
    return result

def create_student(db: Session, user_in: UserCreate):
    if user_in.role != UserRole.STUDENT:
         raise ValueError("Role must be student")
    
    if db.query(User).filter(User.username == user_in.username).first():
        raise ValueError("Username already registered")
        
    user = create_user(db, user_in)
    code = user_in.student_code if user_in.student_code else f"STU{user.id}"
    
    if db.query(Student).filter(Student.student_code == code).first():
        raise ValueError("Student code already exists")

    student_profile = Student(
        user_id=user.id, 
        student_code=code,
        department_id=user_in.department_id
    )
    db.add(student_profile)
    db.commit()
    
    active_sem = db.query(Semester).filter(Semester.is_active == True).first()
    if active_sem:
        init_result = AcademicResult(
            student_id=user.id,
            semester_id=active_sem.id,
            gpa=0.0,
            cpa=0.0,
            total_credits=0,
            completed_credits=0,
            failed_credits=0,
            cumulative_credits=0,
            calculated_at=datetime.now()
        )
        db.add(init_result)
        db.commit()
    
    return user

def update_student(db: Session, user_id: int, user_in: UserUpdate):
    db_user = db.query(User).filter(User.id == user_id, User.role == UserRole.STUDENT).first()
    if not db_user:
        return None
    
    if user_in.full_name:
        db_user.full_name = user_in.full_name
    if user_in.email:
        db_user.email = user_in.email
    if user_in.phone_number:
        db_user.phone_number = user_in.phone_number
    
    if user_in.student_code and db_user.student:
        db_user.student.student_code = user_in.student_code
    
    if user_in.department_id is not None and db_user.student:
        db_user.student.department_id = user_in.department_id
    
    db.commit()
    db.refresh(db_user)
    return db_user

def get_all_students(db: Session):
    students = db.query(User).filter(User.role == "STUDENT").all()
    result = []
    for stu in students:
        result.append({
            "id": stu.id,
            "username": stu.username,
            "email": stu.email,
            "full_name": stu.full_name,
            "phone_number": stu.phone_number,
            "role": stu.role,
            "student_code": stu.student.student_code if stu.student else None,
            "department_name": stu.student.department.name if stu.student and stu.student.department else None,
            "is_active": True
        })
    return result

    return result

def delete_lecturer(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id, User.role == UserRole.LECTURER).first()
    if user:
        db.delete(user)
        db.commit()
    return user

def delete_student(db: Session, user_id: int):
    user = db.query(User).filter(User.id == user_id, User.role == UserRole.STUDENT).first()
    if user:
        db.delete(user)
        db.commit()
    return user

def update_grade(grade_id: int, score: float, db: Session):
    grade = db.query(Grade).filter(Grade.id == grade_id).first()
    if not grade:
        return None
    
    grade.score = score
    db.commit()
    
    enrollment = grade.enrollment
    class_obj = enrollment.class_
    if class_obj and class_obj.semester:
        semester = db.query(Semester).filter(Semester.code == class_obj.semester).first()
        if semester:
            calculate_and_save_semester_result(enrollment.student_id, semester.id, db)
    
    return grade

def create_grade(enrollment_id: int, grade_type: str, score: float, weight: float, db: Session):
    enrollment = db.query(Enrollment).filter(Enrollment.id == enrollment_id).first()
    if not enrollment:
        return None
    
    grade = Grade(
        enrollment_id=enrollment_id,
        grade_type=grade_type,
        score=score,
        weight=weight
    )
    db.add(grade)
    db.commit()
    
    class_obj = enrollment.class_
    if class_obj and class_obj.semester:
        semester = db.query(Semester).filter(Semester.code == class_obj.semester).first()
        if semester:
            calculate_and_save_semester_result(enrollment.student_id, semester.id, db)
    
    return grade
