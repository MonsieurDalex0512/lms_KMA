# BÁO CÁO: HỆ THỐNG OTP CHO TÀI KHOẢN TRƯỞNG KHOA

## 1. KHÁI NIỆM

### 1.1. OTP là gì?

**OTP (One-Time Password)** là mật khẩu một lần - một chuỗi số ngẫu nhiên chỉ sử dụng được **một lần duy nhất** và có **thời gian hết hạn ngắn** (thường 5-10 phút).

**Đặc điểm:**
- Mã ngẫu nhiên 6 chữ số (ví dụ: `847392`)
- Chỉ dùng được 1 lần, sau khi xác thực thành công sẽ bị xóa
- Có thời gian hết hạn (10 phút trong hệ thống này)
- Được gửi qua email hoặc SMS

### 1.2. Xác thực hai yếu tố (2FA)

**2FA (Two-Factor Authentication)** yêu cầu **2 yếu tố khác nhau** để xác thực:

1. **Yếu tố 1 - Cái bạn biết**: Username + Password
2. **Yếu tố 2 - Cái bạn có**: Mã OTP qua email

**Tại sao an toàn hơn?**
- Ngay cả khi mật khẩu bị lộ, kẻ tấn công vẫn không thể đăng nhập nếu không có OTP
- OTP chỉ có hiệu lực trong thời gian ngắn
- OTP chỉ dùng được một lần

### 1.3. Tại sao chỉ áp dụng cho Trưởng Khoa?

Trưởng Khoa có quyền cao nhất trong hệ thống:
- Tạo/xóa/sửa tất cả tài khoản (giảng viên, sinh viên)
- Xem và chỉnh sửa điểm số của tất cả sinh viên
- Quản lý toàn bộ dữ liệu hệ thống

**Rủi ro nếu bị xâm nhập:** Toàn bộ hệ thống sẽ bị ảnh hưởng nghiêm trọng.

---

## 2. NGUYÊN LÝ HOẠT ĐỘNG

### 2.1. Luồng đăng nhập với OTP

```
┌─────────────┐
│  Người dùng │
└──────┬──────┘
       │ 1. Nhập username/password
       ▼
┌─────────────────┐
│  Backend kiểm tra│
│  username/password│
└──────┬──────────┘
       │ 2. Phát hiện là DEAN
       │ 3. Tạo mã OTP ngẫu nhiên
       │ 4. Lưu OTP vào bộ nhớ (10 phút)
       │ 5. Gửi email chứa OTP
       ▼
┌─────────────┐
│  Người dùng │
│  (Nhận email)│
└──────┬──────┘
       │ 6. Nhập mã OTP
       ▼
┌─────────────────┐
│  Backend xác thực│
│  OTP             │
└──────┬──────────┘
       │ 7. OTP đúng → Tạo JWT token
       │ 8. Xóa OTP (chỉ dùng 1 lần)
       ▼
┌─────────────┐
│  Đăng nhập  │
│  thành công │
└─────────────┘
```

### 2.2. Các bước chi tiết

**Bước 1-2: Xác thực Username/Password**
- Backend kiểm tra username và password (đã hash bằng bcrypt)
- Nếu đúng và là Trưởng Khoa → Chuyển sang bước OTP
- Nếu là người dùng khác → Đăng nhập bình thường (không cần OTP)

**Bước 3-4: Tạo và lưu OTP**
- Tạo mã OTP ngẫu nhiên 6 chữ số
- Lưu vào bộ nhớ với thông tin:
  - Mã OTP
  - Thời gian hết hạn (10 phút)
  - Số lần thử (bắt đầu từ 0, tối đa 10 lần)

**Bước 5: Gửi email OTP**
- Kết nối SMTP server (Gmail)
- Gửi email HTML chứa mã OTP
- Email được mã hóa bằng TLS

**Bước 6-7: Xác thực OTP**
- Người dùng nhập mã OTP
- Backend kiểm tra:
  - OTP có tồn tại không?
  - OTP có hết hạn không? (10 phút)
  - Số lần thử có vượt quá 10 lần không?
  - OTP có đúng không?
- Nếu đúng → Tạo JWT token và xóa OTP
- Nếu sai → Tăng số lần thử, thông báo số lần còn lại

**Bước 8: Đăng nhập thành công**
- Backend tạo JWT token (hết hạn sau 30 phút)
- Frontend lưu token vào localStorage
- Người dùng có thể sử dụng hệ thống

### 2.3. Cơ chế bảo mật

**1. Thời gian hết hạn ngắn**
- OTP chỉ có hiệu lực trong 10 phút
- Sau 10 phút, OTP tự động vô hiệu

**2. Giới hạn số lần thử**
- Tối đa 10 lần thử
- Sau 10 lần sai, OTP bị vô hiệu, phải đăng nhập lại

**3. One-time use**
- OTP chỉ dùng được 1 lần duy nhất
- Sau khi xác thực thành công, OTP bị xóa ngay

**4. Ngẫu nhiên và không đoán được**
- OTP 6 chữ số = 1,000,000 khả năng
- Xác suất đoán đúng rất thấp

**5. Email mã hóa**
- Email được gửi qua TLS encryption
- Ngăn chặn man-in-the-middle attack

---

## 3. CÁCH TRIỂN KHAI TRONG HỆ THỐNG

### 3.1. Kiến trúc hệ thống

```
Frontend (React) ←→ Backend (FastAPI) ←→ Database (PostgreSQL)
                           ↓
                    Email Server (SMTP)
```

### 3.2. Backend Implementation

#### a) Router: `lms_backend/app/routers/auth.py`

**Endpoint `/auth/login`:**
```python
@router.post("/login")
async def login_for_access_token(...):
    # 1. Xác thực username/password
    user = get_user_by_username(db, username=form_data.username)
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(401, "Incorrect username or password")
    
    # 2. Kiểm tra vai trò
    if user.role == UserRole.DEAN:
        # 3. Tạo và gửi OTP
        otp = generate_otp()
        store_otp(user.id, otp)
        send_otp_email(user.email, otp, user.full_name)
        
        # 4. Lưu phiên đăng nhập tạm thời
        pending_dean_logins[user.username] = {...}
        
        return {"requires_otp": True, "message": "OTP đã được gửi..."}
    else:
        # Đăng nhập bình thường
        return {"access_token": token, ...}
```

**Endpoint `/auth/verify-otp`:**
```python
@router.post("/verify-otp")
async def verify_otp_login(request: OTPVerifyRequest, ...):
    # 1. Kiểm tra phiên đăng nhập
    if username not in pending_dean_logins:
        raise HTTPException(400, "Phiên xác thực đã hết hạn")
    
    # 2. Xác thực OTP
    success, remaining = verify_otp(user_id, request.otp)
    
    if not success:
        if remaining <= 0:
            raise HTTPException(401, "Đã hết số lần thử")
        raise HTTPException(401, f"Còn {remaining} lần thử")
    
    # 3. OTP đúng, tạo JWT token
    access_token = create_access_token(...)
    return {"access_token": access_token, ...}
```

#### b) Service: `lms_backend/app/services/otp_service.py`

**Tạo OTP:**
```python
def generate_otp() -> str:
    """Tạo mã OTP ngẫu nhiên 6 chữ số"""
    return ''.join(random.choices(string.digits, k=6))
```

**Lưu OTP:**
```python
otp_storage: Dict[str, dict] = {}  # Lưu trong bộ nhớ

def store_otp(user_id: int, otp: str):
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }
```

**Xác thực OTP:**
```python
def verify_otp(user_id: int, otp: str) -> tuple[bool, int]:
    stored = otp_storage.get(str(user_id))
    
    # Kiểm tra hết hạn
    if datetime.utcnow() > stored["expires_at"]:
        return (False, 0)
    
    # Kiểm tra số lần thử
    if stored["attempts"] >= 10:
        return (False, 0)
    
    stored["attempts"] += 1
    
    # So sánh OTP
    if stored["otp"] == otp:
        del otp_storage[str(user_id)]  # Xóa sau khi dùng
        return (True, remaining)
    
    return (False, remaining)
```

**Gửi email OTP:**
```python
def send_otp_email(email: str, otp: str, full_name: str) -> bool:
    msg = MIMEMultipart('alternative')
    msg['Subject'] = 'LMS - Mã xác thực đăng nhập (OTP)'
    msg['From'] = settings.SMTP_EMAIL
    msg['To'] = email
    
    # Tạo nội dung HTML
    html = f"""...mã OTP: {otp}..."""
    
    # Gửi qua SMTP với TLS
    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
        server.starttls()  # Mã hóa TLS
        server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
        server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
    
    return True
```

### 3.3. Frontend Implementation

#### a) Trang đăng nhập: `lms_frontend/src/pages/Login.tsx`

```typescript
const handleSubmit = async (e: React.FormEvent) => {
    const response = await api.post('/auth/login', {
        username: username,
        password: password
    });
    
    const data = response.data;
    
    // Kiểm tra có cần OTP không
    if (data.requires_otp) {
        // Chuyển đến trang xác thực OTP
        navigate('/verify-otp', {
            state: {
                username: username,
                emailHint: data.email_hint
            }
        });
    } else {
        // Đăng nhập bình thường
        login(data.access_token, {...});
        navigate('/dashboard');
    }
};
```

#### b) Trang xác thực OTP: `lms_frontend/src/pages/OtpVerify.tsx`

```typescript
const handleOtpSubmit = async (e: React.FormEvent) => {
    const response = await api.post('/auth/verify-otp', {
        username: username,
        otp: otp
    });
    
    // Nhận JWT token
    const { access_token, role } = response.data;
    
    // Đăng nhập thành công
    login(access_token, { username, role });
    navigate('/dashboard');
};
```

### 3.4. Cấu hình

**File: `lms_backend/app/core/config.py`**

```python
class Settings:
    # OTP Configuration
    OTP_LENGTH: int = 6
    OTP_EXPIRE_MINUTES: int = 10
    OTP_MAX_ATTEMPTS: int = 10
    
    # SMTP Configuration
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_EMAIL: str  # Email gửi OTP
    SMTP_PASSWORD: str  # Mật khẩu ứng dụng Gmail
    
    # JWT Configuration
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    SECRET_KEY: str  # Secret key để ký JWT
```

### 3.5. Lưu trữ dữ liệu

**OTP Storage:**
- Hiện tại: Lưu trong bộ nhớ (dictionary `otp_storage`)
- Nhược điểm: Mất khi server restart
- Khuyến nghị: Chuyển sang Redis hoặc database

**Pending Logins:**
- Lưu thông tin đăng nhập tạm thời trong `pending_dean_logins` (dictionary)
- Tự động xóa sau khi xác thực thành công hoặc hết hạn

**JWT Token:**
- Lưu trong localStorage của frontend
- Hết hạn sau 30 phút
- Tự động thêm vào header mọi request

---

## 4. TÓM TẮT

### 4.1. Quy trình đăng nhập

1. **Người dùng nhập username/password** → Backend xác thực
2. **Nếu là Trưởng Khoa** → Backend tạo OTP và gửi email
3. **Người dùng nhận email** → Nhập mã OTP
4. **Backend xác thực OTP** → Tạo JWT token
5. **Frontend lưu token** → Đăng nhập thành công

### 4.2. Điểm mạnh

- ✅ **2FA hiệu quả**: Ngay cả khi mật khẩu bị lộ, vẫn cần OTP
- ✅ **Thời gian hết hạn ngắn**: OTP chỉ có hiệu lực 10 phút
- ✅ **Giới hạn số lần thử**: Tối đa 10 lần, chống brute-force
- ✅ **One-time use**: OTP chỉ dùng được 1 lần
- ✅ **Email mã hóa**: TLS encryption khi gửi

### 4.3. Khuyến nghị cải thiện

- **Rate limiting**: Giới hạn số lần đăng nhập/phút
- **Redis storage**: Chuyển OTP storage sang Redis (không mất khi restart)
- **HttpOnly cookie**: Dùng cookie thay vì localStorage cho JWT token
- **Audit logging**: Ghi log các lần đăng nhập để theo dõi

---

**Tác giả**: AI Assistant  
**Ngày**: 2024  
**Phiên bản**: 1.0

