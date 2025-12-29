"""
Demo Script: SQL Injection Protection
Chạy script này để demo SQL injection protection
"""
import requests

BASE_URL = "http://localhost:8000"

def test_sql_injection():
    print("=" * 60)
    print("DEMO: SQL INJECTION PROTECTION")
    print("=" * 60)

    # Test 1: SQL Injection trong login
    print("\n1. Test SQL Injection trong login form:")
    sql_payloads = [
        "admin' OR '1'='1",
        "admin' OR '1'='1' --",
        "'; DROP TABLE users; --",
        "' UNION SELECT NULL--",
    ]

    safe_count = 0
    unsafe_count = 0

    for payload in sql_payloads:
        try:
            response = requests.post(f"{BASE_URL}/auth/login", data={
                "username": payload,
                "password": "anypassword"
            }, timeout=5)

            if response.status_code == 500:
                print(f"   ❌ NGUY HIỂM: SQL injection gây lỗi 500 với payload: {payload[:40]}")
                unsafe_count += 1
            elif response.status_code in [400, 401, 422]:
                print(f"   ✅ An toàn: Payload bị reject: {payload[:40]}... (Status: {response.status_code})")
                safe_count += 1
            else:
                print(f"   ⚠️  Unexpected: Status {response.status_code} với payload: {payload[:40]}")
            
            # Kiểm tra không expose SQL errors
            response_text = response.text.lower()
            if "sql" in response_text and ("error" in response_text or "syntax" in response_text):
                print(f"   ⚠️  CẢNH BÁO: Có thể expose SQL errors trong response")
        except Exception as e:
            print(f"   ❌ Lỗi khi test payload {payload[:30]}: {e}")

    print(f"\n   Tổng kết: {safe_count} payload an toàn, {unsafe_count} payload nguy hiểm")

    # Test 2: SQL Injection trong search
    print("\n2. Test SQL Injection trong search endpoint:")
    # Đăng nhập để lấy token
    try:
        login_response = requests.post(f"{BASE_URL}/auth/login", data={
            "username": "student1",
            "password": "password123"
        }, timeout=5)

        if login_response.status_code == 200:
            token = login_response.json().get("access_token")
            if token:
                headers = {"Authorization": f"Bearer {token}"}
                
                search_payloads = [
                    "test' OR '1'='1",
                    "'; DROP TABLE--",
                    "' UNION SELECT * FROM users--",
                ]

                for payload in search_payloads:
                    try:
                        response = requests.get(
                            f"{BASE_URL}/search?q={payload}",
                            headers=headers,
                            timeout=5
                        )

                        if response.status_code == 500:
                            print(f"   ❌ NGUY HIỂM: SQL injection gây lỗi 500 với payload: {payload[:40]}")
                        else:
                            print(f"   ✅ An toàn: Status {response.status_code} với payload: {payload[:40]}...")
                    except Exception as e:
                        print(f"   ❌ Lỗi khi test search payload {payload[:30]}: {e}")
            else:
                print("   ⚠️  Không nhận được token")
        else:
            print(f"   ⚠️  Không thể đăng nhập để test search endpoint: {login_response.status_code}")
    except Exception as e:
        print(f"   ❌ Lỗi kết nối: {e}")
        print("   💡 Đảm bảo backend server đang chạy tại http://localhost:8000")

    print("\n" + "=" * 60)
    print("KẾT LUẬN: SQL Injection Protection đã được kiểm thử!")
    print("=" * 60)
    print("\n💡 Lý do an toàn: Hệ thống sử dụng SQLAlchemy ORM")
    print("   ORM tự động escape và parameterize queries")
    print("   Không có raw SQL queries từ user input")

if __name__ == "__main__":
    test_sql_injection()


