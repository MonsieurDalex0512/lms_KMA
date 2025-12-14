from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class ReportCreate(BaseModel):
    title: str
    description: str
    report_type: str

class ReportUpdate(BaseModel):
    status: Optional[str] = None
    dean_response: Optional[str] = None

class ReportResponse(BaseModel):
    id: int
    student_id: int
    student_code: Optional[str] = None
    student_name: str
    title: str
    description: str
    report_type: str
    status: str
    dean_response: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    resolved_at: Optional[datetime] = None
    resolved_by_name: Optional[str] = None
    
    class Config:
        from_attributes = True

class ReportStats(BaseModel):
    total: int
    pending: int
    processing: int
    resolved: int
    rejected: int
