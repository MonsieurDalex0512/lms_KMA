"""
Migration script: Tạo bảng cumulative_results và backfill data

Chạy script này để:
1. Tạo bảng cumulative_results
2. Tính toán và điền dữ liệu CPA cho tất cả sinh viên hiện có
"""

from sqlalchemy import create_engine, Column, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker
from app.database import get_db, Base
from app.models.cumulative_result import CumulativeResult
from app.models.user import Student
from app.utils.academic_calculator import calculate_cumulative_cpa_from_courses
import sys

def create_cumulative_results_table():
    """Tạo bảng cumulative_results"""
    print("Creating cumulative_results table...")
    Base.metadata.create_all(bind=get_db().__next__().bind, tables=[CumulativeResult.__table__])
    print("✓ Table created successfully")

def backfill_cumulative_results():
    """Tính toán và điền CPA cho tất cả sinh viên"""
    print("\nBackfilling cumulative results...")
    db = next(get_db())
    
    try:
        # Lấy tất cả sinh viên
        students = db.query(Student).all()
        print(f"Found {len(students)} students")
        
        count_success = 0
        count_skip = 0
        
        for student in students:
            try:
                # Tính CPA từ tất cả các môn học
                from app.utils.academic_calculator import calculate_cumulative_cpa_from_courses
                cpa, registered, completed, failed = calculate_cumulative_cpa_from_courses(student.user_id, db)
                
                # Tạo hoặc cập nhật record
                cumulative = db.query(CumulativeResult).filter(
                    CumulativeResult.student_id == student.user_id
                ).first()
                
                if cumulative:
                    cumulative.cpa = cpa
                    cumulative.total_registered_credits = registered
                    cumulative.total_completed_credits = completed
                    cumulative.total_failed_credits = failed
                else:
                    cumulative = CumulativeResult(
                        student_id=student.user_id,
                        cpa=cpa,
                        total_registered_credits=registered,
                        total_completed_credits=completed,
                        total_failed_credits=failed
                    )
                    db.add(cumulative)
                
                db.commit()
                count_success += 1
                print(f"  ✓ Student {student.student_code}: CPA={cpa}, Credits={registered}")
                
            except Exception as e:
                print(f"  ✗ Error for student {student.student_code}: {e}")
                count_skip += 1
                db.rollback()
                continue
        
        print(f"\n✓ Backfill completed: {count_success} success, {count_skip} skipped")
        
    except Exception as e:
        print(f"✗ Error during backfill: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("=== Migration: Create cumulative_results table ===\n")
    
    # Bước 1: Tạo bảng
    create_cumulative_results_table()
    
    # Bước 2: Backfill data
    backfill_cumulative_results()
    
    print("\n=== Migration completed ===")
