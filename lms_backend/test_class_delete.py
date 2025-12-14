"""
Script để test việc xóa lớp và đảm bảo grades/enrollments được xóa đúng
"""
import sys
import os
import io

# Fix encoding for Windows console
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal
from app.models.academic import Class, Enrollment, Grade
from app.models.timetable import Timetable
from app.models.academic_year import Semester

def test_class_delete():
    db = SessionLocal()
    try:
        print("=" * 60)
        print("KIỂM TRA XÓA LỚP VÀ DỮ LIỆU LIÊN QUAN")
        print("=" * 60)
        
        # Tìm một lớp có enrollments và grades
        classes_with_data = db.query(Class).join(Enrollment).join(Grade).distinct().limit(5).all()
        
        if not classes_with_data:
            print("\n❌ Không tìm thấy lớp nào có enrollments và grades để test")
            return
        
        for cls in classes_with_data:
            print(f"\n📚 Lớp: {cls.code} (ID: {cls.id})")
            
            # Đếm enrollments
            enrollments = db.query(Enrollment).filter(Enrollment.class_id == cls.id).all()
            enrollment_count = len(enrollments)
            print(f"   - Số enrollments: {enrollment_count}")
            
            # Đếm grades
            total_grades = 0
            for enr in enrollments:
                grades = db.query(Grade).filter(Grade.enrollment_id == enr.id).all()
                total_grades += len(grades)
                if grades:
                    print(f"     Enrollment {enr.id} (Student {enr.student_id}): {len(grades)} grades")
                    for g in grades:
                        print(f"       - {g.grade_type}: {g.score}")
            
            print(f"   - Tổng số grades: {total_grades}")
            
            # Đếm timetables
            timetables = db.query(Timetable).filter(Timetable.class_id == cls.id).all()
            print(f"   - Số timetables: {len(timetables)}")
            
            if enrollment_count > 0 and total_grades > 0:
                print(f"\n   ✅ Lớp này có dữ liệu để test")
                print(f"   ⚠️  LƯU Ý: Script này chỉ kiểm tra, không xóa thật!")
                break
        
        print("\n\n" + "=" * 60)
        print("KIỂM TRA LOGIC XÓA:")
        print("=" * 60)
        print("""
Khi xóa lớp, logic sẽ:
1. Lấy danh sách enrollments của lớp
2. Lấy danh sách enrollment_ids
3. Xóa TẤT CẢ grades có enrollment_id trong danh sách → COMMIT
4. Xóa TẤT CẢ enrollments của lớp → COMMIT
5. Xóa timetables → COMMIT
6. Xóa schedules → COMMIT
7. Xóa lớp → COMMIT
8. Recalculate semester results cho tất cả students bị ảnh hưởng

Để test thực tế:
1. Tạo một lớp test
2. Enroll 1-2 students
3. Nhập điểm cho students
4. Xóa lớp qua API
5. Kiểm tra database xem grades và enrollments đã bị xóa chưa
        """)
        
    except Exception as e:
        print(f"❌ Lỗi: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_class_delete()
