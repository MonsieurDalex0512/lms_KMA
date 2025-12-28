from sqlalchemy import Column, Integer, String, ForeignKey, Float, Date, Boolean, DateTime
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class AcademicYear(Base):
    __tablename__ = "academic_years"

    id = Column(Integer, primary_key=True, index=True)
    year = Column(String, unique=True, index=True, nullable=False)  
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True)
    is_deleted = Column(Boolean, default=False)
    
    semesters = relationship("Semester", back_populates="academic_year", cascade="all, delete-orphan")

class Semester(Base):
    __tablename__ = "semesters"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False)  
    name = Column(String, nullable=False)  
    academic_year_id = Column(Integer, ForeignKey("academic_years.id"), nullable=False)
    semester_number = Column(Integer, nullable=False) 
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_active = Column(Boolean, default=False) 
    is_deleted = Column(Boolean, default=False)
    
    academic_year = relationship("AcademicYear", back_populates="semesters")
    academic_results = relationship("AcademicResult", back_populates="semester", cascade="all, delete-orphan")

class AcademicResult(Base):
    __tablename__ = "academic_results"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.user_id"), nullable=False)
    semester_id = Column(Integer, ForeignKey("semesters.id"), nullable=False)
    
    gpa = Column(Float, default=0.0)  
    cpa = Column(Float, default=0.0)  
    total_credits = Column(Integer, default=0)  
    completed_credits = Column(Integer, default=0)  
    failed_credits = Column(Integer, default=0)  
    
    cumulative_credits = Column(Integer, default=0)  
    
    calculated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    student = relationship("Student", back_populates="academic_results")
    semester = relationship("Semester", back_populates="academic_results")
