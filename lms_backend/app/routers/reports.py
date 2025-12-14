from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User
from app.models.enums import UserRole
from app.schemas.report import ReportCreate, ReportUpdate, ReportResponse, ReportStats
from app.services import report_service

router = APIRouter(prefix="/reports", tags=["reports"])

@router.post("", response_model=ReportResponse)
def create_report(
    report_data: ReportCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can create reports")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    
    report = report_service.create_report(
        student.user_id,
        report_data.title,
        report_data.description,
        report_data.report_type,
        db
    )
    
    return report_service.get_report_by_id(report.id, db)

@router.get("/my-reports", response_model=List[ReportResponse])
def get_my_reports(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.STUDENT:
        raise HTTPException(status_code=403, detail="Only students can view their reports")
    
    student = current_user.student
    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
    
    return report_service.get_student_reports(student.user_id, db)

@router.get("/all", response_model=List[ReportResponse])
def get_all_reports(
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Only deans can view all reports")
    
    return report_service.get_all_reports(status, db, skip=skip, limit=limit)

@router.get("/stats", response_model=ReportStats)
def get_report_stats(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Only deans can view stats")
    
    return report_service.get_report_stats(db)

@router.get("/{report_id}", response_model=ReportResponse)
def get_report_detail(
    report_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    report = report_service.get_report_by_id(report_id, db)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    if current_user.role == UserRole.STUDENT:
        student = current_user.student
        if not student or report["student_id"] != student.user_id:
            raise HTTPException(status_code=403, detail="Not authorized")
    elif current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    return report

@router.put("/{report_id}", response_model=ReportResponse)
def update_report(
    report_id: int,
    update_data: ReportUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if current_user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Only deans can update reports")
    
    report = report_service.update_report(
        report_id,
        update_data.status,
        update_data.dean_response,
        current_user.id,
        db
    )
    
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    return report_service.get_report_by_id(report.id, db)
