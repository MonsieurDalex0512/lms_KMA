# BÁO CÁO KỸ THUẬT: PASSWORD HASHING VỚI BCRYPT

## MỤC LỤC

1. [Tổng quan](#1-tổng-quan)
2. [Khái niệm cơ bản](#2-khái-niệm-cơ-bản)
3. [Nguyên lý hoạt động của bcrypt](#3-nguyên-lý-hoạt-động-của-bcrypt)
4. [Triển khai trong hệ thống](#4-triển-khai-trong-hệ-thống)
5. [Bảo mật và ưu điểm](#5-bảo-mật-và-ưu-điểm)

---

## 1. TỔNG QUAN

### 1.1. Vấn đề cần giải quyết

Khi lưu trữ mật khẩu người dùng trong hệ thống, **KHÔNG BAO GIỜ** được lưu mật khẩu dạng text (plaintext). Nếu database bị hack, kẻ tấn công sẽ có ngay toàn bộ mật khẩu của người dùng.

**Giải pháp**: Sử dụng **hashing** - một chiều để chuyển đổi mật khẩu thành một chuỗi không thể đảo ngược.

### 1.2. bcrypt là gì?

**bcrypt** là một thuật toán hash mật khẩu được thiết kế đặc biệt để:
- Hash mật khẩu một chiều (không thể reverse)
- Tự động thêm salt (muối) để chống rainbow table attack
- Có thể điều chỉnh độ khó (cost factor) để làm chậm brute-force attack
- Được sử dụng rộng rãi và được coi là an toàn

---

## 2. KHÁI NIỆM CƠ BẢN

### 2.1. Hash Function (Hàm băm)

**Hash function** là hàm một chiều:
- Input: Mật khẩu gốc (ví dụ: "myPassword123")
- Output: Chuỗi hash (ví dụ: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5")
- **Đặc điểm**: Không thể reverse từ hash về mật khẩu gốc

```
"myPassword123" → [Hash Function] → "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
```

### 2.2. Salt (Muối)

**Salt** là một chuỗi ngẫu nhiên được thêm vào mật khẩu trước khi hash:

- **Mục đích**: Ngăn chặn rainbow table attack
- **Đặc điểm**: Mỗi mật khẩu có salt riêng, ngẫu nhiên
- **Lưu trữ**: Salt được lưu kèm trong hash string (không cần lưu riêng)

**Ví dụ**:
```
Mật khẩu: "password123"
Salt 1: "abc123" → Hash 1: "$2b$12$abc123...xyz"
Salt 2: "def456" → Hash 2: "$2b$12$def456...uvw"
```

Cùng một mật khẩu, nhưng hash khác nhau do salt khác nhau.

### 2.3. Cost Factor (Hệ số chi phí)

**Cost factor** (hay rounds) xác định số lần thuật toán được thực hiện:
- **Mục đích**: Làm chậm quá trình hash để chống brute-force
- **Giá trị**: Thường từ 10-14 (2^10 đến 2^14 rounds)
- **Trade-off**: Cost cao hơn = an toàn hơn nhưng chậm hơn

**Ví dụ**:
- Cost = 10: ~100ms để hash
- Cost = 12: ~400ms để hash (mặc định của bcrypt)
- Cost = 14: ~1.6s để hash

---

## 3. NGUYÊN LÝ HOẠT ĐỘNG CỦA BCRYPT

### 3.1. Quá trình Hash (Khi tạo/đổi mật khẩu)

```
1. Người dùng nhập mật khẩu: "myPassword123"
2. Tạo salt ngẫu nhiên (bcrypt.gensalt())
3. Kết hợp password + salt
4. Thực hiện hash với cost factor (mặc định 12 rounds)
5. Trả về hash string: "$2b$12$salt...hash"
```

**Cấu trúc hash string**:
```
$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5
│  │  │  │
│  │  │  └─ Hash (31 ký tự)
│  │  └──── Salt (22 ký tự)
│  └─────── Cost factor (12 = 2^12 rounds)
└────────── Algorithm version (2b)
```

### 3.2. Quá trình Verify (Khi đăng nhập)

```
1. Người dùng nhập mật khẩu: "myPassword123"
2. Lấy hash từ database: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
3. bcrypt tự động extract salt từ hash string
4. Hash mật khẩu người dùng với salt đó
5. So sánh kết quả với hash trong database
6. Trả về True/False
```

**Lưu ý**: bcrypt tự động xử lý salt, không cần lưu riêng.

### 3.3. Tại sao cùng mật khẩu nhưng hash khác nhau?

Vì mỗi lần hash, bcrypt tạo salt ngẫu nhiên mới:

```python
# Lần 1
hash1 = bcrypt.hashpw("password123".encode(), bcrypt.gensalt())
# Kết quả: "$2b$12$abc123...xyz"

# Lần 2 (cùng mật khẩu)
hash2 = bcrypt.hashpw("password123".encode(), bcrypt.gensalt())
# Kết quả: "$2b$12$def456...uvw" (KHÁC hash1)

# Nhưng verify vẫn đúng
bcrypt.checkpw("password123".encode(), hash1)  # True
bcrypt.checkpw("password123".encode(), hash2)  # True
```

---

## 4. TRIỂN KHAI TRONG HỆ THỐNG

### 4.1. File triển khai

**File**: `lms_backend/app/auth/security.py`

```python
import bcrypt

def get_password_hash(password):
    """Hash mật khẩu bằng bcrypt"""
    if isinstance(password, str):
        password = password.encode('utf-8')
    return bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')

def verify_password(plain_password, hashed_password):
    """So sánh mật khẩu người dùng với hash trong database"""
    if isinstance(plain_password, str):
        plain_password = plain_password.encode('utf-8')
    if isinstance(hashed_password, str):
        hashed_password = hashed_password.encode('utf-8')
    return bcrypt.checkpw(plain_password, hashed_password)
```

### 4.2. Sử dụng khi đăng ký người dùng

**File**: `lms_backend/app/crud/user.py`

```python
from app.auth.security import get_password_hash

def create_user(db: Session, user: UserCreate):
    # Hash mật khẩu trước khi lưu vào database
    hashed_password = get_password_hash(user.password)
    
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password,  # Lưu hash, KHÔNG lưu password gốc
        role=user.role,
        ...
    )
    db.add(db_user)
    db.commit()
    return db_user
```

**Luồng hoạt động**:
```
1. Người dùng đăng ký với password: "myPassword123"
2. create_user() gọi get_password_hash("myPassword123")
3. get_password_hash() trả về: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
4. Lưu hash vào database (KHÔNG lưu "myPassword123")
```

### 4.3. Sử dụng khi đăng nhập

**File**: `lms_backend/app/routers/auth.py`

```python
from app.auth.security import verify_password

@router.post("/login")
async def login_for_access_token(form_data: OAuth2PasswordRequestForm, ...):
    user = get_user_by_username(db, username=form_data.username)
    
    # So sánh mật khẩu người dùng nhập với hash trong database
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    
    # Nếu đúng, tạo JWT token
    access_token = create_access_token(...)
    return {"access_token": access_token, ...}
```

**Luồng hoạt động**:
```
1. Người dùng nhập: username="john", password="myPassword123"
2. Lấy user từ database → user.hashed_password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
3. verify_password("myPassword123", "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5")
4. bcrypt.checkpw() so sánh → True
5. Tạo JWT token và trả về
```

### 4.4. Sử dụng khi đổi mật khẩu

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/change-password")
def change_password(
    old_password: str = Form(...),
    new_password: str = Form(...),
    current_user: User = Depends(get_current_active_user),
    ...
):
    # Xác thực mật khẩu cũ
    if not verify_password(old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Old password is incorrect")
    
    # Hash mật khẩu mới và lưu
    current_user.hashed_password = get_password_hash(new_password)
    db.commit()
    
    return {"message": "Password changed successfully"}
```

**Luồng hoạt động**:
```
1. Người dùng nhập: old_password="old123", new_password="new456"
2. verify_password("old123", current_user.hashed_password) → True
3. get_password_hash("new456") → "$2b$12$newHash..."
4. Cập nhật current_user.hashed_password = "$2b$12$newHash..."
5. Lưu vào database
```

### 4.5. Lưu trữ trong Database

**Model**: `lms_backend/app/models/user.py`

```python
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)  # Lưu hash, KHÔNG lưu password gốc
    ...
```

**Lưu ý quan trọng**:
- ✅ Database chỉ lưu `hashed_password` (dạng hash)
- ❌ KHÔNG BAO GIỜ lưu password gốc
- ✅ Ngay cả admin cũng không thể xem mật khẩu gốc

---

## 5. BẢO MẬT VÀ ƯU ĐIỂM

### 5.1. Các mối đe dọa được bảo vệ

| Mối đe dọa | Cách bcrypt bảo vệ |
|------------|-------------------|
| **Database leak** | Mật khẩu đã hash, không thể reverse |
| **Rainbow table attack** | Salt ngẫu nhiên cho mỗi mật khẩu |
| **Brute-force attack** | Cost factor làm chậm quá trình hash |
| **Password reuse** | Cùng mật khẩu nhưng hash khác nhau (do salt) |

### 5.2. Ưu điểm của bcrypt

1. **Tự động quản lý salt**: Không cần lưu salt riêng, salt được embed trong hash string
2. **Điều chỉnh được độ khó**: Có thể tăng cost factor khi phần cứng mạnh hơn
3. **Được kiểm chứng**: Được sử dụng rộng rãi, đã được kiểm tra kỹ lưỡng
4. **Chống timing attack**: `bcrypt.checkpw()` so sánh an toàn về thời gian

### 5.3. So sánh với các phương pháp khác

| Phương pháp | Ưu điểm | Nhược điểm |
|------------|---------|------------|
| **MD5/SHA1** | Nhanh | ❌ Không an toàn, dễ bị crack |
| **SHA256** | Nhanh | ❌ Không có salt, dễ rainbow table |
| **bcrypt** | ✅ An toàn, có salt, có cost factor | Hơi chậm (nhưng đây là ưu điểm) |
| **Argon2** | ✅ Rất an toàn, mới nhất | Phức tạp hơn, ít được dùng hơn |

**Kết luận**: bcrypt là lựa chọn tốt, cân bằng giữa an toàn và dễ sử dụng.

### 5.4. Best Practices trong hệ thống

✅ **Đã triển khai đúng**:
- Hash mật khẩu trước khi lưu database
- Sử dụng bcrypt với salt tự động
- Verify mật khẩu an toàn khi đăng nhập
- Không bao giờ lưu password dạng text

⚠️ **Có thể cải thiện** (tùy chọn):
- Thêm password strength validation (độ dài, ký tự đặc biệt)
- Thêm rate limiting cho đăng nhập (chống brute-force)
- Cân nhắc tăng cost factor nếu server đủ mạnh

---

## KẾT LUẬN

bcrypt là một giải pháp hash mật khẩu an toàn và đáng tin cậy. Hệ thống đã triển khai đúng cách:

1. ✅ Hash mật khẩu khi đăng ký
2. ✅ Verify mật khẩu khi đăng nhập
3. ✅ Hash mật khẩu mới khi đổi mật khẩu
4. ✅ Không bao giờ lưu password dạng text

Với cách triển khai hiện tại, hệ thống đã đảm bảo mật khẩu người dùng được bảo vệ an toàn, ngay cả khi database bị rò rỉ.

---

**Tài liệu tham khảo**:
- bcrypt Python library: https://github.com/pyca/bcrypt
- OWASP Password Storage Cheat Sheet
- File triển khai: `lms_backend/app/auth/security.py`

