from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_active_user
from app.database import get_db
from app.models.user import User, Lecturer, Student
from app.models.academic import Department, Course, Class, Enrollment, Grade
from app.models.academic_year import AcademicYear, Semester, AcademicResult
from app.schemas.academic import (
    CourseCreate, Course as CourseSchema,
    ClassCreate, Class as ClassSchema,
    GradeCreate, Grade as GradeSchema,
    DepartmentCreate, Department as DepartmentSchema
)
from app.schemas.academic_year import (
    AcademicYearCreate, AcademicYear as AcademicYearSchema, AcademicYearUpdate,
    SemesterCreate, Semester as SemesterSchema, SemesterUpdate, SemesterWithYear,
    AcademicResult as AcademicResultSchema, AcademicResultDetail
)
from app.schemas.user import UserCreate, User as UserSchema, UserUpdate
from app.models.enums import UserRole
from app.crud.user import create_user
from app.crud.user import create_user
from app.utils.academic_calculator import calculate_and_save_semester_result, calculate_all_students_in_semester
from app.services.academic_service import (
    academic_year_service, semester_service, department_service, course_service
)
from app.services.class_service import class_service
from app.services.tuition_service import tuition_service
from app.models.timetable import Timetable
from app.services import dean_service


router = APIRouter(prefix="/deans", tags=["deans"])

class DeanStudentResult(BaseModel):
    student_id: int
    student_code: Optional[str] = None
    full_name: str
    gpa: float
    cpa: float
    total_credits: int
    completed_credits: int
    failed_credits: int
    cumulative_credits: int
    semester_code: str
    semester_name: str

@router.get("/academic-results", response_model=List[DeanStudentResult])
def list_academic_results(
    semester_id: Optional[int] = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    from app.services import dean_service
    
    if not semester_id:
        active_sem = db.query(Semester).filter(Semester.is_active == True).first()
        if active_sem:
            semester_id = active_sem.id
    
    if not semester_id:
        return []
    
    return dean_service.get_academic_results_by_semester(semester_id, db, skip=skip, limit=limit)

@router.get("/students/{student_id}/academic-results")
def get_student_academic_results(
    student_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    from app.services import dean_service
    
    result = dean_service.get_student_all_results(student_id, db)
    if not result:
        raise HTTPException(status_code=404, detail="Student not found")
    
    return result

@router.post("/recalculate-all-cpa")
def recalculate_all_cpa(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    from app.services import dean_service
    return dean_service.recalculate_all_cpa(db)


def check_dean_role(user: User):

    if user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized. Dean access required.")

# --- Department Management ---
@router.post("/departments", response_model=DepartmentSchema)
def create_department(
    dept_in: DepartmentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    if department_service.get_by_name(db, name=dept_in.name):
        raise HTTPException(status_code=400, detail="Department already exists")
    
    return department_service.create(db, obj_in=dept_in)

@router.get("/departments", response_model=List[DepartmentSchema])
def list_departments(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)

    return department_service.get_multi(db)

@router.put("/departments/{dept_id}", response_model=DepartmentSchema)
def update_department(
    dept_id: int,
    dept_in: DepartmentCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_dept = db.query(Department).filter(Department.id == dept_id).first()
    if not db_dept:
        raise HTTPException(status_code=404, detail="Department not found")
    
    db_dept.name = dept_in.name
    if dept_in.description:
        db_dept.description = dept_in.description
        
    db.commit()
    db.refresh(db_dept)
    return db_dept

@router.delete("/departments/{dept_id}")
def delete_department(
    dept_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    db_dept = department_service.remove(db, id=dept_id)
    if not db_dept:
        raise HTTPException(status_code=404, detail="Department not found")
        
    return {"message": "Department deleted"}

# --- Course Management ---
@router.post("/courses", response_model=CourseSchema)
def create_course(
    course: CourseCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    if course_service.get_by_code(db, code=course.code):
        raise HTTPException(status_code=400, detail="Course code already exists")

    return course_service.create(db, obj_in=course)

@router.get("/courses", response_model=List[CourseSchema])
def list_courses(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    return course_service.get_multi(db)

@router.put("/courses/{course_id}", response_model=CourseSchema)
def update_course(
    course_id: int,
    course_in: CourseCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_course = db.query(Course).filter(Course.id == course_id).first()
    if not db_course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    db_course.code = course_in.code
    db_course.name = course_in.name
    db_course.credits = course_in.credits
    
    db.commit()
    db.refresh(db_course)
    return db_course

@router.delete("/courses/{course_id}")
def delete_course(
    course_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    db_course = course_service.remove(db, id=course_id)
    if not db_course:
        raise HTTPException(status_code=404, detail="Course not found")
        
    return {"message": "Course deleted"}

# --- Lecturer Management ---
@router.post("/lecturers", response_model=UserSchema)
def create_lecturer(
    user_in: UserCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    try:
        return dean_service.create_lecturer(db, user_in)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/lecturers", response_model=List[UserSchema])
def list_lecturers(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    return dean_service.list_lecturers(db, skip=skip, limit=limit)

@router.put("/lecturers/{user_id}", response_model=UserSchema)
def update_lecturer(
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    user = dean_service.update_lecturer(db, user_id, user_in)
    if not user:
        raise HTTPException(status_code=404, detail="Lecturer not found")
    
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "phone_number": user.phone_number,
        "role": user.role,
        "student_code": None,
        "department_name": user.lecturer.department.name if user.lecturer and user.lecturer.department else None,
        "is_active": True
    }

@router.delete("/lecturers/{user_id}")
def delete_lecturer(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    user = dean_service.delete_lecturer(db, user_id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Lecturer not found")
        
    return {"message": "Lecturer deleted"}

# --- Student Management ---
@router.post("/students", response_model=UserSchema)
def create_student(
    user_in: UserCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    try:
        return dean_service.create_student(db, user_in)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/students", response_model=List[UserSchema])
def list_students(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    return dean_service.list_students(db, skip=skip, limit=limit)

@router.put("/students/{user_id}", response_model=UserSchema)
def update_student(
    user_id: int,
    user_in: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    user = dean_service.update_student(db, user_id, user_in)
    if not user:
         raise HTTPException(status_code=404, detail="Student not found")
    
    # Return with department_name
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "phone_number": user.phone_number,
        "role": user.role,
        "student_code": user.student.student_code if user.student else None,
        "department_name": user.student.department.name if user.student and user.student.department else None,
        "is_active": True
    }

@router.delete("/students/{user_id}")
def delete_student(
    user_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    user = dean_service.delete_student(db, user_id=user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Student not found")
        
    return {"message": "Student deleted"}

# --- Class Management ---
@router.post("/classes", response_model=ClassSchema)
def create_class(
    class_in: ClassCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    check_dean_role(current_user)
    try:
        return class_service.create_class(db, class_in)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/classes", response_model=List[ClassSchema])
def list_classes(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    classes = class_service.get_multi(db, skip=skip, limit=limit)
    
    for c in classes:
        c.enrolled_count = db.query(Enrollment).filter(Enrollment.class_id == c.id).count()
        
    return classes

@router.put("/classes/{class_id}", response_model=ClassSchema)
def update_class(
    class_id: int,
    class_in: ClassCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    updated_class = class_service.update_class(db, class_id, class_in)
    if not updated_class:
        raise HTTPException(status_code=404, detail="Class not found")
        
    return updated_class

@router.delete("/classes/{class_id}")
def delete_class(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    check_dean_role(current_user)
    db_class = class_service.remove(db, id=class_id)
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")

    return {"message": "Class deleted"}

@router.post("/classes/{class_id}/timetable/generate")
def generate_class_timetable(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Tạo thời khóa biểu chi tiết cho lớp học"""
    check_dean_role(current_user)
    class_service.generate_timetable(db, class_id)
    return {"message": "Timetable generated"}

@router.get("/classes/{class_id}/timetable")
def get_class_timetable(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    """Xem thời khóa biểu chi tiết của lớp học"""
    check_dean_role(current_user)
    return db.query(Timetable).filter(Timetable.class_id == class_id).order_by(Timetable.date, Timetable.start_period).all()

# --- Enrollment Management ---
@router.post("/classes/{class_id}/enrollments/bulk")
def bulk_enroll_students(
    class_id: int,
    enrollment_in: dict, 

    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    student_ids = enrollment_in.get('student_ids', [])
    if not student_ids:
         raise HTTPException(status_code=400, detail="No students provided")

    db_class = db.query(Class).filter(Class.id == class_id).first()
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
        
    # Check capacity
    current_count = db.query(Enrollment).filter(Enrollment.class_id == class_id).count()
    if current_count + len(student_ids) > db_class.max_students:
        raise HTTPException(status_code=400, detail=f"Class capacity exceeded. Remaining slots: {db_class.max_students - current_count}")

    added_count = 0
    for student_id in student_ids:
        student = db.query(Student).filter(Student.user_id == student_id).first()
        if not student:
            continue 
            
        existing = db.query(Enrollment).filter(Enrollment.class_id == class_id, Enrollment.student_id == student_id).first()
        if existing:
            continue

        if class_service.check_schedule_conflict(db, student_id, class_id):

             raise HTTPException(status_code=400, detail=f"Schedule conflict detected for student ID {student_id}")
            
        new_enrollment = Enrollment(class_id=class_id, student_id=student_id)
        db.add(new_enrollment)
        added_count += 1
        
    db.commit()

    if db_class.semester:
        for student_id in student_ids:
            try:
                tuition_service.calculate_tuition(db, student_id, db_class.semester)
            except Exception as e:
                print(f"Error calculating tuition for student {student_id}: {e}")

    return {"message": f"Successfully added {added_count} students"}

@router.get("/classes/{class_id}/students", response_model=List[UserSchema])
def list_class_students(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    results = db.query(User).join(Student).join(Enrollment).filter(Enrollment.class_id == class_id).all()
    return results

@router.put("/grades/{grade_id}", response_model=GradeSchema)
def update_grade(
    grade_id: int,
    grade_in: dict, 
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    db_grade = db.query(Grade).filter(Grade.id == grade_id).first()
    if not db_grade:
        raise HTTPException(status_code=404, detail="Grade not found")
        
    if 'score' in grade_in:
        db_grade.score = grade_in['score']
    
    db.commit()
    db.refresh(db_grade)
    
    try:
        enrollment = db_grade.enrollment
        class_obj = enrollment.class_
        semester = db.query(Semester).filter(Semester.code == class_obj.semester).first()
        if semester:
            calculate_and_save_semester_result(enrollment.student_id, semester.id, db)
    except Exception as e:
        print(f"ERROR calculating academic result: {e}")
    
    return db_grade

@router.post("/grades", response_model=GradeSchema)
def create_grade(
    grade_in: GradeCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    enrollment = db.query(Enrollment).filter(Enrollment.id == grade_in.enrollment_id).first()
    if not enrollment:
        raise HTTPException(status_code=404, detail="Enrollment not found")
        
    existing = db.query(Grade).filter(
        Grade.enrollment_id == grade_in.enrollment_id, 
        Grade.grade_type == grade_in.grade_type
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail=f"Grade type {grade_in.grade_type} already exists for this student. Use PUT to update.")

    db_grade = Grade(**grade_in.dict())
    db.add(db_grade)
    db.commit()
    db.refresh(db_grade)
    
    try:
        class_obj = enrollment.class_
        semester = db.query(Semester).filter(Semester.code == class_obj.semester).first()
        if semester:
            calculate_and_save_semester_result(enrollment.student_id, semester.id, db)
    except Exception as e:
        print(f"ERROR calculating academic result: {e}")
    
    return db_grade

# --- Grade Management ---
@router.get("/classes/{class_id}/grades", response_model=List[dict])
def view_class_grades(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    class_obj = db.query(Class).filter(Class.id == class_id).first()
    if not class_obj:
        raise HTTPException(status_code=404, detail="Class not found")

    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    
    results = []
    for enrollment in enrollments:
        student_info = {
            "enrollment_id": enrollment.id,
            "student_id": enrollment.student.user.id,
            "student_code": enrollment.student.student_code,
            "full_name": enrollment.student.user.full_name,
            "full_name": enrollment.student.user.full_name,
            "grades": [
                {
                    "id": g.id, 
                    "grade_type": g.grade_type, 
                    "score": g.score, 
                    "weight": g.weight
                } for g in enrollment.grades
            ]
        }
        results.append(student_info)
        
    return results

@router.get("/classes/{class_id}", response_model=ClassSchema)
def get_class(
    class_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_class = db.query(Class).filter(Class.id == class_id).first()
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    return db_class

# ============= ACADEMIC YEAR MANAGEMENT =============

@router.post("/academic-years", response_model=AcademicYearSchema)
def create_academic_year(
    year_in: AcademicYearCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    if academic_year_service.get_by_year(db, year_in.year):
        raise HTTPException(status_code=400, detail="Academic year already exists")
    
    return academic_year_service.create(db=db, obj_in=year_in)

@router.get("/academic-years", response_model=List[AcademicYearSchema])
def list_academic_years(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)

    return db.query(AcademicYear).order_by(AcademicYear.start_date.desc()).all()

@router.get("/academic-years/{year_id}", response_model=AcademicYearSchema)
def get_academic_year(
    year_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_year = academic_year_service.get(db, year_id)
    if not db_year:
        raise HTTPException(status_code=404, detail="Academic year not found")
    return db_year

@router.put("/academic-years/{year_id}", response_model=AcademicYearSchema)
def update_academic_year(
    year_id: int,
    year_in: AcademicYearUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_year = academic_year_service.get(db, year_id)
    if not db_year:
        raise HTTPException(status_code=404, detail="Academic year not found")
    
    return academic_year_service.update(db=db, db_obj=db_year, obj_in=year_in)

@router.delete("/academic-years/{year_id}")
def delete_academic_year(
    year_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_year = academic_year_service.get(db, year_id)
    if not db_year:
        raise HTTPException(status_code=404, detail="Academic year not found")
    
    academic_year_service.remove(db=db, id=year_id)
    return {"message": "Academic year deleted"}

# ============= SEMESTER MANAGEMENT =============

@router.post("/semesters", response_model=SemesterSchema)
def create_semester(
    semester_in: SemesterCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    if semester_service.get_by_code(db, semester_in.code):
        raise HTTPException(status_code=400, detail="Semester code already exists")
    
    if not academic_year_service.get(db, semester_in.academic_year_id):
        raise HTTPException(status_code=404, detail="Academic year not found")
    
    return semester_service.create(db=db, obj_in=semester_in)

@router.get("/semesters", response_model=List[SemesterWithYear])
def list_semesters(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    return db.query(Semester).order_by(Semester.start_date.desc()).all()

@router.get("/semesters/{semester_id}", response_model=SemesterWithYear)
def get_semester(
    semester_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_semester = semester_service.get(db, semester_id)
    if not db_semester:
        raise HTTPException(status_code=404, detail="Semester not found")
    return db_semester

@router.put("/semesters/{semester_id}", response_model=SemesterSchema)
def update_semester(
    semester_id: int,
    semester_in: SemesterUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    db_semester = semester_service.get(db, semester_id)
    if not db_semester:
        raise HTTPException(status_code=404, detail="Semester not found")
    
    return semester_service.update(db=db, db_obj=db_semester, obj_in=semester_in)

@router.delete("/semesters/{semester_id}")
def delete_semester(
    semester_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    if not semester_service.get(db, semester_id):
        raise HTTPException(status_code=404, detail="Semester not found")
    
    semester_service.remove(db=db, id=semester_id)
    return {"message": "Semester deleted"}

@router.post("/semesters/{semester_id}/activate")
def activate_semester(
    semester_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    db_semester = db.query(Semester).filter(Semester.id == semester_id).first()
    if not db_semester:
        raise HTTPException(status_code=404, detail="Semester not found")
    
    db.query(Semester).update({"is_active": False})
    
    db_semester.is_active = True
    db.commit()
    db.refresh(db_semester)
    
    return {"message": f"Semester {db_semester.code} activated", "semester": db_semester}

# ============= ACADEMIC RESULTS MANAGEMENT =============

@router.post("/semesters/{semester_id}/calculate-results")
def calculate_semester_results(
    semester_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    try:
        count = calculate_all_students_in_semester(semester_id, db)
        return {"message": f"Calculated results for {count} students", "count": count}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.post("/students/{student_id}/calculate-result/{semester_id}")
def calculate_student_semester_result(
    student_id: int,
    semester_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    if not db.query(Student).filter(Student.user_id == student_id).first():
        raise HTTPException(status_code=404, detail="Student not found")
    
    try:
        result = calculate_and_save_semester_result(student_id, semester_id, db)
        return {
            "message": "Result calculated successfully",
            "gpa": result.gpa,
            "cpa": result.cpa
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))

@router.get("/students/{student_id}/results", response_model=List[AcademicResultDetail])
def get_student_results(
    student_id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    check_dean_role(current_user)
    
    if not db.query(Student).filter(Student.user_id == student_id).first():
        raise HTTPException(status_code=404, detail="Student not found")
    
    results = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id
    ).join(Semester).order_by(Semester.start_date).all()
    
    result_list = []
    for result in results:
        result_dict = {
            "id": result.id,
            "student_id": result.student_id,
            "semester_id": result.semester_id,
            "gpa": result.gpa,
            "cpa": result.cpa,
            "total_credits": result.total_credits,
            "completed_credits": result.completed_credits,
            "failed_credits": result.failed_credits,
            "cumulative_credits": result.cumulative_credits,
            "calculated_at": result.calculated_at,
            "semester_code": result.semester.code,
            "semester_name": result.semester.name
        }
        result_list.append(result_dict)
    
    return result_list
