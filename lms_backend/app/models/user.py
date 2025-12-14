from sqlalchemy import Column, Integer, String, Enum, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.enums import UserRole

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False)
    full_name = Column(String)
    phone_number = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", uselist=False, back_populates="user")
    lecturer = relationship("Lecturer", uselist=False, back_populates="user")

    @property
    def student_code(self):
        return self.student.student_code if self.student else None

class Student(Base):
    __tablename__ = "students"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    student_code = Column(String, unique=True, index=True, nullable=False)
    department_id = Column(Integer, ForeignKey("departments.id"))
    
    user = relationship("User", back_populates="student")
    department = relationship("Department", back_populates="students")
    enrollments = relationship("Enrollment", back_populates="student")
    academic_results = relationship("AcademicResult", back_populates="student")
    cumulative_result = relationship("CumulativeResult", back_populates="student", uselist=False)
    tuitions = relationship("Tuition", back_populates="student")

class Lecturer(Base):
    __tablename__ = "lecturers"

    user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    lecturer_code = Column(String, unique=True, index=True, nullable=False)
    department_id = Column(Integer, ForeignKey("departments.id"))

    user = relationship("User", back_populates="lecturer")
    department = relationship("Department", back_populates="lecturers")
    classes = relationship("Class", back_populates="lecturer")
