from sqlalchemy import Column, Integer, ForeignKey, Float, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class CumulativeResult(Base):
    """Kết quả tích lũy toàn khóa (CPA)"""
    __tablename__ = "cumulative_results"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.user_id"), nullable=False, unique=True)
    
    cpa = Column(Float, default=0.0)  

    total_registered_credits = Column(Integer, default=0)  
    total_completed_credits = Column(Integer, default=0)   
    total_failed_credits = Column(Integer, default=0)      
    
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    student = relationship("Student", back_populates="cumulative_result")
