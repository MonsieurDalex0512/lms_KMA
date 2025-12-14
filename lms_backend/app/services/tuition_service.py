from sqlalchemy.orm import Session
from app.models.tuition import Tuition
from app.models.academic import Enrollment, Class, Course
from app.models.setting import Setting

DEFAULT_PRICE_PER_CREDIT = 500000

class TuitionService:
    def get_current_price(self, db: Session) -> int:
        setting = db.query(Setting).filter(Setting.key == "tuition_price_per_credit").first()
        if setting:
            return int(setting.value)
        return DEFAULT_PRICE_PER_CREDIT

    def set_current_price(self, db: Session, price: int):

        setting = db.query(Setting).filter(Setting.key == "tuition_price_per_credit").first()
        if not setting:
            setting = Setting(key="tuition_price_per_credit", value=str(price))
            db.add(setting)
        else:
            setting.value = str(price)
        db.commit()
        db.refresh(setting)
        
        all_tuitions = db.query(Tuition).all()
        for tuition in all_tuitions:
            enrollments = db.query(Enrollment).join(Class).filter(
                Enrollment.student_id == tuition.student_id,
                Class.semester == tuition.semester
            ).all()

            total_credits = 0
            for enrollment in enrollments:
                course = db.query(Course).filter(Course.id == enrollment.class_.course_id).first()
                if course:
                    total_credits += course.credits
            
            new_total = total_credits * price
            tuition.total_amount = new_total

            if tuition.paid_amount >= new_total:
                tuition.status = "COMPLETED"
            elif tuition.paid_amount > 0:
                tuition.status = "PARTIAL"
            else:
                tuition.status = "COMPLETED" if new_total == 0 else "PENDING"
            
            db.add(tuition)
        
        db.commit()
        return int(setting.value)

    def calculate_tuition(self, db: Session, student_id: int, semester: str):
        enrollments = db.query(Enrollment).join(Class).filter(
            Enrollment.student_id == student_id,
            Class.semester == semester
        ).all()

        total_credits = 0
        for enrollment in enrollments:
            course = db.query(Course).filter(Course.id == enrollment.class_.course_id).first()
            if course:
                total_credits += course.credits
        
        current_price = self.get_current_price(db)
        expected_total = total_credits * current_price

        tuition_record = db.query(Tuition).filter(
            Tuition.student_id == student_id,
            Tuition.semester == semester
        ).first()

        if not tuition_record:
            tuition_record = Tuition(
                student_id=student_id,
                semester=semester,
                total_amount=expected_total,
                paid_amount=0,
                status="PENDING" if expected_total > 0 else "COMPLETED"
            )
            db.add(tuition_record)
        else:
            tuition_record.total_amount = expected_total
            if tuition_record.paid_amount >= expected_total:
                tuition_record.status = "COMPLETED"
            elif tuition_record.paid_amount > 0:
                tuition_record.status = "PARTIAL"
            else:
                tuition_record.status = "COMPLETED" if expected_total == 0 else "PENDING"
        
        db.commit()
        db.refresh(tuition_record)
        return tuition_record

    def update_payment(self, db: Session, tuition_id: int, paid_amount: int):
        tuition_record = db.query(Tuition).filter(Tuition.id == tuition_id).first()
        if not tuition_record:
            return None
        
        tuition_record.paid_amount = paid_amount
        
        if tuition_record.paid_amount >= tuition_record.total_amount:
            tuition_record.status = "COMPLETED"
        elif tuition_record.paid_amount > 0:
             tuition_record.status = "PARTIAL"
        else:
             tuition_record.status = "PENDING"
             
        db.commit()
        db.refresh(tuition_record)
        return tuition_record

    def get_student_tuitions(self, db: Session, student_id: int):
        return db.query(Tuition).filter(Tuition.student_id == student_id).all()

    def get_all_tuitions(self, db: Session, skip: int = 0, limit: int = 100):
        return db.query(Tuition).offset(skip).limit(limit).all()

tuition_service = TuitionService()
