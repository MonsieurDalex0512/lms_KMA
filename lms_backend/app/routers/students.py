from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User
from app.models.enums import UserRole
from app.schemas.academic import MobileGradeResponse, MobileClassResponse, MobileTimetableResponse
from app.schemas.academic_year import MobileSemesterDetailResponse
from app.schemas.user import UserUpdate, User as UserSchema
from app.services import student_service

router = APIRouter(prefix="/students", tags=["students"])

@router.get("/me", response_model=UserSchema)
def read_student_profile(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    department_name = None
    if current_user.student and current_user.student.department:
        department_name = current_user.student.department.name
    
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "phone_number": current_user.phone_number,
        "role": current_user.role,
        "student_code": current_user.student.student_code if current_user.student else None,
        "department_name": department_name,
        "is_active": True
    }

@router.put("/me", response_model=UserSchema)
def update_student_profile(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    if user_update.full_name:
        current_user.full_name = user_update.full_name
    if user_update.email:
        current_user.email = user_update.email
    if user_update.phone_number:
        current_user.phone_number = user_update.phone_number
        
    db.commit()
    db.refresh(current_user)
    return current_user

@router.get("/my-grades", response_model=List[MobileGradeResponse])
def read_student_grades(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    return student_service.get_student_grades(student.user_id, db)

@router.get("/my-classes", response_model=List[MobileClassResponse])
def read_student_classes(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    return student_service.get_student_classes(student.user_id, db)

@router.get("/my-projects", response_model=List[MobileClassResponse])
def read_student_projects(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    return student_service.get_student_projects(student.user_id, db)

@router.get("/academic-summary")
def get_academic_summary(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    
    return student_service.get_academic_summary(student.user_id, db)

@router.get("/my-results/{semester_code}", response_model=MobileSemesterDetailResponse)
def read_student_semester_detail(
    semester_code: str,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    
    result = student_service.get_semester_detail(student.user_id, semester_code, db)
    if not result:
        raise HTTPException(status_code=404, detail="Academic result not found for this semester")
    
    return result

@router.get("/my-timetable", response_model=List[MobileTimetableResponse])
def read_student_timetable(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")

    return student_service.get_student_timetable(student.user_id, db)
