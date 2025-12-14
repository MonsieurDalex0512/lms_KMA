from typing import List, Optional
from datetime import datetime
from sqlalchemy.orm import Session
from app.models.report import Report, ReportStatus, ReportType
from app.models.user import Student

def create_report(student_id: int, title: str, description: str, report_type: str, db: Session):
    report = Report(
        student_id=student_id,
        title=title,
        description=description,
        report_type=report_type,
        status=ReportStatus.PENDING
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    return report

def get_student_reports(student_id: int, db: Session):
    reports = db.query(Report).filter(Report.student_id == student_id).order_by(Report.created_at.desc()).all()
    
    return [
        {
            "id": r.id,
            "student_id": r.student_id,
            "student_code": r.student.student_code if r.student else None,
            "student_name": r.student.user.full_name if r.student and r.student.user else "Unknown",
            "title": r.title,
            "description": r.description,
            "report_type": r.report_type.value,
            "status": r.status.value,
            "dean_response": r.dean_response,
            "created_at": r.created_at,
            "updated_at": r.updated_at,
            "resolved_at": r.resolved_at,
            "resolved_by_name": r.resolved_by_user.full_name if r.resolved_by_user else None
        }
        for r in reports
    ]

def get_all_reports(status_filter: Optional[str], db: Session, skip: int = 0, limit: int = 100):
    query = db.query(Report)
    
    if status_filter:
        query = query.filter(Report.status == status_filter)
    
    reports = query.order_by(Report.created_at.desc()).offset(skip).limit(limit).all()
    
    return [
        {
            "id": r.id,
            "student_id": r.student_id,
            "student_code": r.student.student_code if r.student else None,
            "student_name": r.student.user.full_name if r.student and r.student.user else "Unknown",
            "title": r.title,
            "description": r.description,
            "report_type": r.report_type.value,
            "status": r.status.value,
            "dean_response": r.dean_response,
            "created_at": r.created_at,
            "updated_at": r.updated_at,
            "resolved_at": r.resolved_at,
            "resolved_by_name": r.resolved_by_user.full_name if r.resolved_by_user else None
        }
        for r in reports
    ]

def get_report_by_id(report_id: int, db: Session):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        return None
    
    return {
        "id": report.id,
        "student_id": report.student_id,
        "student_code": report.student.student_code if report.student else None,
        "student_name": report.student.user.full_name if report.student and report.student.user else "Unknown",
        "title": report.title,
        "description": report.description,
        "report_type": report.report_type.value,
        "status": report.status.value,
        "dean_response": report.dean_response,
        "created_at": report.created_at,
        "updated_at": report.updated_at,
        "resolved_at": report.resolved_at,
        "resolved_by_name": report.resolved_by_user.full_name if report.resolved_by_user else None
    }

def update_report(report_id: int, status: Optional[str], dean_response: Optional[str], dean_id: int, db: Session):
    report = db.query(Report).filter(Report.id == report_id).first()
    if not report:
        return None
    
    if status:
        report.status = status
        if status in [ReportStatus.RESOLVED.value, ReportStatus.REJECTED.value]:
            report.resolved_at = datetime.now()
            report.resolved_by = dean_id
    
    if dean_response:
        report.dean_response = dean_response
    
    db.commit()
    db.refresh(report)
    return report

def get_report_stats(db: Session):
    total = db.query(Report).count()
    pending = db.query(Report).filter(Report.status == ReportStatus.PENDING).count()
    processing = db.query(Report).filter(Report.status == ReportStatus.PROCESSING).count()
    resolved = db.query(Report).filter(Report.status == ReportStatus.RESOLVED).count()
    rejected = db.query(Report).filter(Report.status == ReportStatus.REJECTED).count()
    
    return {
        "total": total,
        "pending": pending,
        "processing": processing,
        "resolved": resolved,
        "rejected": rejected
    }
