from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum

class ReportType(str, enum.Enum):
    ACADEMIC = "academic"
    ADMINISTRATIVE = "administrative"
    TECHNICAL = "technical"
    OTHER = "other"

class ReportStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    RESOLVED = "resolved"
    REJECTED = "rejected"

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.user_id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    report_type = Column(SQLEnum(ReportType), nullable=False, default=ReportType.OTHER)
    status = Column(SQLEnum(ReportStatus), nullable=False, default=ReportStatus.PENDING)
    dean_response = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolved_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    student = relationship("Student", foreign_keys=[student_id], backref="reports")
    resolved_by_user = relationship("User", foreign_keys=[resolved_by])
