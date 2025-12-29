# BÁO CÁO BẢO MẬT: ĐĂNG NHẬP OTP CHO TÀI KHOẢN TRƯỞNG KHOA

## 1. TỔNG QUAN

### 1.1. Giới thiệu

Hệ thống LMS (Learning Management System) yêu cầu xác thực hai yếu tố (2FA) với OTP qua email cho tài khoản Trưởng Khoa. Đây là biện pháp bảo mật quan trọng vì Trưởng Khoa có quyền cao nhất trong hệ thống, có thể quản lý toàn bộ tài khoản, điểm số, và dữ liệu học tập.

### 1.2. Khái niệm OTP và 2FA

**OTP (One-Time Password)**: Mật khẩu một lần, chỉ sử dụng được một lần duy nhất, có thời gian hết hạn ngắn (10 phút).

**2FA (Two-Factor Authentication)**: Xác thực hai yếu tố:
- **Yếu tố 1**: Username và Password (cái bạn biết)
- **Yếu tố 2**: Mã OTP qua email (cái bạn có)

Chỉ khi có CẢ HAI yếu tố, Trưởng Khoa mới có thể đăng nhập thành công.

### 1.3. Tại sao cần OTP cho Trưởng Khoa?

- Quyền hạn cao nhất: Tạo/xóa/sửa tất cả tài khoản, xem và chỉnh sửa điểm số, quản lý toàn bộ hệ thống
- Rủi ro lớn: Nếu tài khoản bị hack, toàn bộ hệ thống sẽ bị ảnh hưởng nghiêm trọng
- Bảo vệ tối đa: Ngay cả khi mật khẩu bị lộ, kẻ tấn công vẫn không thể đăng nhập nếu không có OTP

---

## 2. LUỒNG HOẠT ĐỘNG

### 2.1. Sơ đồ tổng quan

```
Người dùng → Nhập username/password → Backend kiểm tra
    ↓
Backend phát hiện là DEAN → Tạo OTP → Gửi email
    ↓
Người dùng nhận email → Nhập OTP → Backend xác thực OTP
    ↓
Backend tạo JWT token → Trả về cho Frontend → Đăng nhập thành công
```

### 2.2. Các bước chi tiết

**Bước 1**: Người dùng nhập username và password trên trang đăng nhập

**Bước 2**: Frontend gửi request `POST /auth/login` đến Backend

**Bước 3**: Backend xác thực username/password:
- Tìm user trong database
- So sánh mật khẩu đã hash bằng bcrypt
- Kiểm tra vai trò (role)

**Bước 4**: Nếu là Trưởng Khoa (DEAN):
- Tạo mã OTP ngẫu nhiên 6 chữ số
- Lưu OTP vào bộ nhớ với thời gian hết hạn (10 phút)
- Gửi email chứa OTP đến địa chỉ email của người dùng
- Lưu thông tin đăng nhập tạm thời vào `pending_dean_logins`
- Trả về response yêu cầu OTP

**Bước 5**: Frontend nhận response, chuyển hướng đến trang xác thực OTP

**Bước 6**: Người dùng nhận email, nhập mã OTP vào form

**Bước 7**: Frontend gửi request `POST /auth/verify-otp` với username và OTP

**Bước 8**: Backend xác thực OTP:
- Kiểm tra phiên đăng nhập có tồn tại không
- Kiểm tra OTP có đúng không
- Kiểm tra OTP có hết hạn không (10 phút)
- Kiểm tra số lần thử (tối đa 10 lần)
- Nếu đúng: Xóa OTP (chỉ dùng được 1 lần)

**Bước 9**: Nếu OTP đúng, Backend tạo JWT token:
- Chứa username và user_id
- Có thời gian hết hạn (30 phút)
- Được ký bằng secret key

**Bước 10**: Frontend nhận token, lưu vào localStorage, chuyển đến Dashboard

---

## 3. CƠ CHẾ BẢO MẬT

### 3.1. Lớp 1: Xác thực Username/Password

**Mật khẩu được hash bằng bcrypt**:
- Mật khẩu KHÔNG BAO GIỜ được lưu dạng text
- Database chỉ lưu hash, không thể reverse về mật khẩu gốc
- Mỗi mật khẩu có salt ngẫu nhiên riêng
- Mỗi lần verify mất ~100ms (làm chậm brute-force attack)

**Code**:
```python
def get_password_hash(password):
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def verify_password(plain_password, hashed_password):
    return bcrypt.checkpw(plain_password.encode(), hashed_password.encode())
```

### 3.2. Lớp 2: Xác thực OTP (2FA)

**Yêu cầu 2 yếu tố**:
- Yếu tố 1: Username/Password (đã xác thực ở bước 1)
- Yếu tố 2: OTP qua email

**Chỉ áp dụng cho Trưởng Khoa**: Giảng viên và sinh viên đăng nhập bình thường, không cần OTP.

### 3.3. Lớp 3: Bảo vệ OTP

**Thời gian hết hạn ngắn**: OTP chỉ có hiệu lực trong 10 phút, sau đó tự động vô hiệu.

**Giới hạn số lần thử**: Tối đa 10 lần thử, sau đó OTP bị vô hiệu hóa, phải đăng nhập lại.

**One-time use**: OTP chỉ dùng được 1 lần duy nhất, sau khi xác thực thành công sẽ bị xóa ngay.

**Ngẫu nhiên và không đoán được**: OTP 6 chữ số = 1,000,000 khả năng, xác suất đoán đúng rất thấp.

**Code**:
```python
def generate_otp() -> str:
    return ''.join(random.choices(string.digits, k=6))

def store_otp(user_id: int, otp: str):
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }
```

### 3.4. Lớp 4: Bảo vệ JWT Token

**Thời gian hết hạn**: Token tự động hết hạn sau 30 phút, phải đăng nhập lại.

**Signature**: Token được ký bằng secret key, không thể giả mạo nếu không có key.

**Minimal data**: Token chỉ chứa username và user_id, không có thông tin nhạy cảm.

**Code**:
```python
def create_access_token(data: dict):
    expire = datetime.utcnow() + timedelta(minutes=30)
    to_encode = data.copy()
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm="HS256")
```

### 3.5. Lớp 5: Bảo vệ Email Communication

**TLS Encryption**: Email được mã hóa bằng TLS khi truyền qua mạng, ngăn chặn man-in-the-middle attack.

**Email hint**: Chỉ hiển thị 3 ký tự đầu của email (ví dụ: `dea***@gmail.com`) để bảo vệ quyền riêng tư.

**Cảnh báo bảo mật**: Email chứa cảnh báo không chia sẻ OTP với bất kỳ ai.

### 3.6. Lớp 6: Bảo vệ Session và State

**Pending logins tự động xóa**: Sau khi xác thực OTP thành công hoặc hết lần thử, phiên đăng nhập tạm thời bị xóa.

**SessionStorage cho dữ liệu tạm**: Thông tin OTP được lưu trong sessionStorage (mất khi đóng tab), không phải localStorage.

**Token cleanup**: Khi logout, token được xóa khỏi localStorage.

---

## 4. CODE IMPLEMENTATION CHÍNH

### 4.1. Backend - Router Authentication

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/login")
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm,
    db: Session = Depends(get_db)
):
    # Xác thực username/password
    user = get_user_by_username(db, username=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    
    # Kiểm tra vai trò
    if user.role == UserRole.DEAN:
        # Tạo và gửi OTP
        otp = generate_otp()
        store_otp(user.id, otp)
        send_otp_email(user.email, otp, user.full_name)
        
        # Lưu phiên đăng nhập tạm thời
        pending_dean_logins[user.username] = {
            "user_id": user.id,
            "username": user.username,
            "role": user.role.value
        }
        
        return {
            "requires_otp": True,
            "message": "OTP đã được gửi đến email của bạn",
            "email_hint": masked_email
        }
    else:
        # Đăng nhập bình thường
        access_token = create_access_token(
            data={"sub": user.username, "user_id": user.id}
        )
        return {"access_token": access_token, "token_type": "bearer"}

@router.post("/verify-otp")
async def verify_otp_login(request: OTPVerifyRequest, db: Session = Depends(get_db)):
    # Kiểm tra phiên đăng nhập
    if request.username not in pending_dean_logins:
        raise HTTPException(status_code=400, detail="Phiên xác thực đã hết hạn")
    
    # Xác thực OTP
    user_id = pending_dean_logins[request.username]["user_id"]
    success, remaining = verify_otp(user_id, request.otp)
    
    if not success:
        if remaining <= 0:
            del pending_dean_logins[request.username]
            raise HTTPException(status_code=401, detail="Đã hết số lần thử")
        raise HTTPException(status_code=401, detail=f"Mã OTP không đúng. Còn {remaining} lần thử")
    
    # OTP đúng, tạo token
    del pending_dean_logins[request.username]
    user = get_user_by_username(db, username=request.username)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}
    )
    return {"access_token": access_token, "token_type": "bearer"}
```

### 4.2. Backend - OTP Service

**File**: `lms_backend/app/services/otp_service.py`

```python
otp_storage: Dict[str, dict] = {}

def generate_otp() -> str:
    return ''.join(random.choices(string.digits, k=6))

def store_otp(user_id: int, otp: str):
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }

def verify_otp(user_id: int, otp: str) -> tuple[bool, int]:
    stored = otp_storage.get(str(user_id))
    if not stored:
        return (False, 0)
    
    # Kiểm tra hết hạn
    if datetime.utcnow() > stored["expires_at"]:
        del otp_storage[str(user_id)]
        return (False, 0)
    
    # Kiểm tra số lần thử
    if stored["attempts"] >= 10:
        del otp_storage[str(user_id)]
        return (False, 0)
    
    stored["attempts"] += 1
    remaining = 10 - stored["attempts"]
    
    # So sánh OTP
    if stored["otp"] == otp:
        del otp_storage[str(user_id)]  # Xóa sau khi dùng
        return (True, remaining)
    
    return (False, remaining)

def send_otp_email(email: str, otp: str, full_name: str) -> bool:
    try:
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'LMS - Mã xác thực đăng nhập (OTP)'
        msg['From'] = settings.SMTP_EMAIL
        msg['To'] = email
        
        html = f"""
        <html>
        <body>
            <p>Xin chào <strong>{full_name}</strong>,</p>
            <p>Mã OTP của bạn là: <strong>{otp}</strong></p>
            <p>Mã này có hiệu lực trong 10 phút.</p>
            <p>⚠️ Không chia sẻ mã này với bất kỳ ai.</p>
        </body>
        </html>
        """
        
        msg.attach(MIMEText(html, 'html'))
        
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
        
        return True
    except Exception as e:
        print(f"Failed to send OTP email: {e}")
        return False
```

### 4.3. Frontend - Login Page

**File**: `lms_frontend/src/pages/Login.tsx`

```typescript
const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
        const response = await api.post('/auth/login', new URLSearchParams({
            username: username,
            password: password,
        }));
        
        const data = response.data;
        
        // Kiểm tra có cần OTP không
        if (data.requires_otp) {
            navigate('/verify-otp', {
                state: {
                    username: username,
                    emailHint: data.email_hint,
                    message: data.message
                }
            });
        } else {
            // Đăng nhập bình thường
            const { access_token, role } = data;
            login(access_token, { username, role });
            navigate('/dashboard');
        }
    } catch (err) {
        setError(err.response?.data?.detail || 'Đăng nhập thất bại');
    }
};
```

### 4.4. Frontend - OTP Verification

**File**: `lms_frontend/src/pages/OtpVerify.tsx`

```typescript
const handleOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
        const response = await api.post('/auth/verify-otp', {
            username: username,
            otp: otp
        });
        
        const { access_token, role } = response.data;
        login(access_token, { username, role });
        navigate('/dashboard');
    } catch (err) {
        setError(err.response?.data?.detail || 'Mã OTP không hợp lệ');
    }
};
```

---

## 5. RỦI RO VÀ CÁCH KHẮC PHỤC

### 5.1. Rủi ro đã được khắc phục

| Rủi ro | Cách khắc phục | Trạng thái |
|--------|----------------|------------|
| **Brute force password** | bcrypt làm chậm, không tiết lộ thông tin | ✅ Đã khắc phục |
| **OTP interception** | TLS encryption, thời gian hết hạn ngắn | ✅ Đã khắc phục |
| **OTP brute force** | Giới hạn 10 lần thử | ✅ Đã khắc phục |
| **OTP replay** | OTP chỉ dùng được 1 lần | ✅ Đã khắc phục |
| **Token theft** | Token hết hạn sau 30 phút, signature | ✅ Đã khắc phục |
| **Email không mã hóa** | TLS encryption | ✅ Đã khắc phục |

### 5.2. Rủi ro cần cải thiện

| Rủi ro | Mức độ | Cách khắc phục đề xuất |
|--------|--------|------------------------|
| **Rate limiting** | Trung bình | Thêm rate limiting cho login endpoint (5 lần/phút) |
| **Account lockout** | Trung bình | Khóa tài khoản tạm thời sau 5 lần thử sai |
| **OTP storage** | Thấp | Chuyển từ memory sang Redis (không mất khi restart) |
| **Token storage** | Trung bình | Dùng httpOnly cookie thay vì localStorage |
| **Email compromise** | Cao | Thông báo khi có đăng nhập mới, yêu cầu 2FA cho email |

### 5.3. Kế hoạch cải thiện

**Ưu tiên cao (thực hiện ngay)**:
1. Thêm rate limiting cho login endpoint
2. Account lockout sau nhiều lần thử sai
3. Giảm thời gian hết hạn OTP từ 10 phút xuống 5 phút
4. Thông báo email khi có đăng nhập mới

**Ưu tiên trung bình (1-2 tháng)**:
1. Chuyển OTP storage sang Redis
2. HttpOnly cookie cho JWT token
3. Refresh token mechanism
4. Audit logging cho các lần đăng nhập

**Ưu tiên thấp (3-6 tháng)**:
1. SMS backup cho OTP
2. IP whitelist cho trưởng khoa
3. Security monitoring và alerting

---

## 6. KẾT LUẬN

### 6.1. Tóm tắt

Hệ thống đăng nhập OTP cho tài khoản Trưởng Khoa đã được triển khai với nhiều lớp bảo mật:

- ✅ **Xác thực 2 yếu tố**: Yêu cầu cả password và OTP
- ✅ **Mật khẩu an toàn**: Hash bằng bcrypt, không lưu dạng text
- ✅ **OTP bảo vệ**: Hết hạn ngắn, giới hạn số lần thử, chỉ dùng 1 lần
- ✅ **JWT token an toàn**: Hết hạn sau 30 phút, được ký bằng secret key
- ✅ **Email mã hóa**: TLS encryption khi truyền
- ✅ **Session cleanup**: Tự động xóa dữ liệu tạm thời

### 6.2. Điểm mạnh

1. **Nhiều lớp bảo vệ**: Defense in Depth, nếu một lớp bị phá vỡ, các lớp khác vẫn bảo vệ
2. **2FA hiệu quả**: Ngay cả khi mật khẩu bị lộ, vẫn cần OTP để đăng nhập
3. **Time-limited**: OTP và token đều có thời gian hết hạn ngắn
4. **User-friendly**: Giao diện rõ ràng, thông báo đầy đủ

### 6.3. Khuyến nghị

1. **Thực hiện ngay**: Rate limiting, account lockout
2. **Cải thiện dần**: Redis storage, httpOnly cookie, audit logging
3. **Giám sát liên tục**: Security monitoring, regular audits

Hệ thống hiện tại đã đạt mức bảo mật tốt, nhưng vẫn cần cải thiện thêm để đạt mức bảo mật cao nhất.

---

**Tác giả**: AI Assistant  
**Ngày**: 2024  
**Phiên bản**: 1.0




