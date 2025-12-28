from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User, Student, Lecturer
from app.models.academic import Course, Class, Department
from app.models.enums import UserRole

router = APIRouter(prefix="/deans/statistics", tags=["deans"])

def check_dean_role(user: User):
    if user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")

@router.get("")
def get_statistics(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    total_students = db.query(func.count(Student.user_id)).scalar()
    total_lecturers = db.query(func.count(Lecturer.user_id)).scalar()
    total_courses = db.query(func.count(Course.id)).scalar()
    total_classes = db.query(func.count(Class.id)).scalar()
    total_departments = db.query(func.count(Department.id)).scalar()
    
    return {
        "total_students": total_students or 0,
        "total_lecturers": total_lecturers or 0,
        "total_courses": total_courses or 0,
        "total_classes": total_classes or 0,
        "total_departments": total_departments or 0
    }

@router.get("/charts")
def get_chart_statistics(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Lấy dữ liệu thống kê cho biểu đồ dashboard"""
    check_dean_role(current_user)
    
    students_by_dept = db.query(
        Department.name,
        func.count(Student.user_id).label('count')
    ).join(Student, Student.department_id == Department.id, isouter=True)\
     .group_by(Department.id, Department.name)\
     .all()
    
    students_by_department = [
        {"name": dept_name, "value": count}
        for dept_name, count in students_by_dept
    ]
    
    from app.models.academic_year import Semester
    recent_semesters = db.query(Semester)\
        .order_by(Semester.start_date.desc())\
        .limit(5)\
        .all()
    
    classes_by_semester = []
    for sem in reversed(recent_semesters):
        count = db.query(func.count(Class.id))\
            .filter(Class.semester == sem.code)\
            .scalar()
        classes_by_semester.append({
            "semester": sem.name,
            "count": count or 0
        })
    
    total_students = db.query(func.count(Student.user_id)).scalar() or 0
    total_lecturers = db.query(func.count(Lecturer.user_id)).scalar() or 0
    total_courses = db.query(func.count(Course.id)).scalar() or 0
    
    overview_comparison = [
        {"category": "Sinh viên", "value": total_students},
        {"category": "Giảng viên", "value": total_lecturers},
        {"category": "Môn học", "value": total_courses}
    ]
    
    return {
        "students_by_department": students_by_department,
        "classes_by_semester": classes_by_semester,
        "overview_comparison": overview_comparison
    }

