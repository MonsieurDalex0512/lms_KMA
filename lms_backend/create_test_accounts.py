"""
Script tạo test accounts cho security testing
Chạy script này để tạo các tài khoản test cần thiết
"""
import sys
import os

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import User, Student, Lecturer
from app.auth.security import get_password_hash
from app.models.enums import UserRole

def create_test_accounts():
    """Tạo các test accounts"""
    db: Session = SessionLocal()
    
    try:
        print("=" * 70)
        print(" " * 20 + "TẠO TEST ACCOUNTS")
        print("=" * 70)
        
        # Test accounts data
        test_accounts = [
            {
                "username": "student1",
                "email": "student1@test.com",
                "password": "password123",
                "full_name": "Sinh Viên Test 1",
                "role": UserRole.STUDENT,
                "student_code": "SV001"
            },
            {
                "username": "lecturer1",
                "email": "lecturer1@test.com",
                "password": "password123",
                "full_name": "Giảng Viên Test 1",
                "role": UserRole.LECTURER,
                "lecturer_code": "GV001"
            },
            {
                "username": "dean1",
                "email": "dean1@test.com",
                "password": "password123",
                "full_name": "Trưởng Khoa Test 1",
                "role": UserRole.DEAN
            },
        ]
        
        created_count = 0
        existing_count = 0
        
        for account_data in test_accounts:
            username = account_data["username"]
            
            # Kiểm tra user đã tồn tại chưa
            existing_user = db.query(User).filter(User.username == username).first()
            
            if existing_user:
                print(f"⚠️  Tài khoản '{username}' đã tồn tại, bỏ qua...")
                existing_count += 1
                continue
            
            # Tạo user
            hashed_password = get_password_hash(account_data["password"])
            user = User(
                username=username,
                email=account_data["email"],
                hashed_password=hashed_password,
                full_name=account_data["full_name"],
                role=account_data["role"],
                is_active=True
            )
            db.add(user)
            db.flush()  # Để lấy user.id
            
            # Tạo Student hoặc Lecturer nếu cần
            if account_data["role"] == UserRole.STUDENT:
                student = Student(
                    user_id=user.id,
                    student_code=account_data.get("student_code", f"SV{user.id:03d}")
                )
                db.add(student)
            elif account_data["role"] == UserRole.LECTURER:
                lecturer = Lecturer(
                    user_id=user.id,
                    lecturer_code=account_data.get("lecturer_code", f"GV{user.id:03d}")
                )
                db.add(lecturer)
            
            db.commit()
            print(f"✅ Đã tạo tài khoản: {username} ({account_data['role'].value})")
            created_count += 1
        
        print("\n" + "=" * 70)
        print(f"📊 Tổng kết:")
        print(f"   ✅ Đã tạo: {created_count} tài khoản")
        print(f"   ⚠️  Đã tồn tại: {existing_count} tài khoản")
        print("=" * 70)
        
        # Hiển thị thông tin đăng nhập
        print("\n📋 THÔNG TIN ĐĂNG NHẬP:")
        print("-" * 70)
        for account in test_accounts:
            print(f"   Username: {account['username']}")
            print(f"   Password: {account['password']}")
            print(f"   Role: {account['role'].value}")
            print(f"   Email: {account['email']}")
            print()
        
        print("=" * 70)
        print("✅ Hoàn tất!")
        print("=" * 70)
        
    except Exception as e:
        db.rollback()
        print(f"\n❌ Lỗi khi tạo tài khoản: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    create_test_accounts()

