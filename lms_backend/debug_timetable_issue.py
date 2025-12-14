"""
Script để debug vấn đề timetable không hiển thị trên mobile app
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
from app.models.academic import Class, Enrollment
from app.models.timetable import Timetable
from app.models.academic_year import Semester
from app.models.user import Student, User
from sqlalchemy.orm import joinedload

def check_timetable_issue():
    db = SessionLocal()
    try:
        print("=" * 60)
        print("KIỂM TRA VẤN ĐỀ TIMETABLE")
        print("=" * 60)
        
        # 1. Kiểm tra tất cả các lớp học
        print("\n1. DANH SÁCH TẤT CẢ LỚP HỌC:")
        print("-" * 60)
        classes = db.query(Class).options(
            joinedload(Class.course),
            joinedload(Class.lecturer)
        ).all()
        
        if not classes:
            print("❌ Không có lớp học nào trong hệ thống!")
            return
        
        for cls in classes:
            print(f"\n📚 Lớp: {cls.code} (ID: {cls.id})")
            print(f"   - Môn học: {cls.course.name if cls.course else 'N/A'}")
            print(f"   - Học kỳ: {cls.semester or '❌ CHƯA CÓ'}")
            print(f"   - Thứ: {cls.day_of_week or '❌ CHƯA CÓ'}")
            print(f"   - Tuần: {cls.start_week or 'N/A'} - {cls.end_week or 'N/A'}")
            print(f"   - Tiết: {cls.start_period or 'N/A'} - {cls.end_period or 'N/A'}")
            print(f"   - Phòng: {cls.room or 'N/A'}")
            
            # Kiểm tra semester
            if cls.semester:
                semester = db.query(Semester).filter(Semester.code == cls.semester).first()
                if semester:
                    print(f"   - ✅ Semester tồn tại: {semester.name}")
                    print(f"   - ✅ Start date: {semester.start_date}")
                else:
                    print(f"   - ❌ Semester '{cls.semester}' KHÔNG TỒN TẠI trong database!")
            
            # Kiểm tra timetable
            timetables = db.query(Timetable).filter(Timetable.class_id == cls.id).all()
            print(f"   - Timetable records: {len(timetables)}")
            if timetables:
                print(f"     ✅ Có {len(timetables)} buổi học đã được tạo")
                print(f"     - Ngày đầu: {min(t.date for t in timetables)}")
                print(f"     - Ngày cuối: {max(t.date for t in timetables)}")
            else:
                print(f"     ❌ CHƯA CÓ TIMETABLE!")
                if not cls.semester:
                    print(f"     ⚠️  Nguyên nhân: Lớp chưa có semester code")
                elif not cls.day_of_week:
                    print(f"     ⚠️  Nguyên nhân: Lớp chưa có day_of_week")
                elif not cls.start_week or not cls.end_week:
                    print(f"     ⚠️  Nguyên nhân: Lớp chưa có start_week hoặc end_week")
            
            # Kiểm tra enrollments
            enrollments = db.query(Enrollment).filter(Enrollment.class_id == cls.id).all()
            print(f"   - Số sinh viên đã enroll: {len(enrollments)}")
            if enrollments:
                print(f"     Danh sách student IDs: {[e.student_id for e in enrollments]}")
            else:
                print(f"     ⚠️  CHƯA CÓ SINH VIÊN NÀO ĐƯỢC ENROLL!")
        
        # 2. Kiểm tra một student cụ thể
        print("\n\n2. KIỂM TRA TIMETABLE CỦA STUDENT:")
        print("-" * 60)
        students = db.query(Student).join(User).limit(5).all()
        
        if not students:
            print("❌ Không có student nào trong hệ thống!")
            return
        
        for student in students:
            print(f"\n👤 Student: {student.user.full_name} (ID: {student.user_id})")
            
            # Enrollments của student
            enrollments = db.query(Enrollment).filter(Enrollment.student_id == student.user_id).all()
            print(f"   - Số lớp đã enroll: {len(enrollments)}")
            
            if enrollments:
                for enr in enrollments:
                    cls = enr.class_
                    print(f"     📚 Lớp: {cls.code} (ID: {cls.id})")
                    
                    # Timetable của lớp này
                    timetables = db.query(Timetable).filter(Timetable.class_id == cls.id).all()
                    print(f"       - Timetable records: {len(timetables)}")
                    if timetables:
                        print(f"         ✅ Có {len(timetables)} buổi học")
                    else:
                        print(f"         ❌ KHÔNG CÓ TIMETABLE!")
            else:
                print(f"     ⚠️  Student chưa enroll vào lớp nào!")
            
            # Query giống như trong get_student_timetable
            from app.models.timetable import Timetable as TT
            timetables_result = db.query(TT).join(Class).join(Enrollment).filter(
                Enrollment.student_id == student.user_id,
                Enrollment.class_id == Class.id
            ).order_by(TT.date, TT.start_period).all()
            
            print(f"   - Kết quả từ get_student_timetable query: {len(timetables_result)} records")
            if timetables_result:
                print(f"     ✅ Sẽ hiển thị trên app mobile")
                for tt in timetables_result[:3]:  # Show first 3
                    print(f"       - {tt.date}: {tt.class_.course.name if tt.class_ and tt.class_.course else 'N/A'}")
            else:
                print(f"     ❌ SẼ KHÔNG HIỂN THỊ TRÊN APP MOBILE")
                if not enrollments:
                    print(f"       ⚠️  Nguyên nhân: Student chưa enroll vào lớp nào")
                else:
                    print(f"       ⚠️  Nguyên nhân: Các lớp đã enroll không có timetable")
        
        print("\n\n" + "=" * 60)
        print("KẾT LUẬN:")
        print("=" * 60)
        print("""
Để timetable hiển thị trên app mobile, cần đảm bảo:
1. ✅ Lớp học có semester code hợp lệ
2. ✅ Semester tồn tại và có start_date
3. ✅ Lớp học có day_of_week, start_week, end_week
4. ✅ Timetable đã được generate (có records trong bảng timetables)
5. ✅ Student đã được enroll vào lớp học

Nếu thiếu bất kỳ điều kiện nào ở trên, timetable sẽ không hiển thị!
        """)
        
    except Exception as e:
        print(f"❌ Lỗi: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    check_timetable_issue()
