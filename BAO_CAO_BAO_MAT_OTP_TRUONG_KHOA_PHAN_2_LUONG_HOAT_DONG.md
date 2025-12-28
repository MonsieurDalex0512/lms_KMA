# BÁO CÁO BẢO MẬT CHUYÊN SÂU: ĐĂNG NHẬP OTP CHO TÀI KHOẢN TRƯỞNG KHOA
## PHẦN 2: LUỒNG HOẠT ĐỘNG CHI TIẾT

## MỤC LỤC

1. [Tổng quan luồng đăng nhập](#1-tổng-quan-luồng-đăng-nhập)
2. [Bước 1: Người dùng nhập thông tin đăng nhập](#2-bước-1-người-dùng-nhập-thông-tin-đăng-nhập)
3. [Bước 2: Frontend gửi request đến Backend](#3-bước-2-frontend-gửi-request-đến-backend)
4. [Bước 3: Backend xác thực username/password](#4-bước-3-backend-xác-thực-usernamepassword)
5. [Bước 4: Backend kiểm tra vai trò và tạo OTP](#5-bước-4-backend-kiểm-tra-vai-trò-và-tạo-otp)
6. [Bước 5: Backend gửi email OTP](#6-bước-5-backend-gửi-email-otp)
7. [Bước 6: Người dùng nhận email và nhập OTP](#7-bước-6-người-dùng-nhận-email-và-nhập-otp)
8. [Bước 7: Frontend gửi OTP để xác thực](#8-bước-7-frontend-gửi-otp-để-xác-thực)
9. [Bước 8: Backend xác thực OTP](#9-bước-8-backend-xác-thực-otp)
10. [Bước 9: Backend tạo JWT token](#10-bước-9-backend-tạo-jwt-token)
11. [Bước 10: Frontend lưu token và đăng nhập thành công](#11-bước-10-frontend-lưu-token-và-đăng-nhập-thành-công)
12. [Sơ đồ luồng hoàn chỉnh](#12-sơ-đồ-luồng-hoàn-chỉnh)

---

## 1. TỔNG QUAN LUỒNG ĐĂNG NHẬP

### 1.1. Luồng đăng nhập cho Trưởng khoa (có OTP)

```
Người dùng → Nhập username/password → Backend kiểm tra
    ↓
Backend phát hiện là DEAN → Tạo OTP → Gửi email
    ↓
Người dùng nhận email → Nhập OTP → Backend xác thực OTP
    ↓
Backend tạo JWT token → Trả về cho Frontend → Đăng nhập thành công
```

### 1.2. Luồng đăng nhập cho người dùng khác (không OTP)

```
Người dùng → Nhập username/password → Backend kiểm tra
    ↓
Backend tạo JWT token ngay → Trả về cho Frontend → Đăng nhập thành công
```

**Lưu ý**: Chỉ có **Trưởng khoa (DEAN)** mới cần OTP!

---

## 2. BƯỚC 1: NGƯỜI DÙNG NHẬP THÔNG TIN ĐĂNG NHẬP

### 2.1. Giao diện đăng nhập

**File**: `lms_frontend/src/pages/Login.tsx`

Người dùng mở trang đăng nhập và nhập:
- **Username**: Tên đăng nhập (ví dụ: `dean001`)
- **Password**: Mật khẩu

### 2.2. Code xử lý form

```typescript
// File: lms_frontend/src/pages/Login.tsx

const [username, setUsername] = useState('');
const [password, setPassword] = useState('');

const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault(); // Ngăn form submit mặc định
    setError('');
    setIsLoading(true);

    try {
        // Gửi request đến backend
        const response = await api.post('/auth/login', new URLSearchParams({
            username: username,
            password: password,
        }), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });
        
        // Xử lý phản hồi (sẽ giải thích ở bước tiếp theo)
        // ...
    } catch (err) {
        // Xử lý lỗi
        setError(err.response?.data?.detail || 'Tên đăng nhập hoặc mật khẩu không đúng');
    }
};
```

### 2.3. Giải thích

- `useState`: Lưu trữ giá trị username và password
- `handleSubmit`: Hàm được gọi khi người dùng nhấn nút "Đăng nhập"
- `e.preventDefault()`: Ngăn trình duyệt reload trang
- `api.post()`: Gửi HTTP POST request đến backend

---

## 3. BƯỚC 2: FRONTEND GỬI REQUEST ĐẾN BACKEND

### 3.1. HTTP Request

**Endpoint**: `POST /auth/login`

**Headers**:
```
Content-Type: application/x-www-form-urlencoded
```

**Body**:
```
username=dean001&password=myPassword123
```

### 3.2. Code API Service

**File**: `lms_frontend/src/services/api.ts`

```typescript
import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:8000',
    headers: {
        'Content-Type': 'application/json',
    },
});

// Tự động thêm JWT token vào header (nếu có)
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);

export default api;
```

### 3.3. Giải thích

- `axios.create()`: Tạo instance axios với cấu hình mặc định
- `baseURL`: URL gốc của backend API
- `interceptors.request`: Tự động thêm JWT token vào mọi request (nếu đã đăng nhập)
- Request được gửi đến: `http://localhost:8000/auth/login`

---

## 4. BƯỚC 3: BACKEND XÁC THỰC USERNAME/PASSWORD

### 4.1. Endpoint nhận request

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/login")
async def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db)
):
    # Bước 3.1: Tìm user trong database
    user = get_user_by_username(db, username=form_data.username)
    
    # Bước 3.2: Kiểm tra user có tồn tại không
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Bước 3.3: Kiểm tra mật khẩu
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Bước 3.4: Kiểm tra vai trò (sẽ giải thích ở bước tiếp theo)
    if user.role == UserRole.DEAN:
        # Xử lý OTP cho trưởng khoa
        # ...
    else:
        # Đăng nhập bình thường cho người dùng khác
        # ...
```

### 4.2. Hàm xác thực mật khẩu

**File**: `lms_backend/app/auth/security.py`

```python
import bcrypt

def verify_password(plain_password, hashed_password):
    """
    So sánh mật khẩu người dùng nhập với mật khẩu đã hash trong database
    
    Args:
        plain_password: Mật khẩu người dùng nhập (dạng text)
        hashed_password: Mật khẩu đã hash trong database (dạng bcrypt hash)
    
    Returns:
        True nếu mật khẩu đúng, False nếu sai
    """
    # Chuyển đổi sang bytes nếu là string
    if isinstance(plain_password, str):
        plain_password = plain_password.encode('utf-8')
    if isinstance(hashed_password, str):
        hashed_password = hashed_password.encode('utf-8')
    
    # Sử dụng bcrypt để so sánh
    return bcrypt.checkpw(plain_password, hashed_password)
```

### 4.3. Giải thích về bcrypt

**bcrypt** là thuật toán hash mật khẩu an toàn:

1. **Mật khẩu được hash khi tạo tài khoản**:
   ```python
   # Khi tạo user, mật khẩu được hash
   hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
   # Kết quả: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5
   ```

2. **Mật khẩu KHÔNG BAO GIỜ được lưu dạng text**:
   - Database chỉ lưu hash, không lưu mật khẩu gốc
   - Ngay cả admin cũng không thể xem mật khẩu gốc

3. **Khi đăng nhập, so sánh hash**:
   - Hash mật khẩu người dùng nhập
   - So sánh với hash trong database
   - Nếu khớp → mật khẩu đúng

### 4.4. Lưu ý bảo mật

- ✅ Mật khẩu được hash bằng bcrypt (rất an toàn)
- ✅ Không trả về thông tin chi tiết khi sai (chỉ nói "sai username hoặc password")
- ✅ Sử dụng HTTP status code 401 (Unauthorized) khi sai

---

## 5. BƯỚC 4: BACKEND KIỂM TRA VAI TRÒ VÀ TẠO OTP

### 5.1. Kiểm tra vai trò

**File**: `lms_backend/app/routers/auth.py`

```python
# Sau khi xác thực username/password thành công
if user.role == UserRole.DEAN:
    # Đây là trưởng khoa, cần OTP!
    
    # Bước 4.1: Tạo mã OTP ngẫu nhiên
    otp = generate_otp()
    
    # Bước 4.2: Lưu OTP vào bộ nhớ với thời gian hết hạn
    store_otp(user.id, otp)
    
    # Bước 4.3: Lấy thông tin email và tên
    email = user.email
    full_name = user.full_name or user.username
    
    # Bước 4.4: Gửi email OTP (sẽ giải thích ở bước tiếp theo)
    email_sent = send_otp_email(email, otp, full_name)
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send OTP email. Please try again."
        )
    
    # Bước 4.5: Lưu thông tin đăng nhập tạm thời
    pending_dean_logins[user.username] = {
        "user_id": user.id,
        "username": user.username,
        "role": user.role.value
    }
    
    # Bước 4.6: Tạo email hint (ẩn một phần email)
    email_parts = email.split('@')
    masked_email = email_parts[0][:3] + '***@' + email_parts[1] if len(email_parts) == 2 else '***'
    
    # Bước 4.7: Trả về thông báo cần OTP
    return {
        "requires_otp": True,
        "message": f"OTP đã được gửi đến email của bạn. Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.",
        "email_hint": masked_email
    }
else:
    # Người dùng khác (giảng viên, sinh viên) - không cần OTP
    # Tạo JWT token ngay
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, 
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer", "role": user.role.value}
```

### 5.2. Hàm tạo OTP

**File**: `lms_backend/app/services/otp_service.py`

```python
import random
import string
from app.core.config import settings

def generate_otp() -> str:
    """
    Tạo mã OTP ngẫu nhiên
    
    Returns:
        Chuỗi số ngẫu nhiên (ví dụ: "123456")
    """
    # Tạo chuỗi số ngẫu nhiên với độ dài = OTP_LENGTH (mặc định 6)
    return ''.join(random.choices(string.digits, k=settings.OTP_LENGTH))
```

**Giải thích**:
- `string.digits`: Chứa các chữ số 0-9
- `random.choices()`: Chọn ngẫu nhiên k ký tự
- `k=settings.OTP_LENGTH`: Độ dài OTP (mặc định 6)
- Kết quả: Mã 6 chữ số ngẫu nhiên (ví dụ: `"847392"`)

### 5.3. Hàm lưu OTP

**File**: `lms_backend/app/services/otp_service.py`

```python
from datetime import datetime, timedelta
from typing import Dict

# Lưu trữ OTP trong bộ nhớ (dictionary)
otp_storage: Dict[str, dict] = {}

def store_otp(user_id: int, otp: str) -> None:
    """
    Lưu OTP với thời gian hết hạn
    
    Args:
        user_id: ID của người dùng
        otp: Mã OTP cần lưu
    """
    # Tính thời gian hết hạn (hiện tại + OTP_EXPIRE_MINUTES phút)
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    
    # Lưu vào dictionary với key là user_id
    otp_storage[str(user_id)] = {
        "otp": otp,                    # Mã OTP
        "expires_at": expires_at,      # Thời gian hết hạn
        "attempts": 0                  # Số lần thử (bắt đầu từ 0)
    }
```

**Cấu trúc dữ liệu**:
```python
otp_storage = {
    "1": {  # user_id = 1
        "otp": "847392",
        "expires_at": datetime(2024, 1, 15, 10, 15, 0),  # Hết hạn sau 10 phút
        "attempts": 0
    },
    "2": {  # user_id = 2
        "otp": "123456",
        "expires_at": datetime(2024, 1, 15, 10, 20, 0),
        "attempts": 0
    }
}
```

**Lưu ý**:
- OTP được lưu trong **bộ nhớ** (RAM), không phải database
- Khi server restart, tất cả OTP sẽ bị xóa
- Trong production, nên dùng Redis hoặc database để lưu OTP

### 5.4. Lưu thông tin đăng nhập tạm thời

**File**: `lms_backend/app/routers/auth.py`

```python
# Dictionary lưu trữ các phiên đăng nhập đang chờ OTP
pending_dean_logins = {}

# Lưu thông tin
pending_dean_logins[user.username] = {
    "user_id": user.id,
    "username": user.username,
    "role": user.role.value
}
```

**Mục đích**:
- Lưu thông tin người dùng đang chờ xác thực OTP
- Khi người dùng gửi OTP, backend biết đây là ai
- Sau khi xác thực thành công, xóa khỏi dictionary

---

## 6. BƯỚC 5: BACKEND GỬI EMAIL OTP

### 6.1. Hàm gửi email

**File**: `lms_backend/app/services/otp_service.py`

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings

def send_otp_email(email: str, otp: str, full_name: str) -> bool:
    """
    Gửi email chứa mã OTP
    
    Args:
        email: Địa chỉ email người nhận
        otp: Mã OTP cần gửi
        full_name: Tên người nhận
    
    Returns:
        True nếu gửi thành công, False nếu thất bại
    """
    try:
        # Bước 6.1: Tạo email message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'LMS - Mã xác thực đăng nhập (OTP)'
        msg['From'] = settings.SMTP_EMAIL
        msg['To'] = email
        
        # Bước 6.2: Tạo nội dung HTML
        html = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                          color: white; padding: 20px; text-align: center; 
                          border-radius: 10px 10px 0 0; }}
                .content {{ background: #f9f9f9; padding: 30px; 
                           border-radius: 0 0 10px 10px; }}
                .otp-code {{ font-size: 32px; font-weight: bold; color: #667eea; 
                            text-align: center; padding: 20px; background: white; 
                            border-radius: 10px; margin: 20px 0; letter-spacing: 8px; }}
                .warning {{ color: #e74c3c; font-size: 12px; margin-top: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🔐 Xác thực đăng nhập</h1>
                </div>
                <div class="content">
                    <p>Xin chào <strong>{full_name}</strong>,</p>
                    <p>Bạn đang đăng nhập vào hệ thống LMS với vai trò Trưởng Khoa. 
                       Vui lòng sử dụng mã OTP sau để hoàn tất đăng nhập:</p>
                    
                    <div class="otp-code">{otp}</div>
                    
                    <p>⏱️ Mã này có hiệu lực trong <strong>{settings.OTP_EXPIRE_MINUTES} phút</strong>.</p>
                    
                    <p class="warning">
                        ⚠️ Không chia sẻ mã này với bất kỳ ai. 
                        Nhân viên LMS sẽ không bao giờ yêu cầu bạn cung cấp mã OTP.
                    </p>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Bước 6.3: Tạo nội dung text (dự phòng)
        text = f"""
        Xin chào {full_name},
        
        Mã OTP của bạn là: {otp}
        
        Mã này có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.
        
        Không chia sẻ mã này với bất kỳ ai.
        """
        
        # Bước 6.4: Đính kèm cả HTML và text
        part1 = MIMEText(text, 'plain')
        part2 = MIMEText(html, 'html')
        msg.attach(part1)
        msg.attach(part2)
        
        # Bước 6.5: Kết nối SMTP server và gửi email
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()  # Bật mã hóa TLS
            server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
            server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
        
        print(f"OTP email sent successfully to {email}")
        return True
        
    except Exception as e:
        print(f"Failed to send OTP email: {e}")
        return False
```

### 6.2. Cấu hình SMTP

**File**: `lms_backend/app/core/config.py`

```python
class Settings(BaseSettings):
    # Cấu hình Gmail SMTP
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_EMAIL: str  # Email gửi (ví dụ: your-email@gmail.com)
    SMTP_PASSWORD: str  # Mật khẩu ứng dụng Gmail
```

**Giải thích SMTP**:
- **SMTP (Simple Mail Transfer Protocol)**: Giao thức gửi email
- **smtp.gmail.com**: Server SMTP của Gmail
- **Port 587**: Port cho TLS (mã hóa)
- **starttls()**: Bật mã hóa kết nối

### 6.3. Quy trình gửi email

```
Backend → Kết nối SMTP server (Gmail)
    ↓
Xác thực với username/password
    ↓
Tạo email message (HTML + text)
    ↓
Gửi email đến địa chỉ người nhận
    ↓
Email server (Gmail) gửi email đến hộp thư người nhận
```

---

## 7. BƯỚC 6: NGƯỜI DÙNG NHẬN EMAIL VÀ NHẬP OTP

### 7.1. Người dùng nhận email

Sau khi backend gửi email, người dùng sẽ nhận được email trong hộp thư với:
- **Tiêu đề**: "LMS - Mã xác thực đăng nhập (OTP)"
- **Nội dung**: Mã OTP 6 chữ số (ví dụ: `847392`)
- **Thời gian hiệu lực**: 10 phút (theo cấu hình)

### 7.2. Frontend chuyển hướng đến trang OTP

**File**: `lms_frontend/src/pages/Login.tsx`

```typescript
// Sau khi nhận phản hồi từ backend
const data = response.data;

// Kiểm tra xem có cần OTP không
if (data.requires_otp) {
    // Chuyển hướng đến trang xác thực OTP
    navigate('/verify-otp', {
        state: {
            username: username,
            emailHint: data.email_hint || '',  // Ví dụ: "dea***@gmail.com"
            message: data.message || 'OTP đã được gửi đến email của bạn'
        }
    });
} else {
    // Đăng nhập bình thường (không cần OTP)
    const { access_token, role } = data;
    login(access_token, { username, role });
    navigate('/dashboard');
}
```

### 7.3. Trang xác thực OTP

**File**: `lms_frontend/src/pages/OtpVerify.tsx`

```typescript
// Lấy thông tin từ state hoặc sessionStorage
const state = location.state as LocationState | null;

if (state?.username) {
    setUsername(state.username);
    setEmailHint(state.emailHint || '');
    setOtpMessage(state.message || 'OTP đã được gửi đến email của bạn');
    // Lưu vào sessionStorage để giữ lại khi refresh trang
    sessionStorage.setItem('otp_username', state.username);
    sessionStorage.setItem('otp_emailHint', state.emailHint || '');
}
```

**Giao diện**:
- Hiển thị email hint (ví dụ: "Mã xác thực đã được gửi đến: dea***@gmail.com")
- Input field để nhập OTP (6 chữ số)
- Nút "Xác Nhận OTP"
- Nút "Gửi lại OTP" (có cooldown 60 giây)

---

## 8. BƯỚC 7: FRONTEND GỬI OTP ĐỂ XÁC THỰC

### 8.1. Người dùng nhập OTP và submit

**File**: `lms_frontend/src/pages/OtpVerify.tsx`

```typescript
const handleOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
        // Gửi OTP đến backend để xác thực
        const response = await api.post('/auth/verify-otp', {
            username: username,
            otp: otp  // Mã OTP người dùng nhập
        });

        // Nếu thành công, nhận được JWT token
        const { access_token, role } = response.data;
        
        // Xóa thông tin tạm thời
        sessionStorage.removeItem('otp_username');
        sessionStorage.removeItem('otp_emailHint');
        
        // Đăng nhập thành công
        login(access_token, { username, role });
        navigate('/dashboard');
    } catch (err: any) {
        // Xử lý lỗi
        const errorMessage = err.response?.data?.detail || 'Mã OTP không hợp lệ';
        setError(errorMessage);
        setOtp('');  // Xóa OTP đã nhập
    } finally {
        setIsLoading(false);
    }
};
```

### 8.2. HTTP Request

**Endpoint**: `POST /auth/verify-otp`

**Headers**:
```
Content-Type: application/json
```

**Body**:
```json
{
    "username": "dean001",
    "otp": "847392"
}
```

---

## 9. BƯỚC 8: BACKEND XÁC THỰC OTP

### 9.1. Endpoint xác thực OTP

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/verify-otp", response_model=Token)
async def verify_otp_login(
    request: OTPVerifyRequest,
    db: Session = Depends(get_db)
):
    username = request.username
    otp = request.otp
    
    # Bước 8.1: Kiểm tra phiên đăng nhập có tồn tại không
    if username not in pending_dean_logins:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phiên xác thực đã hết hạn. Vui lòng thử lại từ đầu."
        )
    
    # Bước 8.2: Lấy thông tin user_id từ pending logins
    pending = pending_dean_logins[username]
    user_id = pending["user_id"]
    
    # Bước 8.3: Xác thực OTP
    success, remaining = verify_otp(user_id, otp)
    
    # Bước 8.4: Xử lý kết quả
    if not success:
        if remaining <= 0:
            # Hết số lần thử, xóa phiên đăng nhập
            del pending_dean_logins[username]
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Đã hết số lần thử. Vui lòng đăng nhập lại."
            )
        # Còn số lần thử
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Mã OTP không đúng. Còn {remaining} lần thử."
        )
    
    # Bước 8.5: OTP đúng, xóa phiên đăng nhập tạm thời
    del pending_dean_logins[username]
    
    # Bước 8.6: Lấy thông tin user từ database
    user = get_user_by_username(db, username=username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Bước 8.7: Tạo JWT token (sẽ giải thích ở bước tiếp theo)
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, 
        expires_delta=access_token_expires
    )
    
    return {"access_token": access_token, "token_type": "bearer", "role": user.role.value}
```

### 9.2. Hàm xác thực OTP

**File**: `lms_backend/app/services/otp_service.py`

```python
def verify_otp(user_id: int, otp: str) -> tuple[bool, int]:
    """
    Xác thực OTP cho một user
    
    Args:
        user_id: ID của người dùng
        otp: Mã OTP người dùng nhập
    
    Returns:
        Tuple (success, remaining_attempts):
        - success: True nếu OTP đúng, False nếu sai
        - remaining: Số lần thử còn lại
    """
    user_key = str(user_id)
    max_attempts = 10  # Tối đa 10 lần thử
    
    # Kiểm tra OTP có tồn tại không
    if user_key not in otp_storage:
        return (False, 0)
    
    stored = otp_storage[user_key]
    
    # Kiểm tra thời gian hết hạn
    if datetime.utcnow() > stored["expires_at"]:
        del otp_storage[user_key]
        return (False, 0)
    
    # Kiểm tra số lần thử
    if stored["attempts"] >= max_attempts:
        del otp_storage[user_key]
        return (False, 0)
    
    # Tăng số lần thử
    stored["attempts"] += 1
    remaining = max_attempts - stored["attempts"]
    
    # So sánh OTP
    if stored["otp"] == otp:
        # OTP đúng, xóa khỏi storage
        del otp_storage[user_key]
        return (True, remaining)
    
    # OTP sai
    if remaining <= 0:
        del otp_storage[user_key]
    
    return (False, remaining)
```

### 9.3. Các kiểm tra bảo mật

1. **Kiểm tra thời gian hết hạn**:
   - Nếu OTP đã hết hạn → Từ chối
   - Mặc định: 10 phút

2. **Giới hạn số lần thử**:
   - Tối đa 10 lần thử
   - Sau 10 lần sai → Xóa OTP, yêu cầu đăng nhập lại

3. **So sánh OTP**:
   - So sánh chính xác (case-sensitive)
   - Nếu đúng → Xóa OTP (chỉ dùng được 1 lần)

---

## 10. BƯỚC 9: BACKEND TẠO JWT TOKEN

### 10.1. JWT Token là gì?

**JWT (JSON Web Token)** là một chuẩn mã hóa để truyền thông tin xác thực giữa client và server.

**Cấu trúc JWT**:
```
header.payload.signature
```

**Ví dụ**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZWFuMDAxIiwidXNlcl9pZCI6MSwiZXhwIjoxNzA1MzI0MDAwfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### 10.2. Hàm tạo JWT Token

**File**: `lms_backend/app/auth/security.py`

```python
from datetime import datetime, timedelta
from jose import jwt
from app.core.config import settings

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Tạo JWT token
    
    Args:
        data: Dữ liệu cần mã hóa vào token (ví dụ: username, user_id)
        expires_delta: Thời gian hết hạn (mặc định 30 phút)
    
    Returns:
        JWT token (string)
    """
    to_encode = data.copy()
    
    # Thêm thời gian hết hạn
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    
    # Mã hóa bằng secret key
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt
```

### 10.3. Nội dung JWT Token

**Payload** (dữ liệu trong token):
```json
{
    "sub": "dean001",        // Username
    "user_id": 1,            // ID người dùng
    "exp": 1705324000        // Thời gian hết hạn (Unix timestamp)
}
```

### 10.4. Bảo mật JWT

- ✅ **Secret Key**: Chỉ server biết, dùng để ký token
- ✅ **Thời gian hết hạn**: Token tự động hết hạn sau 30 phút
- ✅ **Không thể giả mạo**: Không thể tạo token hợp lệ nếu không có secret key

---

## 11. BƯỚC 10: FRONTEND LƯU TOKEN VÀ ĐĂNG NHẬP THÀNH CÔNG

### 11.1. Lưu token vào localStorage

**File**: `lms_frontend/src/context/AuthContext.tsx`

```typescript
const login = (newToken: string, newUser: any) => {
    // Lưu token vào localStorage
    localStorage.setItem('token', newToken);
    localStorage.setItem('user', JSON.stringify(newUser));
    
    // Cập nhật state
    setToken(newToken);
    setUser(newUser);
};
```

### 11.2. Tự động thêm token vào mọi request

**File**: `lms_frontend/src/services/api.ts`

```typescript
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            // Tự động thêm token vào header
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);
```

### 11.3. Chuyển hướng đến Dashboard

Sau khi lưu token, frontend chuyển hướng đến trang dashboard:
```typescript
navigate('/dashboard');
```

### 11.4. Sử dụng token cho các request tiếp theo

Mỗi khi frontend gửi request đến backend:
```
GET /api/deans/students
Headers:
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Backend sẽ kiểm tra token này để xác thực người dùng.

---

## 12. SƠ ĐỒ LUỒNG HOÀN CHỈNH

```
┌─────────────┐
│  Người dùng │
└──────┬──────┘
       │ 1. Nhập username/password
       ▼
┌─────────────────┐
│  Frontend       │
│  (Login.tsx)    │
└──────┬──────────┘
       │ 2. POST /auth/login
       ▼
┌─────────────────┐
│  Backend        │
│  (auth.py)      │
└──────┬──────────┘
       │ 3. Kiểm tra username/password
       │ 4. Phát hiện là DEAN
       │ 5. Tạo OTP
       │ 6. Lưu OTP vào memory
       │ 7. Gửi email OTP
       │ 8. Trả về requires_otp=true
       ▼
┌─────────────────┐
│  Email Server   │
│  (Gmail SMTP)   │
└──────┬──────────┘
       │ 9. Gửi email đến người dùng
       ▼
┌─────────────┐
│  Người dùng │
│  (Nhận email)│
└──────┬──────┘
       │ 10. Nhập OTP
       ▼
┌─────────────────┐
│  Frontend       │
│  (OtpVerify.tsx)│
└──────┬──────────┘
       │ 11. POST /auth/verify-otp
       ▼
┌─────────────────┐
│  Backend        │
│  (auth.py)      │
└──────┬──────────┘
       │ 12. Xác thực OTP
       │ 13. Tạo JWT token
       │ 14. Trả về token
       ▼
┌─────────────────┐
│  Frontend       │
│  (AuthContext)  │
└──────┬──────────┘
       │ 15. Lưu token vào localStorage
       │ 16. Chuyển đến Dashboard
       ▼
┌─────────────┐
│  Dashboard  │
│  (Đăng nhập │
│   thành công)│
└─────────────┘
```

---

## TÓM TẮT PHẦN 2

Trong phần này, chúng ta đã tìm hiểu **LUỒNG HOẠT ĐỘNG CHI TIẾT** từng bước:

1. ✅ Người dùng nhập username/password
2. ✅ Frontend gửi request đến Backend
3. ✅ Backend xác thực username/password
4. ✅ Backend kiểm tra vai trò và tạo OTP
5. ✅ Backend gửi email OTP
6. ✅ Người dùng nhận email và nhập OTP
7. ✅ Frontend gửi OTP để xác thực
8. ✅ Backend xác thực OTP
9. ✅ Backend tạo JWT token
10. ✅ Frontend lưu token và đăng nhập thành công

**Tiếp theo**: Phần 3 sẽ giải thích **CODE IMPLEMENTATION CHI TIẾT** từng file, từng hàm một.

---

**📄 Xem tiếp**: `BAO_CAO_BAO_MAT_OTP_TRUONG_KHOA_PHAN_3_CODE_IMPLEMENTATION.md`

