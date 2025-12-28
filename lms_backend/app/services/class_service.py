from datetime import timedelta, date
from sqlalchemy.orm import Session
from app.models.academic import Class, Enrollment, Schedule
from app.models.timetable import Timetable
from app.models.academic_year import Semester
from app.services.base import BaseService

from app.models.user import Lecturer, User
from app.models.enums import UserRole
from app.schemas.academic import ClassCreate

class ClassService(BaseService[Class]):
    def create_class(self, db: Session, class_in: ClassCreate):
        lecturer = db.query(Lecturer).filter(Lecturer.user_id == class_in.lecturer_id).first()
        if not lecturer:
            user = db.query(User).filter(User.id == class_in.lecturer_id, User.role == UserRole.LECTURER).first()
            if user:
                lecturer = Lecturer(user_id=user.id, lecturer_code=f"LEC{user.id}")
                db.add(lecturer)
                db.commit()
            else:
                raise ValueError("Invaild lecturer selected")
        
        db_class = Class(**class_in.dict())
        db.add(db_class)
        db.commit()
        db.refresh(db_class)
        
        self.generate_timetable(db, db_class.id)
        return db_class

    def update_class(self, db: Session, class_id: int, class_in: ClassCreate):
        db_class = self.get(db, class_id)
        if not db_class:
            return None
            
        schedule_fields = ['start_week', 'end_week', 'day_of_week', 'start_period', 'end_period']
        schedule_changed = False
        
        for key, value in class_in.dict().items():
            if key in schedule_fields and getattr(db_class, key) != value:
                schedule_changed = True
            setattr(db_class, key, value)
            
        db.commit()
        db.refresh(db_class)
        
        if schedule_changed:
            self.generate_timetable(db, db_class.id)
            
        return db_class

    def generate_timetable(self, db: Session, class_id: int):
        db_class = self.get(db, class_id)
        if not db_class or not db_class.semester:
            return

        semester = db.query(Semester).filter(Semester.code == db_class.semester).first()
        if not semester or not semester.start_date:
            return

        start_date = semester.start_date

        db.query(Timetable).filter(Timetable.class_id == class_id).delete()
        
        schedules_to_process = []
        if db_class.schedules:
            for s in db_class.schedules:
                
                try:
                    dow = int(s.day_of_week) if s.day_of_week else None
                except:
                    dow = None 
                
                if dow:
                    schedules_to_process.append({
                        "day_of_week": dow,
                        "start_period": 1, 
                        "end_period": 3,   
                        "room": s.room
                    })
        
        if not schedules_to_process:
            if db_class.day_of_week:
                schedules_to_process.append({
                    "day_of_week": db_class.day_of_week,
                    "start_period": db_class.start_period,
                    "end_period": db_class.end_period,
                    "room": db_class.room or "Unknown"
                })

        new_timetables = []
        for sche in schedules_to_process:
            dow = sche["day_of_week"]
            target_weekday = dow - 2 # 2->0 (Mon)
            
            for week in range(db_class.start_week or 1, (db_class.end_week or 15) + 1):
                
                aligned_start = start_date - timedelta(days=start_date.weekday())
                week_monday = aligned_start + timedelta(weeks=week-1)
                target_date = week_monday + timedelta(days=target_weekday)
                                
                tt = Timetable(
                    class_id=class_id,
                    date=target_date,
                    start_period=sche["start_period"],
                    end_period=sche["end_period"],
                    room=sche["room"]
                )
                new_timetables.append(tt)
        
        if new_timetables:
            db.add_all(new_timetables)
            db.commit()

    def check_schedule_conflict(self, db: Session, student_id: int, class_id: int) -> bool:
        self.generate_timetable(db, class_id)
        
        new_timetables = db.query(Timetable).filter(Timetable.class_id == class_id).all()
        if not new_timetables:
            return False
            
        student_enrollments = db.query(Enrollment).filter(Enrollment.student_id == student_id).all()
        existing_class_ids = [e.class_id for e in student_enrollments]
        
        if not existing_class_ids:
            return False
            
        existing_timetables = db.query(Timetable).filter(Timetable.class_id.in_(existing_class_ids)).all()
        
        for new_tt in new_timetables:
            for exist_tt in existing_timetables:
                if new_tt.date == exist_tt.date:
                    
                    if max(new_tt.start_period, exist_tt.start_period) <= min(new_tt.end_period, exist_tt.end_period):
                        return True
        return False

class_service = ClassService(Class)
