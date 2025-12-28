from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_, func

from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User, Lecturer
from app.models.academic import Course, Class
from app.models.enums import UserRole

router = APIRouter(prefix="/students/search", tags=["students"])

def check_student_role(user: User):
    if user.role != UserRole.STUDENT:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail="Not authorized. Student access required.")

@router.get("")
def search(
    q: str = Query(..., min_length=1, description="Search query"),
    type: str = Query("all", description="Search type: all, course, lecturer, class"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """
    Tìm kiếm học phần, giảng viên, lớp học
    
    Args:
        q: Từ khóa tìm kiếm
        type: Loại tìm kiếm (all, course, lecturer, class)
    
    Returns:
        Dictionary chứa kết quả tìm kiếm
    """
    check_student_role(current_user)
    
    search_term = f"%{q}%"
    results = {
        "courses": [],
        "lecturers": [],
        "classes": []
    }
    
    # Tìm kiếm học phần
    if type in ["all", "course"]:
        courses = db.query(Course).filter(
            or_(
                Course.name.ilike(search_term),
                Course.code.ilike(search_term)
            )
        ).limit(10).all()
        
        results["courses"] = [
            {
                "id": c.id,
                "code": c.code,
                "name": c.name,
                "credits": c.credits
            }
            for c in courses
        ]
    
    # Tìm kiếm giảng viên
    if type in ["all", "lecturer"]:
        lecturers = db.query(User).join(Lecturer).filter(
            User.role == UserRole.LECTURER,
            or_(
                User.full_name.ilike(search_term),
                User.email.ilike(search_term)
            )
        ).limit(10).all()
        
        results["lecturers"] = [
            {
                "id": lec.id,
                "full_name": lec.full_name,
                "email": lec.email,
                "department_name": lec.lecturer.department.name if lec.lecturer and lec.lecturer.department else None
            }
            for lec in lecturers
        ]
    
    # Tìm kiếm lớp học
    if type in ["all", "class"]:
        classes = db.query(Class).join(Course).filter(
            or_(
                Class.code.ilike(search_term),
                Course.name.ilike(search_term),
                Class.semester.ilike(search_term)
            )
        ).limit(10).all()
        
        results["classes"] = [
            {
                "id": cls.id,
                "code": cls.code,
                "course_name": cls.course.name if cls.course else None,
                "course_code": cls.course.code if cls.course else None,
                "lecturer_name": cls.lecturer.user.full_name if cls.lecturer else None,
                "semester": cls.semester,
                "day_of_week": cls.day_of_week,
                "start_period": cls.start_period,
                "end_period": cls.end_period,
                "room": cls.room,
                "max_students": cls.max_students,
                "enrolled_count": len(cls.enrollments) if cls.enrollments else 0
            }
            for cls in classes
        ]
    
    return results
