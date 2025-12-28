from sqlalchemy import Column, Integer, String, ForeignKey, Float
from sqlalchemy.orm import relationship
from app.database import Base

class Tuition(Base):
    __tablename__ = "tuitions"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.user_id"), nullable=False)
    semester = Column(String, nullable=False)  
    total_amount = Column(Integer, default=0)
    paid_amount = Column(Integer, default=0)
    status = Column(String, default="PENDING")  # PENDING, PARTIAL, COMPLETED
    
    student = relationship("Student", back_populates="tuitions")
