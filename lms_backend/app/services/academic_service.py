from sqlalchemy.orm import Session
from app.models.academic_year import AcademicYear, Semester
from app.services.base import BaseService

class AcademicYearService(BaseService[AcademicYear]):
    def get(self, db: Session, id: int):
        return db.query(AcademicYear).filter(AcademicYear.id == id, AcademicYear.is_deleted == False).first()

    def get_multi(self, db: Session, *, skip: int = 0, limit: int = 100):
        return db.query(AcademicYear).filter(AcademicYear.is_deleted == False).order_by(AcademicYear.start_date.desc()).offset(skip).limit(limit).all()

    def get_by_year(self, db: Session, year: str):
        return db.query(AcademicYear).filter(AcademicYear.year == year, AcademicYear.is_deleted == False).first()
    
    def remove(self, db: Session, *, id: int):
        obj = db.query(AcademicYear).get(id)
        if obj:
            obj.is_deleted = True
            db.commit()
            db.refresh(obj)
        return obj

class SemesterService(BaseService[Semester]):
    def get(self, db: Session, id: int):
        return db.query(Semester).filter(Semester.id == id, Semester.is_deleted == False).first()

    def get_multi(self, db: Session, *, skip: int = 0, limit: int = 100):
        return db.query(Semester).filter(Semester.is_deleted == False).order_by(Semester.start_date.desc()).offset(skip).limit(limit).all()

    def get_by_code(self, db: Session, code: str):
        return db.query(Semester).filter(Semester.code == code, Semester.is_deleted == False).first()
    
    def get_active_semester(self, db: Session):
        return db.query(Semester).filter(Semester.is_active == True, Semester.is_deleted == False).first()
    
    def remove(self, db: Session, *, id: int):
        obj = db.query(Semester).get(id)
        if obj:
            obj.is_deleted = True
            db.commit()
            db.refresh(obj)
        return obj


from app.models.academic import Department, Course

class DepartmentService(BaseService[Department]):
    def get_by_name(self, db: Session, name: str):
        return db.query(Department).filter(Department.name == name).first()

class CourseService(BaseService[Course]):
    def get_by_code(self, db: Session, code: str):
        return db.query(Course).filter(Course.code == code).first()

academic_year_service = AcademicYearService(AcademicYear)
semester_service = SemesterService(Semester)
department_service = DepartmentService(Department)
course_service = CourseService(Course)
