from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User
from app.models.enums import UserRole
from app.schemas.academic import Class as ClassSchema
from app.schemas.user import User as UserSchema
from app.services import lecturer_service

router = APIRouter(prefix="/lecturers", tags=["lecturers"])

def check_lecturer_role(user: User):
    if user.role != UserRole.LECTURER:
        raise HTTPException(status_code=403, detail="Not authorized")

@router.get("/me", response_model=UserSchema)
def get_lecturer_profile(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Lấy thông tin profile của giảng viên hiện tại"""
    check_lecturer_role(current_user)
    return current_user

@router.get("/my-classes", response_model=List[ClassSchema])
def get_my_classes(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_lecturer_role(current_user)
    lecturer = current_user.lecturer
    if not lecturer:
        raise HTTPException(status_code=404, detail="Lecturer profile not found")
    
    return lecturer_service.get_lecturer_classes(lecturer.user_id, db)

@router.get("/classes/{class_id}/students")
def get_class_students(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Lấy danh sách sinh viên trong lớp kèm điểm số"""
    check_lecturer_role(current_user)
    students = lecturer_service.get_class_students_with_grades(class_id, db)
    
    if students is None:
        raise HTTPException(status_code=404, detail="Class not found")
    
    return students

@router.get("/classes/{class_id}/grades")
def get_class_grades(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_lecturer_role(current_user)
    return lecturer_service.get_class_grades(class_id, db)

@router.put("/grades")
@router.post("/grades")
def add_or_update_grade(
    grade_data: dict,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_lecturer_role(current_user)
    
    class_id = grade_data.get("class_id")
    student_id = grade_data.get("student_id")
    
    if not class_id or not student_id:
        raise HTTPException(status_code=400, detail="Missing class_id or student_id")
    
    grades = {
        k: v for k, v in grade_data.items() 
        if k in ['midterm', 'final', 'lab', 'assignment']
    }
    
    result = lecturer_service.add_or_update_grade(class_id, student_id, grades, db)
    
    if result is None:
        raise HTTPException(status_code=404, detail="Enrollment or class not found")
    
    return result
