from typing import List, Optional
from pydantic import BaseModel
from datetime import date, datetime

# ============= Academic Year Schemas =============

class AcademicYearBase(BaseModel):
    year: str  
    start_date: date
    end_date: date
    is_active: bool = True

class AcademicYearCreate(AcademicYearBase):
    pass

class AcademicYearUpdate(BaseModel):
    year: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None

class AcademicYear(AcademicYearBase):
    id: int
    
    class Config:
        from_attributes = True

# ============= Semester Schemas =============

class SemesterBase(BaseModel):
    code: str 
    name: str  
    academic_year_id: int
    semester_number: int 
    start_date: date
    end_date: date
    is_active: bool = False

class SemesterCreate(SemesterBase):
    pass

class SemesterUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    academic_year_id: Optional[int] = None
    semester_number: Optional[int] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    is_active: Optional[bool] = None

class Semester(SemesterBase):
    id: int
    
    class Config:
        from_attributes = True

class SemesterWithYear(Semester):
    """Semester kèm thông tin năm học"""
    academic_year: Optional[AcademicYear] = None

# ============= Academic Result Schemas =============

class AcademicResultBase(BaseModel):
    gpa: float
    cpa: float
    total_credits: int
    completed_credits: int
    failed_credits: int = 0
    cumulative_credits: int = 0

class AcademicResultCreate(BaseModel):
    student_id: int
    semester_id: int

class AcademicResult(AcademicResultBase):
    id: int
    student_id: int
    semester_id: int
    calculated_at: datetime
    
    class Config:
        from_attributes = True

class AcademicResultDetail(AcademicResult):
    """Kết quả học tập kèm thông tin học kỳ"""
    semester_code: Optional[str] = None
    semester_name: Optional[str] = None

# ============= Mobile Response Schemas =============

class MobileAcademicResultResponse(BaseModel):
    """Response cho mobile app - danh sách kết quả theo học kỳ"""
    semester_code: str
    semester_name: str
    gpa: float
    cpa: float
    total_credits: int
    completed_credits: int
    failed_credits: int

class CourseGradeDetail(BaseModel):
    """Chi tiết điểm của 1 môn học"""
    course_code: str
    course_name: str
    credits: int
    score_10: Optional[float] = None 
    score_4: Optional[float] = None  
    letter_grade: Optional[str] = None  
    grade_type: Optional[str] = None  

class MobileSemesterDetailResponse(BaseModel):
    """Chi tiết kết quả 1 học kỳ cho mobile"""
    semester_code: str
    semester_name: str
    gpa: float
    cpa: float
    total_credits: int
    completed_credits: int
    failed_credits: int
    courses: List[CourseGradeDetail] = []
