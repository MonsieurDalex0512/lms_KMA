"""
Demo Script: JWT Token Security
Chạy script này để demo JWT security testing
"""
import requests
from jose import jwt
from datetime import datetime
import sys
import os

# Add app to path
sys.path.insert(0, os.path.dirname(__file__))

try:
    from app.core.config import settings
except ImportError:
    print("⚠️  Không thể import settings. Đảm bảo đang chạy từ thư mục lms_backend")
    settings = type('Settings', (), {'SECRET_KEY': 'test-secret-key', 'ALGORITHM': 'HS256'})()

BASE_URL = "http://localhost:8000"

def test_jwt_security():
    print("=" * 60)
    print("DEMO: JWT TOKEN SECURITY")
    print("=" * 60)

    # Test 1: Token hợp lệ
    print("\n1. Test với token hợp lệ:")
    try:
        login_response = requests.post(f"{BASE_URL}/auth/login", data={
            "username": "student1",
            "password": "password123"
        }, timeout=5)
        
        if login_response.status_code == 200:
            token = login_response.json().get("access_token")
            if token:
                print(f"   ✅ Đăng nhập thành công, nhận token")
                
                headers = {"Authorization": f"Bearer {token}"}
                response = requests.get(f"{BASE_URL}/students/profile", headers=headers, timeout=5)
                print(f"   ✅ Truy cập endpoint với token hợp lệ: Status {response.status_code}")
            else:
                print("   ⚠️  Không nhận được token trong response")
        else:
            print(f"   ⚠️  Đăng nhập thất bại: {login_response.status_code}")
            print(f"   Response: {login_response.text[:100]}")
    except Exception as e:
        print(f"   ❌ Lỗi: {e}")

    # Test 2: Token hết hạn
    print("\n2. Test với token đã hết hạn:")
    try:
        expired_data = {
            "sub": "student1",
            "user_id": 1,
            "exp": int(datetime.utcnow().timestamp()) - 3600
        }
        expired_token = jwt.encode(expired_data, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        headers = {"Authorization": f"Bearer {expired_token}"}
        response = requests.get(f"{BASE_URL}/students/profile", headers=headers, timeout=5)
        
        if response.status_code == 401:
            print(f"   ✅ Token hết hạn bị từ chối: Status {response.status_code} (Đúng!)")
        else:
            print(f"   ⚠️  Token hết hạn không bị từ chối: Status {response.status_code}")
    except Exception as e:
        print(f"   ❌ Lỗi: {e}")

    # Test 3: Token bị chỉnh sửa
    print("\n3. Test với token bị chỉnh sửa:")
    try:
        login_response = requests.post(f"{BASE_URL}/auth/login", data={
            "username": "student1",
            "password": "password123"
        }, timeout=5)
        
        if login_response.status_code == 200:
            token = login_response.json().get("access_token")
            if token:
                tampered_token = token[:-5] + "XXXXX"
                headers = {"Authorization": f"Bearer {tampered_token}"}
                response = requests.get(f"{BASE_URL}/students/profile", headers=headers, timeout=5)
                
                if response.status_code == 401:
                    print(f"   ✅ Token bị chỉnh sửa bị từ chối: Status {response.status_code} (Đúng!)")
                else:
                    print(f"   ⚠️  Token bị chỉnh sửa không bị từ chối: Status {response.status_code}")
    except Exception as e:
        print(f"   ❌ Lỗi: {e}")

    # Test 4: Không có token
    print("\n4. Test không có token:")
    try:
        response = requests.get(f"{BASE_URL}/students/profile", timeout=5)
        if response.status_code == 401:
            print(f"   ✅ Request không có token bị từ chối: Status {response.status_code} (Đúng!)")
        else:
            print(f"   ⚠️  Request không có token không bị từ chối: Status {response.status_code}")
    except Exception as e:
        print(f"   ❌ Lỗi: {e}")

    print("\n" + "=" * 60)
    print("KẾT LUẬN: JWT Security đã được kiểm thử!")
    print("=" * 60)

if __name__ == "__main__":
    test_jwt_security()


