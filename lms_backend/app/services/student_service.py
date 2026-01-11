from typing import List, Optional, Tuple
from sqlalchemy.orm import Session
from app.models.user import Student, User
from app.models.academic import Enrollment, Grade, Class, Course
from app.models.academic_year import AcademicResult, Semester
from app.models.cumulative_result import CumulativeResult
from app.utils.academic_calculator import convert_score_to_grade_4, calculate_final_score

def get_student_enrollments(student_id: int, db: Session) -> List[Enrollment]:
    return db.query(Enrollment).filter(Enrollment.student_id == student_id).all()

def get_student_classes(student_id: int, db: Session):
    from app.models.academic_year import Semester
    
    try:
        # Get active semester to identify current classes
        active_semester = db.query(Semester).filter(
            Semester.is_active == True,
            Semester.is_deleted == False
        ).first()
        active_semester_code = active_semester.code if active_semester else None
        
        enrollments = get_student_enrollments(student_id, db)
        result = []
        
        for e in enrollments:
            try:
                class_info = e.class_
                if not class_info:
                    continue
                
                course_name = "Unknown"
                course_code = None
                credits = 0
                try:
                    if class_info.course:
                        course_name = class_info.course.name or "Unknown"
                        course_code = class_info.course.code
                        credits = class_info.course.credits or 0
                except:
                    pass
                
                lecturer_name = "Unknown"
                try:
                    if class_info.lecturer and class_info.lecturer.user:
                        lecturer_name = class_info.lecturer.user.full_name or "Unknown"
                except:
                    pass
                
                result.append({
                    "id": class_info.id,
                    "class_code": class_info.code or None,
                    "course_name": course_name,
                    "course_code": course_code,
                    "lecturer_name": lecturer_name,
                    "room": class_info.room or "Online",
                    "semester": class_info.semester,
                    "semester_code": class_info.semester,
                    "is_current": class_info.semester == active_semester_code if active_semester_code else False,
                    "day_of_week": class_info.day_of_week,
                    "start_week": class_info.start_week,
                    "end_week": class_info.end_week,
                    "start_period": class_info.start_period,
                    "end_period": class_info.end_period,
                    "credits": credits
                })
            except Exception as ex:
                import traceback
                print(f"Error processing enrollment {e.id}: {ex}")
                print(traceback.format_exc())
                continue
        
        return result
    except Exception as e:
        import traceback
        print(f"Error in get_student_classes: {e}")
        print(traceback.format_exc())
        raise

def get_student_grades(student_id: int, db: Session):
    enrollments = get_student_enrollments(student_id, db)
    results = []
    
    for enrollment in enrollments:
        class_info = enrollment.class_
        course_info = class_info.course
        
        display_grade = None
        for g in enrollment.grades:
            if g.grade_type == 'final':
                display_grade = g.score
                break
        if display_grade is None and enrollment.grades:
            display_grade = enrollment.grades[0].score

        grade_details = [
            {'grade_type': g.grade_type, 'score': g.score, 'weight': g.weight}
            for g in enrollment.grades
        ]

        results.append({
            "course_name": course_info.name,
            "credits": course_info.credits,
            "grade": display_grade,
            "details": grade_details
        })
    return results

def get_student_projects(student_id: int, db: Session):
    enrollments = db.query(Enrollment).join(Class).join(Course).filter(
        Enrollment.student_id == student_id,
        Course.name.ilike("%đồ án%")
    ).all()
    
    return [
        {
            "id": e.class_.id,
            "course_name": e.class_.course.name,
            "lecturer_name": e.class_.lecturer.user.full_name if e.class_.lecturer else "N/A",
            "room": e.class_.room or "N/A",
            "start_week": e.class_.start_week,
            "end_week": e.class_.end_week,
            "day_of_week": None,
            "start_period": None,
            "end_period": None
        }
        for e in enrollments
    ]

def get_academic_summary(student_id: int, db: Session):
    semester_results = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id
    ).join(Semester).order_by(Semester.start_date).all()
    
    cumulative = db.query(CumulativeResult).filter(
        CumulativeResult.student_id == student_id
    ).first()
    
    semesters = [
        {
            "semester_code": r.semester.code,
            "semester_name": r.semester.name,
            "gpa": r.gpa,
            "total_credits": r.total_credits,
            "completed_credits": r.completed_credits,
            "failed_credits": r.failed_credits
        }
        for r in semester_results
    ]
    
    return {
        "semester_results": semesters,
        "cumulative_cpa": cumulative.cpa if cumulative else 0.0,
        "total_registered_credits": cumulative.total_registered_credits if cumulative else 0,
        "total_completed_credits": cumulative.total_completed_credits if cumulative else 0,
        "total_failed_credits": cumulative.total_failed_credits if cumulative else 0
    }

def get_semester_detail(student_id: int, semester_code: str, db: Session):
    semester = db.query(Semester).filter(Semester.code == semester_code).first()
    if not semester:
        return None
    
    result = db.query(AcademicResult).filter(
        AcademicResult.student_id == student_id,
        AcademicResult.semester_id == semester.id
    ).first()
    
    if not result:
        return None
    
    enrollments = db.query(Enrollment).join(Class).filter(
        Enrollment.student_id == student_id,
        Class.semester == semester_code
    ).all()
    
    courses = []
    for enrollment in enrollments:
        course = enrollment.class_.course
        final_score_10 = calculate_final_score(enrollment.grades)
        
        if final_score_10 is not None:
            score_4, letter_grade = convert_score_to_grade_4(final_score_10)
        else:
            score_4 = None
            letter_grade = None
        
        courses.append({
            "course_code": course.code,
            "course_name": course.name,
            "credits": course.credits,
            "score_10": final_score_10,
            "score_4": score_4,
            "letter_grade": letter_grade,
            "grade_type": "final"
        })
    
    return {
        "semester_code": semester.code,
        "semester_name": semester.name,
        "gpa": result.gpa,
        "cpa": result.cpa,
        "total_credits": result.total_credits,
        "completed_credits": result.completed_credits,
        "failed_credits": result.failed_credits,
        "courses": courses
    }

def get_student_timetable(student_id: int, db: Session):
    from app.models.timetable import Timetable
    
    try:
        # Get enrolled class IDs first
        enrolled_classes = db.query(Enrollment.class_id).filter(
            Enrollment.student_id == student_id
        ).distinct().all()
        
        if not enrolled_classes:
            return []
        
        class_ids = [row[0] for row in enrolled_classes]
        
        # Query timetables for those classes
        timetables = db.query(Timetable).filter(
            Timetable.class_id.in_(class_ids)
        ).order_by(Timetable.date, Timetable.start_period).all()
        
        result = []
        for t in timetables:
            try:
                course_name = "Unknown"
                class_code = "Unknown"
                lecturer_name = "Unknown"
                
                # Access class relationship - use try/except for each access
                try:
                    if t.class_:
                        class_code = t.class_.code or "Unknown"
                        
                        # Access course
                        try:
                            if t.class_.course:
                                course_name = t.class_.course.name or "Unknown"
                        except:
                            pass
                        
                        # Access lecturer and user
                        try:
                            if t.class_.lecturer and t.class_.lecturer.user:
                                lecturer_name = t.class_.lecturer.user.full_name or "Unknown"
                        except:
                            pass
                except:
                    pass
                
                result.append({
                    "id": t.id,
                    "date": t.date,
                    "start_period": t.start_period,
                    "end_period": t.end_period,
                    "room": t.room,
                    "course_name": course_name,
                    "class_code": class_code,
                    "lecturer_name": lecturer_name
                })
            except Exception as e:
                import traceback
                print(f"Error processing timetable item {t.id}: {e}")
                print(traceback.format_exc())
                # Add with default values on error
                result.append({
                    "id": t.id,
                    "date": t.date,
                    "start_period": t.start_period or 0,
                    "end_period": t.end_period or 0,
                    "room": t.room or "",
                    "course_name": "Unknown",
                    "class_code": "Unknown",
                    "lecturer_name": "Unknown"
                })
        
        return result
    except Exception as e:
        import traceback
        error_msg = f"Error in get_student_timetable: {e}\n{traceback.format_exc()}"
        print(error_msg)
        raise Exception(error_msg)
