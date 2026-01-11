from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.user import Lecturer, User
from app.models.academic import Class, Grade, Enrollment, Course
from app.models.academic_year import AcademicResult, Semester
from app.utils.academic_calculator import calculate_and_save_semester_result

def get_lecturer_classes(lecturer_id: int, db: Session):
    from app.models.academic_year import Semester
    
    # Get active semester to identify current classes
    active_semester = db.query(Semester).filter(
        Semester.is_active == True,
        Semester.is_deleted == False
    ).first()
    active_semester_code = active_semester.code if active_semester else None
    
    classes = db.query(Class).filter(Class.lecturer_id == lecturer_id).all()
    result = []
    
    for c in classes:
        try:
            course_name = "Unknown"
            course_code = None
            credits = 0
            try:
                if c.course:
                    course_name = c.course.name or "Unknown"
                    course_code = c.course.code
                    credits = c.course.credits or 0
            except:
                pass
            
            result.append({
                "id": c.id,
                "code": c.code,
                "class_code": c.code,
                "course_name": course_name,
                "course_code": course_code,
                "course": {
                    "id": c.course.id if c.course else None,
                    "name": course_name,
                    "code": course_code,
                },
                "semester": c.semester,
                "semester_code": c.semester,
                "is_current": c.semester == active_semester_code if active_semester_code else False,
                "room": c.room,
                "day_of_week": c.day_of_week,
                "start_week": c.start_week,
                "end_week": c.end_week,
                "start_period": c.start_period,
                "end_period": c.end_period,
                "credits": credits,
                "enrolled_count": len(c.enrollments) if c.enrollments else 0,
                "max_students": c.max_students
            })
        except Exception as ex:
            import traceback
            print(f"Error processing class {c.id}: {ex}")
            print(traceback.format_exc())
            continue
    
    return result

def get_class_students(class_id: int, db: Session):
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj:
        return None
    
    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    students = []
    for e in enrollments:
        user = e.student.user
        user.department_name = e.student.department.name if e.student.department else None
        students.append(user)
        
    return students

def get_class_students_with_grades(class_id: int, db: Session):
    """Lấy danh sách sinh viên kèm điểm số cho mobile app"""
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj:
        return None
    
    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    students = []
    
    for enrollment in enrollments:
        student = enrollment.student
        user = student.user
        
        grades = {g.grade_type: g.score for g in enrollment.grades}
        
        students.append({
            "student_id": student.student_code,  # MSSV
            "student_name": user.full_name,
            "student_code": student.student_code,
            "enrollment_id": enrollment.id,
            "midterm_grade": grades.get('midterm'),
            "final_grade": grades.get('final'),
            "lab_grade": grades.get('lab'),
            "assignment_grade": grades.get('assignment')
        })
        
    return students

def get_class_grades(class_id: int, db: Session):
    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    results = []
    
    for enrollment in enrollments:
        student = enrollment.student
        grades = {g.grade_type: g.score for g in enrollment.grades}
        
        results.append({
            "student_id": student.user_id,
            "student_code": student.student_code,
            "full_name": student.user.full_name,
            "midterm": grades.get('midterm'),
            "final": grades.get('final'),
            "lab": grades.get('lab'),
            "assignment": grades.get('assignment')
        })
    
    return results

def add_or_update_grade(class_id: int, student_id: int, grade_data: dict, db: Session):
    enrollment = db.query(Enrollment).filter(
        Enrollment.class_id == class_id,
        Enrollment.student_id == student_id
    ).first()
    
    if not enrollment:
        return None
    
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj or not class_obj.semester:
        return None
    
    for grade_type, score in grade_data.items():
        if score is None:
            continue
            
        existing_grade = db.query(Grade).filter(
            Grade.enrollment_id == enrollment.id,
            Grade.grade_type == grade_type
        ).first()
        
        if existing_grade:
            existing_grade.score = score
        else:
            weight = {'midterm': 0.3, 'final': 0.5, 'lab': 0.1, 'assignment': 0.1}.get(grade_type, 0.0)
            new_grade = Grade(
                enrollment_id=enrollment.id,
                grade_type=grade_type,
                score=score,
                weight=weight
            )
            db.add(new_grade)
    
    db.commit()
    
    semester = db.query(Semester).filter(Semester.code == class_obj.semester).first()
    if semester:
        calculate_and_save_semester_result(student_id, semester.id, db)
    
    return {"success": True}

