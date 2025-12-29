# BÁO CÁO BẢO MẬT CHUYÊN SÂU: ĐĂNG NHẬP OTP CHO TÀI KHOẢN TRƯỞNG KHOA
## PHẦN 4: CƠ CHẾ BẢO MẬT VÀ CÁC LỚP BẢO VỆ

## MỤC LỤC

1. [Tổng quan về các lớp bảo mật](#1-tổng-quan-về-các-lớp-bảo-mật)
2. [Lớp 1: Xác thực Username/Password](#2-lớp-1-xác-thực-usernamepassword)
3. [Lớp 2: Xác thực OTP (Two-Factor Authentication)](#3-lớp-2-xác-thực-otp-two-factor-authentication)
4. [Lớp 3: Bảo vệ OTP](#4-lớp-3-bảo-vệ-otp)
5. [Lớp 4: Bảo vệ JWT Token](#5-lớp-4-bảo-vệ-jwt-token)
6. [Lớp 5: Bảo vệ Email Communication](#6-lớp-5-bảo-vệ-email-communication)
7. [Lớp 6: Bảo vệ Session và State](#7-lớp-6-bảo-vệ-session-và-state)
8. [Tổng hợp các cơ chế bảo mật](#8-tổng-hợp-các-cơ-chế-bảo-mật)

---

## 1. TỔNG QUAN VỀ CÁC LỚP BẢO MẬT

### 1.1. Mô hình Defense in Depth (Bảo vệ nhiều lớp)

Hệ thống sử dụng **Defense in Depth** - bảo vệ nhiều lớp để đảm bảo an toàn:

```
┌─────────────────────────────────────┐
│  Lớp 6: Session & State Protection  │
├─────────────────────────────────────┤
│  Lớp 5: Email Communication Security│
├─────────────────────────────────────┤
│  Lớp 4: JWT Token Security          │
├─────────────────────────────────────┤
│  Lớp 3: OTP Protection              │
├─────────────────────────────────────┤
│  Lớp 2: OTP Authentication (2FA)     │
├─────────────────────────────────────┤
│  Lớp 1: Username/Password Auth      │
└─────────────────────────────────────┘
```

**Nguyên tắc**: Nếu một lớp bị phá vỡ, các lớp khác vẫn bảo vệ hệ thống.

### 1.2. Các mối đe dọa được bảo vệ

| Mối đe dọa | Lớp bảo vệ | Mô tả |
|------------|------------|-------|
| **Brute Force Attack** | Lớp 1, 3 | Giới hạn số lần thử |
| **Password Theft** | Lớp 2 | Cần OTP để đăng nhập |
| **OTP Interception** | Lớp 3, 5 | OTP hết hạn, email mã hóa |
| **Token Theft** | Lớp 4 | Token hết hạn, signature |
| **Session Hijacking** | Lớp 6 | Session timeout, secure storage |
| **Man-in-the-Middle** | Lớp 5 | TLS encryption |

---

## 2. LỚP 1: XÁC THỰC USERNAME/PASSWORD

### 2.1. Mật khẩu được hash bằng bcrypt

**File**: `lms_backend/app/auth/security.py`

```python
import bcrypt

def get_password_hash(password):
    """Hash mật khẩu bằng bcrypt"""
    if isinstance(password, str):
        password = password.encode('utf-8')
    return bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')
```

**Cơ chế bảo vệ**:

1. **Salt ngẫu nhiên**:
   - Mỗi mật khẩu có salt riêng
   - Ngăn chặn rainbow table attack

2. **Cost factor**:
   - bcrypt tự động điều chỉnh độ khó
   - Làm chậm brute-force attack

3. **Mật khẩu không bao giờ lưu dạng text**:
   - Database chỉ lưu hash
   - Ngay cả admin cũng không thể xem mật khẩu gốc

**Ví dụ**:
```python
# Mật khẩu gốc: "myPassword123"
# Hash trong database: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
# Không thể reverse từ hash về mật khẩu gốc
```

### 2.2. Xác thực mật khẩu an toàn

**File**: `lms_backend/app/auth/security.py`

```python
def verify_password(plain_password, hashed_password):
    """So sánh mật khẩu người dùng nhập với hash"""
    if isinstance(plain_password, str):
        plain_password = plain_password.encode('utf-8')
    if isinstance(hashed_password, str):
        hashed_password = hashed_password.encode('utf-8')
    return bcrypt.checkpw(plain_password, hashed_password)
```

**Cơ chế bảo vệ**:

1. **Timing-safe comparison**:
   - `bcrypt.checkpw()` so sánh an toàn về thời gian
   - Không leak thông tin qua timing attack

2. **Không trả về thông tin chi tiết**:
   ```python
   # ❌ KHÔNG LÀM:
   if not user:
       return "Username không tồn tại"
   if not verify_password(...):
       return "Mật khẩu sai"
   
   # ✅ ĐÚNG:
   if not user or not verify_password(...):
       return "Incorrect username or password"
   ```
   - Kẻ tấn công không biết username hay password sai

### 2.3. Bảo vệ chống Brute Force

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/login")
async def login_for_access_token(...):
    # Kiểm tra username/password
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
```

**Cơ chế bảo vệ**:

1. **HTTP Status 401**:
   - Thông báo lỗi chung, không tiết lộ chi tiết

2. **bcrypt làm chậm**:
   - Mỗi lần verify mất ~100ms
   - Làm chậm brute-force attack

**Cải thiện có thể thực hiện**:
```python
# Rate limiting (có thể thêm)
from slowapi import Limiter

limiter = Limiter(key_func=get_remote_address)

@router.post("/login")
@limiter.limit("5/minute")  # Tối đa 5 lần/phút
async def login_for_access_token(...):
    # ...
```

---

## 3. LỚP 2: XÁC THỰC OTP (TWO-FACTOR AUTHENTICATION)

### 3.1. Yêu cầu 2 yếu tố

**File**: `lms_backend/app/routers/auth.py`

```python
if user.role == UserRole.DEAN:
    # Yếu tố 1: Username/Password (đã xác thực)
    # Yếu tố 2: OTP qua email (sẽ gửi)
    otp = generate_otp()
    store_otp(user.id, otp)
    send_otp_email(email, otp, full_name)
    return {"requires_otp": True, ...}
```

**Cơ chế bảo vệ**:

1. **Yếu tố 1 - Something you know**:
   - Username và Password
   - Chỉ chủ tài khoản biết

2. **Yếu tố 2 - Something you have**:
   - Mã OTP gửi qua email
   - Chỉ chủ tài khoản có quyền truy cập email

3. **Kẻ tấn công cần cả 2 yếu tố**:
   - Nếu chỉ có password → Không thể đăng nhập
   - Nếu chỉ có OTP → Không thể đăng nhập
   - Phải có CẢ HAI → Mới đăng nhập được

### 3.2. Chỉ áp dụng cho Trưởng khoa

**File**: `lms_backend/app/routers/auth.py`

```python
if user.role == UserRole.DEAN:
    # Xử lý OTP
else:
    # Đăng nhập bình thường
    access_token = create_access_token(...)
    return {"access_token": access_token, ...}
```

**Lý do**:
- Trưởng khoa có quyền cao nhất
- Cần bảo vệ tối đa
- Giảng viên và sinh viên có quyền hạn chế hơn

### 3.3. Luồng xác thực 2 yếu tố

```
Bước 1: Người dùng nhập username/password
    ↓
Bước 2: Backend xác thực username/password ✅
    ↓
Bước 3: Backend phát hiện là DEAN → Gửi OTP
    ↓
Bước 4: Người dùng nhận email OTP
    ↓
Bước 5: Người dùng nhập OTP
    ↓
Bước 6: Backend xác thực OTP ✅
    ↓
Bước 7: Đăng nhập thành công
```

**Bảo vệ**: Nếu thiếu bất kỳ bước nào → Đăng nhập thất bại

---

## 4. LỚP 3: BẢO VỆ OTP

### 4.1. OTP có thời gian hết hạn

**File**: `lms_backend/app/services/otp_service.py`

```python
def store_otp(user_id: int, otp: str) -> None:
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }
```

**Cơ chế bảo vệ**:

1. **Thời gian hết hạn ngắn**:
   - Mặc định: 10 phút
   - Giảm thời gian window cho kẻ tấn công

2. **Tự động xóa khi hết hạn**:
   ```python
   if datetime.utcnow() > stored["expires_at"]:
       del otp_storage[user_key]
       return (False, 0)
   ```

3. **Không thể sử dụng OTP cũ**:
   - OTP hết hạn → Không thể dùng
   - Phải yêu cầu OTP mới

**Ví dụ**:
```
10:00 - OTP được tạo: "123456" (hết hạn lúc 10:10)
10:05 - Người dùng nhập OTP → ✅ Thành công
10:11 - Kẻ tấn công có OTP cũ → ❌ Đã hết hạn
```

### 4.2. Giới hạn số lần thử

**File**: `lms_backend/app/services/otp_service.py`

```python
def verify_otp(user_id: int, otp: str) -> tuple[bool, int]:
    max_attempts = 10
    
    # Kiểm tra số lần thử
    if stored["attempts"] >= max_attempts:
        del otp_storage[user_key]
        return (False, 0)
    
    # Tăng số lần thử
    stored["attempts"] += 1
    remaining = max_attempts - stored["attempts"]
    
    # So sánh OTP
    if stored["otp"] == otp:
        return (True, remaining)
    else:
        return (False, remaining)
```

**Cơ chế bảo vệ**:

1. **Tối đa 10 lần thử**:
   - Sau 10 lần sai → OTP bị vô hiệu hóa
   - Phải đăng nhập lại từ đầu

2. **Thông báo số lần thử còn lại**:
   ```python
   detail=f"Mã OTP không đúng. Còn {remaining} lần thử."
   ```
   - Người dùng biết còn bao nhiêu cơ hội

3. **Xóa OTP sau khi hết lần thử**:
   - Ngăn chặn tiếp tục thử
   - Bắt buộc phải yêu cầu OTP mới

**Ví dụ**:
```
Lần 1: Nhập "111111" → ❌ Sai, còn 9 lần thử
Lần 2: Nhập "222222" → ❌ Sai, còn 8 lần thử
...
Lần 10: Nhập "999999" → ❌ Sai, hết lần thử
→ OTP bị vô hiệu hóa, phải đăng nhập lại
```

### 4.3. OTP chỉ dùng được 1 lần

**File**: `lms_backend/app/services/otp_service.py`

```python
if stored["otp"] == otp:
    # OTP đúng, xóa ngay lập tức
    del otp_storage[user_key]
    return (True, remaining)
```

**Cơ chế bảo vệ**:

1. **One-time use**:
   - Sau khi xác thực thành công → Xóa OTP
   - Không thể dùng lại OTP đã dùng

2. **Ngăn chặn replay attack**:
   - Kẻ tấn công không thể dùng lại OTP đã bị đánh cắp
   - Mỗi OTP chỉ dùng được 1 lần

**Ví dụ**:
```
10:00 - OTP được tạo: "123456"
10:05 - Người dùng nhập "123456" → ✅ Thành công, OTP bị xóa
10:06 - Kẻ tấn công có OTP "123456" → ❌ OTP không còn tồn tại
```

### 4.4. OTP ngẫu nhiên và không đoán được

**File**: `lms_backend/app/services/otp_service.py`

```python
def generate_otp() -> str:
    return ''.join(random.choices(string.digits, k=settings.OTP_LENGTH))
```

**Cơ chế bảo vệ**:

1. **Ngẫu nhiên thực sự**:
   - Sử dụng `random.choices()` với seed ngẫu nhiên
   - Không thể đoán được OTP tiếp theo

2. **Độ dài đủ**:
   - 6 chữ số = 1,000,000 khả năng
   - Xác suất đoán đúng: 1/1,000,000

3. **Không có pattern**:
   - Mỗi OTP độc lập
   - Không có mối liên hệ giữa các OTP

**Ví dụ**:
```
OTP 1: "847392"
OTP 2: "123456"  ← Vẫn có thể xảy ra (ngẫu nhiên)
OTP 3: "999999"  ← Vẫn có thể xảy ra (ngẫu nhiên)
```

### 4.5. Lưu trữ OTP an toàn

**File**: `lms_backend/app/services/otp_service.py`

```python
# Lưu trữ trong bộ nhớ (RAM)
otp_storage: Dict[str, dict] = {}
```

**Cơ chế bảo vệ**:

1. **Không lưu trong database**:
   - OTP chỉ tồn tại trong RAM
   - Không thể truy vấn từ database

2. **Tự động xóa khi server restart**:
   - OTP cũ không còn hiệu lực
   - Bắt buộc phải yêu cầu OTP mới

**Lưu ý**: Trong production, nên dùng Redis:
```python
# Cải thiện (có thể thêm)
import redis

redis_client = redis.Redis(host='localhost', port=6379, db=0)

def store_otp(user_id: int, otp: str) -> None:
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    redis_client.setex(
        f"otp:{user_id}",
        int((expires_at - datetime.utcnow()).total_seconds()),
        json.dumps({"otp": otp, "attempts": 0})
    )
```

---

## 5. LỚP 4: BẢO VỆ JWT TOKEN

### 5.1. JWT Token có thời gian hết hạn

**File**: `lms_backend/app/auth/security.py`

```python
def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt
```

**Cơ chế bảo vệ**:

1. **Thời gian hết hạn ngắn**:
   - Mặc định: 30 phút
   - Giảm thời gian window nếu token bị đánh cắp

2. **Tự động kiểm tra khi decode**:
   ```python
   payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
   # Nếu hết hạn → Ném JWTError
   ```

3. **Không thể gia hạn tự động**:
   - Token hết hạn → Phải đăng nhập lại
   - Đảm bảo người dùng vẫn hoạt động

**Ví dụ**:
```
10:00 - Token được tạo (hết hạn lúc 10:30)
10:15 - Sử dụng token → ✅ Hợp lệ
10:35 - Sử dụng token → ❌ Đã hết hạn
```

### 5.2. JWT Token được ký bằng Secret Key

**File**: `lms_backend/app/auth/security.py`

```python
encoded_jwt = jwt.encode(
    to_encode, 
    settings.SECRET_KEY,  # Secret key bí mật
    algorithm=settings.ALGORITHM  # HS256
)
```

**Cơ chế bảo vệ**:

1. **Signature**:
   - Token được ký bằng secret key
   - Không thể giả mạo nếu không có secret key

2. **Verification**:
   ```python
   payload = jwt.decode(
       token, 
       settings.SECRET_KEY,  # Phải khớp với key khi tạo
       algorithms=[settings.ALGORITHM]
   )
   ```
   - Nếu signature không khớp → Token không hợp lệ

3. **Secret Key bảo mật**:
   - Chỉ server biết secret key
   - Không được commit vào git
   - Lưu trong environment variables

**Cấu trúc JWT**:
```
header.payload.signature

header: {"alg": "HS256", "typ": "JWT"}
payload: {"sub": "dean001", "user_id": 1, "exp": 1705324000}
signature: HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret_key)
```

### 5.3. JWT Token chứa thông tin tối thiểu

**File**: `lms_backend/app/routers/auth.py`

```python
access_token = create_access_token(
    data={"sub": user.username, "user_id": user.id}, 
    expires_delta=access_token_expires
)
```

**Cơ chế bảo vệ**:

1. **Không lưu mật khẩu**:
   - Token chỉ chứa username và user_id
   - Không có thông tin nhạy cảm

2. **Không lưu quyền hạn**:
   - Quyền hạn được lấy từ database
   - Đảm bảo quyền hạn luôn cập nhật

3. **Minimal data**:
   - Chỉ lưu thông tin cần thiết
   - Giảm thiểu rủi ro nếu token bị đánh cắp

### 5.4. Tự động thêm token vào request

**File**: `lms_frontend/src/services/api.ts`

```typescript
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    }
);
```

**Cơ chế bảo vệ**:

1. **Tự động thêm vào mọi request**:
   - Không cần thêm thủ công
   - Giảm lỗi quên thêm token

2. **Bearer token**:
   - Format chuẩn OAuth2
   - Dễ dàng xử lý ở backend

### 5.5. Xử lý token hết hạn

**File**: `lms_frontend/src/services/api.ts`

```typescript
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            localStorage.removeItem('token');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);
```

**Cơ chế bảo vệ**:

1. **Tự động logout khi token hết hạn**:
   - Nhận 401 → Xóa token → Chuyển đến trang đăng nhập
   - Ngăn chặn sử dụng token không hợp lệ

2. **Bảo vệ khỏi token đã bị thu hồi**:
   - Nếu token bị thu hồi ở server → 401
   - Client tự động logout

---

## 6. LỚP 5: BẢO VỆ EMAIL COMMUNICATION

### 6.1. Email được mã hóa bằng TLS

**File**: `lms_backend/app/services/otp_service.py`

```python
with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
    server.starttls()  # Bật mã hóa TLS
    server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
    server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
```

**Cơ chế bảo vệ**:

1. **TLS Encryption**:
   - `starttls()`: Bật mã hóa TLS
   - Email được mã hóa khi truyền qua mạng
   - Ngăn chặn man-in-the-middle attack

2. **Port 587**:
   - Port chuẩn cho SMTP với TLS
   - An toàn hơn port 25 (không mã hóa)

3. **Certificate validation**:
   - TLS tự động validate certificate
   - Đảm bảo kết nối đến đúng server

**Luồng mã hóa**:
```
Backend → [TLS Encrypted] → SMTP Server → [TLS Encrypted] → Email Server → Email Client
```

### 6.2. Email không chứa thông tin nhạy cảm khác

**File**: `lms_backend/app/services/otp_service.py`

```python
html = f"""
    <p>Xin chào <strong>{full_name}</strong>,</p>
    <p>Bạn đang đăng nhập vào hệ thống LMS với vai trò Trưởng Khoa.</p>
    <div class="otp-code">{otp}</div>
    <p>⏱️ Mã này có hiệu lực trong <strong>{settings.OTP_EXPIRE_MINUTES} phút</strong>.</p>
"""
```

**Cơ chế bảo vệ**:

1. **Chỉ chứa OTP**:
   - Email không chứa username, password
   - Chỉ có OTP và thông tin cần thiết

2. **Cảnh báo bảo mật**:
   ```html
   <p class="warning">
       ⚠️ Không chia sẻ mã này với bất kỳ ai.
   </p>
   ```
   - Nhắc nhở người dùng không chia sẻ OTP

### 6.3. Email hint (ẩn một phần email)

**File**: `lms_backend/app/routers/auth.py`

```python
email_parts = email.split('@')
masked_email = email_parts[0][:3] + '***@' + email_parts[1] if len(email_parts) == 2 else '***'

return {
    "requires_otp": True,
    "email_hint": masked_email  # Ví dụ: "dea***@gmail.com"
}
```

**Cơ chế bảo vệ**:

1. **Bảo vệ quyền riêng tư**:
   - Không hiển thị toàn bộ email
   - Chỉ hiển thị 3 ký tự đầu

2. **Xác nhận đúng email**:
   - Người dùng biết email nào sẽ nhận OTP
   - Tránh nhầm lẫn

**Ví dụ**:
```
Email thực: "dean001@gmail.com"
Email hint: "dea***@gmail.com"
```

---

## 7. LỚP 6: BẢO VỆ SESSION VÀ STATE

### 7.1. Pending logins có thời gian sống ngắn

**File**: `lms_backend/app/routers/auth.py`

```python
pending_dean_logins = {}  # Lưu trong RAM

# Khi đăng nhập
pending_dean_logins[user.username] = {
    "user_id": user.id,
    "username": user.username,
    "role": user.role.value
}

# Khi xác thực OTP thành công
del pending_dean_logins[username]
```

**Cơ chế bảo vệ**:

1. **Tự động xóa sau khi xác thực**:
   - Sau khi OTP đúng → Xóa pending login
   - Không thể dùng lại phiên đăng nhập

2. **Xóa khi hết lần thử**:
   ```python
   if remaining <= 0:
       del pending_dean_logins[username]
   ```
   - Sau 10 lần thử sai → Xóa phiên
   - Bắt buộc đăng nhập lại từ đầu

3. **Không tồn tại vĩnh viễn**:
   - Lưu trong RAM → Mất khi server restart
   - Không thể truy vấn từ bên ngoài

### 7.2. SessionStorage cho thông tin tạm thời

**File**: `lms_frontend/src/pages/OtpVerify.tsx`

```typescript
// Lưu vào sessionStorage
sessionStorage.setItem('otp_username', state.username);
sessionStorage.setItem('otp_emailHint', state.emailHint || '');

// Xóa sau khi xác thực thành công
sessionStorage.removeItem('otp_username');
sessionStorage.removeItem('otp_emailHint');
```

**Cơ chế bảo vệ**:

1. **SessionStorage vs LocalStorage**:
   - `sessionStorage`: Mất khi đóng tab
   - `localStorage`: Giữ lại vĩnh viễn
   - Dùng sessionStorage cho dữ liệu tạm thời

2. **Tự động xóa**:
   - Sau khi xác thực thành công → Xóa
   - Không để lại dấu vết

3. **Không lưu OTP**:
   - Chỉ lưu username và email hint
   - Không lưu OTP trong storage

### 7.3. Token lưu trong LocalStorage

**File**: `lms_frontend/src/context/AuthContext.tsx`

```typescript
const login = (newToken: string, newUser: any) => {
    localStorage.setItem('token', newToken);
    localStorage.setItem('user', JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
};
```

**Cơ chế bảo vệ**:

1. **Token có thời gian hết hạn**:
   - Token tự động hết hạn sau 30 phút
   - Giảm rủi ro nếu bị đánh cắp

2. **Xóa khi logout**:
   ```typescript
   const logout = () => {
       localStorage.removeItem('token');
       localStorage.removeItem('user');
   };
   ```

3. **Lưu ý**: 
   - LocalStorage có thể bị XSS attack
   - Nên cân nhắc dùng httpOnly cookie (cần backend hỗ trợ)

**Cải thiện có thể thực hiện**:
```typescript
// Dùng httpOnly cookie (cần backend hỗ trợ)
// Backend set cookie với httpOnly flag
// Frontend không cần lưu token
```

---

## 8. TỔNG HỢP CÁC CƠ CHẾ BẢO MẬT

### 8.1. Bảng tổng hợp

| Lớp | Cơ chế | Mục đích | Cách hoạt động |
|-----|--------|----------|----------------|
| **1** | bcrypt hash | Bảo vệ mật khẩu | Hash mật khẩu, không lưu dạng text |
| **2** | 2FA với OTP | Xác thực 2 yếu tố | Yêu cầu cả password và OTP |
| **3** | OTP expiration | Giới hạn thời gian | OTP hết hạn sau 10 phút |
| **3** | OTP attempts limit | Chống brute force | Tối đa 10 lần thử |
| **3** | One-time use | Chống replay | OTP chỉ dùng được 1 lần |
| **4** | JWT expiration | Giới hạn thời gian | Token hết hạn sau 30 phút |
| **4** | JWT signature | Chống giả mạo | Token được ký bằng secret key |
| **5** | TLS encryption | Mã hóa email | Email được mã hóa khi truyền |
| **6** | Session cleanup | Xóa dữ liệu tạm | Tự động xóa sau khi dùng |

### 8.2. Điểm mạnh

1. ✅ **Nhiều lớp bảo vệ**: Nếu một lớp bị phá vỡ, các lớp khác vẫn bảo vệ
2. ✅ **2FA**: Yêu cầu cả password và OTP
3. ✅ **Time-limited**: OTP và token đều có thời gian hết hạn
4. ✅ **Rate limiting**: Giới hạn số lần thử
5. ✅ **Encryption**: Email được mã hóa bằng TLS

### 8.3. Điểm cần cải thiện

1. ⚠️ **OTP storage**: Nên dùng Redis thay vì memory
2. ⚠️ **Rate limiting**: Chưa có rate limiting cho login endpoint
3. ⚠️ **Token storage**: Nên cân nhắc dùng httpOnly cookie
4. ⚠️ **Audit logging**: Chưa có log cho các lần đăng nhập
5. ⚠️ **IP whitelist**: Có thể thêm whitelist IP cho trưởng khoa

---

## TÓM TẮT PHẦN 4

Trong phần này, chúng ta đã tìm hiểu **CƠ CHẾ BẢO MẬT VÀ CÁC LỚP BẢO VỆ**:

1. ✅ **Lớp 1**: Xác thực username/password với bcrypt
2. ✅ **Lớp 2**: Xác thực OTP (2FA)
3. ✅ **Lớp 3**: Bảo vệ OTP (expiration, attempts limit, one-time use)
4. ✅ **Lớp 4**: Bảo vệ JWT token (expiration, signature)
5. ✅ **Lớp 5**: Bảo vệ email communication (TLS encryption)
6. ✅ **Lớp 6**: Bảo vệ session và state (cleanup, storage)

**Tiếp theo**: Phần 5 sẽ giải thích **RỦI RO VÀ CÁCH KHẮC PHỤC**.

---

**📄 Xem tiếp**: `BAO_CAO_BAO_MAT_OTP_TRUONG_KHOA_PHAN_5_RUI_RO_VA_KHAC_PHUC.md`




