from typing import List, Optional
from pydantic import BaseModel
from datetime import date, time

# Department
class DepartmentBase(BaseModel):
    name: str
    description: Optional[str] = None

class DepartmentCreate(DepartmentBase):
    pass

class Department(DepartmentBase):
    id: int
    class Config:
        from_attributes = True

# Course
class CourseBase(BaseModel):
    code: str
    name: str
    credits: int

class CourseCreate(CourseBase):
    pass

class Course(CourseBase):
    id: int
    class Config:
        from_attributes = True

# Class
class ClassBase(BaseModel):
    code: str
    course_id: int
    lecturer_id: int
    semester: str
    max_students: int = 50
    start_week: Optional[int] = None
    end_week: Optional[int] = None
    day_of_week: Optional[int] = None
    start_period: Optional[int] = None
    end_period: Optional[int] = None
    room: Optional[str] = None

class ClassCreate(ClassBase):
    pass

class Class(ClassBase):
    id: int
    course: Optional[Course] = None 
    enrolled_count: int = 0
    class Config:
        from_attributes = True

# Enrollment & Grade
class GradeBase(BaseModel):
    grade_type: str
    score: float
    weight: float = 1.0

class GradeCreate(GradeBase):
    enrollment_id: int

class Grade(GradeBase):
    id: int
    class Config:
        from_attributes = True

class EnrollmentBase(BaseModel):
    class_id: int
    student_id: int

class EnrollmentBulkCreate(BaseModel):
    student_ids: List[int]

class Enrollment(EnrollmentBase):
    id: int
    grades: List[Grade] = []
    class_info: Optional[Class] = None 
    class Config:
        from_attributes = True

class StudentGradeView(BaseModel):
    course_name: str
    class_code: str
    grades: List[Grade]

# Mobile Specific Schemas
class MobileStudentResponse(BaseModel):
    enrollment_id: int
    student_id: str
    student_name: str
    midterm_grade: Optional[float] = None
    final_grade: Optional[float] = None
    grade: Optional[float] = None 
class MobileClassResponse(BaseModel):
    id: int
    course_name: str
    lecturer_name: str
    room: Optional[str] = "Online"
    day_of_week: Optional[int] = None
    start_week: Optional[int] = None
    end_week: Optional[int] = None
    start_period: Optional[int] = None
    end_period: Optional[int] = None

class MobileGradeResponse(BaseModel):
    course_name: str
    credits: int
    grade: Optional[float] = None
    details: List[GradeBase] = []

class MobileTimetableResponse(BaseModel):
    id: int
    date: date
    start_period: int
    end_period: int
    room: Optional[str] = None
    course_name: str
    class_code: str
    lecturer_name: str


