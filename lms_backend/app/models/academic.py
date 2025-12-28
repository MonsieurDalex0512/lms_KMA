from sqlalchemy import Column, Integer, String, ForeignKey, Float, Date, Time
from sqlalchemy.orm import relationship
from app.database import Base

class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True, nullable=False)
    description = Column(String)

    students = relationship("Student", back_populates="department")
    lecturers = relationship("Lecturer", back_populates="department")

class Course(Base):
    __tablename__ = "courses"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False) 
    name = Column(String, nullable=False)
    credits = Column(Integer, nullable=False)
    classes = relationship("Class", back_populates="course")

class Class(Base):
    __tablename__ = "classes"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, index=True, nullable=False) 
    course_id = Column(Integer, ForeignKey("courses.id"))
    lecturer_id = Column(Integer, ForeignKey("lecturers.user_id"))
    semester = Column(String)
    max_students = Column(Integer, default=50)
    
    start_week = Column(Integer)
    end_week = Column(Integer)
    day_of_week = Column(Integer) # 2=Mon, 8=Sun
    start_period = Column(Integer)
    end_period = Column(Integer)
    room = Column(String, nullable=True)

    course = relationship("Course", back_populates="classes")
    lecturer = relationship("Lecturer", back_populates="classes")
    enrollments = relationship("Enrollment", back_populates="class_")
    schedules = relationship("Schedule", back_populates="class_")
    timetables = relationship("Timetable", back_populates="class_")

class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("classes.id"))
    day_of_week = Column(String)
    start_time = Column(Time)
    end_time = Column(Time)
    room = Column(String)

    class_ = relationship("Class", back_populates="schedules")

class Enrollment(Base):
    __tablename__ = "enrollments"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.user_id"))
    class_id = Column(Integer, ForeignKey("classes.id"))

    student = relationship("Student", back_populates="enrollments")
    class_ = relationship("Class", back_populates="enrollments")
    grades = relationship("Grade", back_populates="enrollment")

class Grade(Base):
    __tablename__ = "grades"

    id = Column(Integer, primary_key=True, index=True)
    enrollment_id = Column(Integer, ForeignKey("enrollments.id"))
    grade_type = Column(String) 
    score = Column(Float)
    weight = Column(Float, default=1.0)

    enrollment = relationship("Enrollment", back_populates="grades")
