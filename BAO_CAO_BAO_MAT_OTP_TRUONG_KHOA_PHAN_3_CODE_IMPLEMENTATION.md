# BÁO CÁO BẢO MẬT CHUYÊN SÂU: ĐĂNG NHẬP OTP CHO TÀI KHOẢN TRƯỞNG KHOA
## PHẦN 3: CODE IMPLEMENTATION CHI TIẾT

## MỤC LỤC

1. [Backend - Router Authentication](#1-backend---router-authentication)
2. [Backend - OTP Service](#2-backend---otp-service)
3. [Backend - Security Module](#3-backend---security-module)
4. [Backend - Configuration](#4-backend---configuration)
5. [Frontend - Login Page](#5-frontend---login-page)
6. [Frontend - OTP Verification Page](#6-frontend---otp-verification-page)
7. [Frontend - Auth Context](#7-frontend---auth-context)
8. [Frontend - API Service](#8-frontend---api-service)
9. [Database Models](#9-database-models)
10. [Tổng hợp và Best Practices](#10-tổng-hợp-và-best-practices)

---

## 1. BACKEND - ROUTER AUTHENTICATION

### 1.1. File: `lms_backend/app/routers/auth.py`

Đây là file chính xử lý tất cả các endpoint liên quan đến đăng nhập và xác thực.

#### a) Import và khởi tạo

```python
from datetime import timedelta
from typing import Annotated, Optional

from fastapi import APIRouter, Depends, HTTPException, status, Form
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.auth.security import create_access_token, verify_password, get_password_hash
from app.auth.dependencies import get_current_active_user
from app.core.config import settings
from app.crud.user import create_user, get_user_by_username, get_user_by_email
from app.database import get_db
from app.schemas.user import Token, UserCreate, User, PasswordChange
from app.models.enums import UserRole
from app.services.otp_service import generate_otp, store_otp, verify_otp, send_otp_email

# Tạo router với prefix /auth
router = APIRouter(prefix="/auth", tags=["auth"])

# Dictionary lưu trữ các phiên đăng nhập đang chờ OTP
# Key: username, Value: dict chứa user_id, username, role
pending_dean_logins = {}
```

**Giải thích**:
- `APIRouter`: Tạo router để nhóm các endpoint liên quan
- `prefix="/auth"`: Tất cả endpoint sẽ có prefix `/auth`
- `pending_dean_logins`: Dictionary lưu trữ thông tin đăng nhập tạm thời

#### b) Model cho OTP Request

```python
class OTPVerifyRequest(BaseModel):
    """Model cho request xác thực OTP"""
    username: str
    otp: str

class OTPResponse(BaseModel):
    """Model cho response khi cần OTP"""
    requires_otp: bool
    message: str
    email_hint: Optional[str] = None
```

**Giải thích**:
- `BaseModel`: Pydantic model để validate dữ liệu
- `OTPVerifyRequest`: Dữ liệu client gửi khi xác thực OTP
- `OTPResponse`: Dữ liệu server trả về khi cần OTP

#### c) Endpoint đăng nhập: `/auth/login`

```python
@router.post("/login")
async def login_for_access_token(
    form_data: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Session = Depends(get_db)
):
    """
    Endpoint đăng nhập
    
    Args:
        form_data: Form chứa username và password (OAuth2 standard)
        db: Database session
    
    Returns:
        - Nếu là DEAN: Trả về requires_otp=true và email_hint
        - Nếu không: Trả về access_token ngay
    """
    # Bước 1: Tìm user trong database
    user = get_user_by_username(db, username=form_data.username)
    
    # Bước 2: Kiểm tra user có tồn tại và mật khẩu đúng không
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Bước 3: Kiểm tra vai trò
    if user.role == UserRole.DEAN:
        # ========== XỬ LÝ OTP CHO TRƯỞNG KHOA ==========
        
        # 3.1: Tạo mã OTP ngẫu nhiên
        otp = generate_otp()
        
        # 3.2: Lưu OTP vào bộ nhớ với thời gian hết hạn
        store_otp(user.id, otp)
        
        # 3.3: Lấy thông tin email và tên
        email = user.email
        full_name = user.full_name or user.username
        
        # 3.4: Gửi email chứa OTP
        email_sent = send_otp_email(email, otp, full_name)
        
        # 3.5: Kiểm tra email có gửi thành công không
        if not email_sent:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to send OTP email. Please try again."
            )
        
        # 3.6: Lưu thông tin đăng nhập tạm thời
        pending_dean_logins[user.username] = {
            "user_id": user.id,
            "username": user.username,
            "role": user.role.value
        }
        
        # 3.7: Tạo email hint (ẩn một phần email để bảo mật)
        email_parts = email.split('@')
        masked_email = email_parts[0][:3] + '***@' + email_parts[1] if len(email_parts) == 2 else '***'
        
        # 3.8: Trả về response yêu cầu OTP
        return {
            "requires_otp": True,
            "message": f"OTP đã được gửi đến email của bạn. Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.",
            "email_hint": masked_email
        }
    
    # ========== XỬ LÝ ĐĂNG NHẬP BÌNH THƯỜNG (KHÔNG PHẢI DEAN) ==========
    
    # Tạo JWT token ngay lập tức
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, 
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "role": user.role.value
    }
```

**Giải thích chi tiết**:

1. **OAuth2PasswordRequestForm**: 
   - Form chuẩn OAuth2 để nhận username/password
   - Tự động parse từ form data

2. **get_user_by_username()**: 
   - Tìm user trong database theo username
   - Trả về `None` nếu không tìm thấy

3. **verify_password()**: 
   - So sánh mật khẩu người dùng nhập với hash trong database
   - Sử dụng bcrypt để so sánh

4. **UserRole.DEAN**: 
   - Enum để kiểm tra vai trò
   - Chỉ DEAN mới cần OTP

5. **Email hint**: 
   - Chỉ hiển thị 3 ký tự đầu của email
   - Ví dụ: `dean001@gmail.com` → `dea***@gmail.com`
   - Bảo vệ quyền riêng tư email

#### d) Endpoint xác thực OTP: `/auth/verify-otp`

```python
@router.post("/verify-otp", response_model=Token)
async def verify_otp_login(
    request: OTPVerifyRequest,
    db: Session = Depends(get_db)
):
    """
    Endpoint xác thực OTP cho trưởng khoa
    
    Args:
        request: Chứa username và otp
        db: Database session
    
    Returns:
        Token JWT nếu OTP đúng
    """
    username = request.username
    otp = request.otp
    
    # Bước 1: Kiểm tra phiên đăng nhập có tồn tại không
    if username not in pending_dean_logins:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Phiên xác thực đã hết hạn. Vui lòng thử lại từ đầu."
        )
    
    # Bước 2: Lấy thông tin từ pending logins
    pending = pending_dean_logins[username]
    user_id = pending["user_id"]
    
    # Bước 3: Xác thực OTP
    success, remaining = verify_otp(user_id, otp)
    
    # Bước 4: Xử lý kết quả
    if not success:
        if remaining <= 0:
            # Hết số lần thử, xóa phiên
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
    
    # Bước 5: OTP đúng, xóa phiên tạm thời
    del pending_dean_logins[username]
    
    # Bước 6: Lấy thông tin user từ database
    user = get_user_by_username(db, username=username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Bước 7: Tạo JWT token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id}, 
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "role": user.role.value
    }
```

**Giải thích**:

1. **Kiểm tra phiên đăng nhập**:
   - Nếu không có trong `pending_dean_logins` → Phiên đã hết hạn
   - Có thể do: Server restart, quá thời gian chờ, hoặc đã xác thực rồi

2. **verify_otp()**:
   - Trả về tuple `(success, remaining)`
   - `success`: True nếu OTP đúng, False nếu sai
   - `remaining`: Số lần thử còn lại

3. **Xóa phiên sau khi thành công**:
   - Ngăn chặn sử dụng lại phiên đăng nhập
   - Bảo mật: Mỗi phiên chỉ dùng được 1 lần

#### e) Endpoint gửi lại OTP: `/auth/resend-otp`

```python
@router.post("/resend-otp")
async def resend_otp(
    username: str = Form(...),
    db: Session = Depends(get_db)
):
    """
    Endpoint gửi lại OTP
    
    Args:
        username: Username của người dùng
        db: Database session
    
    Returns:
        Message xác nhận đã gửi lại OTP
    """
    # Bước 1: Tìm user trong database
    user = get_user_by_username(db, username=username)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Bước 2: Kiểm tra chỉ DEAN mới có thể gửi lại OTP
    if user.role != UserRole.DEAN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OTP is only required for Dean users"
        )
    
    # Bước 3: Tạo OTP mới
    otp = generate_otp()
    store_otp(user.id, otp)
    
    # Bước 4: Gửi email
    email = user.email
    full_name = user.full_name or user.username
    email_sent = send_otp_email(email, otp, full_name)
    
    if not email_sent:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to send OTP email. Please try again."
        )
    
    # Bước 5: Cập nhật phiên đăng nhập
    pending_dean_logins[user.username] = {
        "user_id": user.id,
        "username": user.username,
        "role": user.role.value
    }
    
    return {
        "message": f"OTP mới đã được gửi. Mã có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút."
    }
```

**Giải thích**:

- **Form(...)**: Nhận dữ liệu từ form data (không phải JSON)
- **Tạo OTP mới**: Mỗi lần gửi lại sẽ tạo OTP mới, OTP cũ sẽ không còn hiệu lực
- **Cập nhật phiên**: Reset phiên đăng nhập để người dùng có thể thử lại

---

## 2. BACKEND - OTP SERVICE

### 2.1. File: `lms_backend/app/services/otp_service.py`

File này chứa tất cả các hàm liên quan đến OTP.

#### a) Import và khởi tạo

```python
import random
import string
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime, timedelta
from typing import Optional, Dict
from app.core.config import settings

# Lưu trữ OTP trong bộ nhớ
# Key: user_id (string), Value: dict chứa otp, expires_at, attempts
otp_storage: Dict[str, dict] = {}
```

**Giải thích**:
- `otp_storage`: Dictionary lưu trữ OTP trong RAM
- **Lưu ý**: Trong production, nên dùng Redis hoặc database

#### b) Hàm tạo OTP: `generate_otp()`

```python
def generate_otp() -> str:
    """
    Tạo mã OTP ngẫu nhiên
    
    Returns:
        Chuỗi số ngẫu nhiên (ví dụ: "123456")
    """
    return ''.join(random.choices(string.digits, k=settings.OTP_LENGTH))
```

**Giải thích**:

1. **string.digits**: Chứa `'0123456789'`
2. **random.choices()**: 
   - Chọn ngẫu nhiên k phần tử từ string.digits
   - Có thể trùng lặp (ví dụ: "111111" là hợp lệ)
3. **k=settings.OTP_LENGTH**: Độ dài OTP (mặc định 6)
4. **''.join()**: Nối các ký tự thành chuỗi

**Ví dụ**:
```python
random.choices('0123456789', k=6)  # ['8', '4', '7', '3', '9', '2']
''.join(['8', '4', '7', '3', '9', '2'])  # "847392"
```

#### c) Hàm lưu OTP: `store_otp()`

```python
def store_otp(user_id: int, otp: str) -> None:
    """
    Lưu OTP với thời gian hết hạn
    
    Args:
        user_id: ID của người dùng
        otp: Mã OTP cần lưu
    """
    expires_at = datetime.utcnow() + timedelta(minutes=settings.OTP_EXPIRE_MINUTES)
    otp_storage[str(user_id)] = {
        "otp": otp,
        "expires_at": expires_at,
        "attempts": 0
    }
```

**Giải thích**:

1. **datetime.utcnow()**: Thời gian hiện tại (UTC)
2. **timedelta(minutes=...)**: Thêm số phút vào thời gian hiện tại
3. **otp_storage[str(user_id)]**: 
   - Key là user_id dạng string
   - Value là dict chứa OTP, thời gian hết hạn, số lần thử

**Ví dụ**:
```python
# Lưu OTP cho user_id = 1
store_otp(1, "847392")

# otp_storage sẽ có:
{
    "1": {
        "otp": "847392",
        "expires_at": datetime(2024, 1, 15, 10, 15, 0),  # 10 phút sau
        "attempts": 0
    }
}
```

#### d) Hàm xác thực OTP: `verify_otp()`

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
    max_attempts = 10
    
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

**Giải thích từng bước**:

1. **Kiểm tra tồn tại**:
   ```python
   if user_key not in otp_storage:
       return (False, 0)
   ```
   - Nếu không có OTP → Trả về False

2. **Kiểm tra hết hạn**:
   ```python
   if datetime.utcnow() > stored["expires_at"]:
       del otp_storage[user_key]
       return (False, 0)
   ```
   - Nếu đã quá thời gian hết hạn → Xóa và trả về False

3. **Kiểm tra số lần thử**:
   ```python
   if stored["attempts"] >= max_attempts:
       del otp_storage[user_key]
       return (False, 0)
   ```
   - Nếu đã thử quá 10 lần → Xóa và trả về False

4. **Tăng số lần thử**:
   ```python
   stored["attempts"] += 1
   remaining = max_attempts - stored["attempts"]
   ```
   - Mỗi lần gọi hàm này, tăng số lần thử lên 1
   - Tính số lần thử còn lại

5. **So sánh OTP**:
   ```python
   if stored["otp"] == otp:
       del otp_storage[user_key]
       return (True, remaining)
   ```
   - Nếu OTP đúng → Xóa OTP (chỉ dùng được 1 lần) → Trả về True
   - Nếu OTP sai → Trả về False và số lần thử còn lại

#### e) Hàm xóa OTP: `clear_otp()`

```python
def clear_otp(user_id: int) -> None:
    """
    Xóa OTP cho một user (dùng khi cần thiết)
    
    Args:
        user_id: ID của người dùng
    """
    user_key = str(user_id)
    if user_key in otp_storage:
        del otp_storage[user_key]
```

**Giải thích**:
- Hàm này có thể dùng để xóa OTP thủ công
- Ví dụ: Khi người dùng đăng nhập lại từ đầu

#### f) Hàm gửi email OTP: `send_otp_email()`

```python
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
        # Tạo email message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'LMS - Mã xác thực đăng nhập (OTP)'
        msg['From'] = settings.SMTP_EMAIL
        msg['To'] = email
        
        # Tạo nội dung HTML
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
        
        # Tạo nội dung text (dự phòng cho email client không hỗ trợ HTML)
        text = f"""
        Xin chào {full_name},
        
        Mã OTP của bạn là: {otp}
        
        Mã này có hiệu lực trong {settings.OTP_EXPIRE_MINUTES} phút.
        
        Không chia sẻ mã này với bất kỳ ai.
        """
        
        # Đính kèm cả HTML và text
        part1 = MIMEText(text, 'plain')
        part2 = MIMEText(html, 'html')
        msg.attach(part1)
        msg.attach(part2)
        
        # Kết nối SMTP server và gửi email
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

**Giải thích từng bước**:

1. **MIMEMultipart('alternative')**:
   - Tạo email message có thể chứa cả HTML và text
   - Email client sẽ chọn format phù hợp

2. **HTML Content**:
   - Tạo email đẹp với CSS
   - Hiển thị OTP nổi bật
   - Cảnh báo bảo mật

3. **Text Content**:
   - Dự phòng cho email client không hỗ trợ HTML
   - Nội dung đơn giản, dễ đọc

4. **SMTP Connection**:
   ```python
   with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
       server.starttls()  # Mã hóa kết nối
       server.login(...)  # Đăng nhập
       server.sendmail(...)  # Gửi email
   ```
   - `starttls()`: Bật mã hóa TLS (bảo mật)
   - `login()`: Xác thực với email server
   - `sendmail()`: Gửi email

5. **Error Handling**:
   - Nếu có lỗi → In ra console và trả về False
   - Backend sẽ xử lý lỗi và trả về HTTP 500

---

## 3. BACKEND - SECURITY MODULE

### 3.1. File: `lms_backend/app/auth/security.py`

File này chứa các hàm liên quan đến bảo mật: hash password, JWT token.

#### a) Hàm xác thực mật khẩu: `verify_password()`

```python
import bcrypt

def verify_password(plain_password, hashed_password):
    """
    So sánh mật khẩu người dùng nhập với mật khẩu đã hash
    
    Args:
        plain_password: Mật khẩu người dùng nhập (string hoặc bytes)
        hashed_password: Mật khẩu đã hash trong database (string hoặc bytes)
    
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

**Giải thích**:

1. **bcrypt.checkpw()**:
   - So sánh mật khẩu plaintext với hash
   - Tự động xử lý salt (muối) trong hash
   - An toàn và chống brute-force

2. **Ví dụ**:
   ```python
   # Khi tạo user
   hashed = bcrypt.hashpw("myPassword123".encode(), bcrypt.gensalt())
   # Kết quả: b'$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5'
   
   # Khi đăng nhập
   verify_password("myPassword123", hashed)  # True
   verify_password("wrongPassword", hashed)   # False
   ```

#### b) Hàm hash mật khẩu: `get_password_hash()`

```python
def get_password_hash(password):
    """
    Hash mật khẩu bằng bcrypt
    
    Args:
        password: Mật khẩu cần hash (string hoặc bytes)
    
    Returns:
        Mật khẩu đã hash (string)
    """
    if isinstance(password, str):
        password = password.encode('utf-8')
    return bcrypt.hashpw(password, bcrypt.gensalt()).decode('utf-8')
```

**Giải thích**:
- `bcrypt.gensalt()`: Tạo salt ngẫu nhiên
- Mỗi lần hash sẽ tạo ra kết quả khác nhau (do salt khác nhau)
- Nhưng `checkpw()` vẫn so sánh được

#### c) Hàm tạo JWT token: `create_access_token()`

```python
from datetime import datetime, timedelta
from typing import Optional
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

**Giải thích**:

1. **JWT Structure**:
   ```
   header.payload.signature
   ```

2. **Payload**:
   ```python
   {
       "sub": "dean001",      # Subject (username)
       "user_id": 1,          # User ID
       "exp": 1705324000      # Expiration time (Unix timestamp)
   }
   ```

3. **Signature**:
   - Được tạo bằng secret key
   - Đảm bảo token không thể giả mạo

4. **Ví dụ token**:
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZWFuMDAxIiwidXNlcl9pZCI6MSwiZXhwIjoxNzA1MzI0MDAwfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
   ```

#### d) Hàm giải mã JWT token: `decode_access_token()`

```python
def decode_access_token(token: str):
    """
    Giải mã JWT token
    
    Args:
        token: JWT token cần giải mã
    
    Returns:
        Payload (dict) nếu hợp lệ, None nếu không hợp lệ
    """
    try:
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None
```

**Giải thích**:
- `jwt.decode()`: Giải mã và xác thực token
- Nếu token không hợp lệ (hết hạn, sai signature, ...) → Ném exception
- Catch exception và trả về None

---

## 4. BACKEND - CONFIGURATION

### 4.1. File: `lms_backend/app/core/config.py`

File này chứa tất cả cấu hình của hệ thống.

```python
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    
    # JWT
    SECRET_KEY: str  # Secret key để ký JWT token (phải bảo mật!)
    ALGORITHM: str = "HS256"  # Thuật toán mã hóa JWT
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30  # Thời gian hết hạn token (30 phút)
    
    # SMTP (Email)
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_EMAIL: str  # Email gửi OTP
    SMTP_PASSWORD: str  # Mật khẩu ứng dụng Gmail
    
    # OTP
    OTP_EXPIRE_MINUTES: int = 10  # Thời gian hết hạn OTP (10 phút)
    OTP_LENGTH: int = 6  # Độ dài OTP (6 chữ số)
    
    class Config:
        env_file = ".env"  # Đọc từ file .env

settings = Settings()
```

**Giải thích**:

1. **BaseSettings**:
   - Pydantic class để validate cấu hình
   - Tự động đọc từ environment variables hoặc file .env

2. **SECRET_KEY**:
   - **QUAN TRỌNG**: Phải giữ bí mật!
   - Dùng để ký JWT token
   - Nếu lộ → Kẻ tấn công có thể tạo token giả

3. **OTP_EXPIRE_MINUTES**:
   - Thời gian OTP có hiệu lực
   - Mặc định 10 phút (đủ thời gian để người dùng nhập)

4. **OTP_LENGTH**:
   - Độ dài OTP
   - Mặc định 6 chữ số (cân bằng giữa bảo mật và tiện lợi)

**File .env** (ví dụ):
```env
DATABASE_URL=postgresql://user:password@localhost/lms_db
SECRET_KEY=your-super-secret-key-here-change-in-production
SMTP_EMAIL=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

---

## 5. FRONTEND - LOGIN PAGE

### 5.1. File: `lms_frontend/src/pages/Login.tsx`

File này chứa giao diện và logic đăng nhập.

#### a) Import và State

```typescript
import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { useNavigate } from 'react-router-dom';

const Login: React.FC = () => {
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const { login } = useAuth();
    const navigate = useNavigate();
```

**Giải thích**:
- `useState`: Quản lý state của component
- `useAuth`: Hook để truy cập AuthContext
- `useNavigate`: Hook để điều hướng trang

#### b) Hàm xử lý submit

```typescript
const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
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

        const data = response.data;

        // Kiểm tra xem có cần OTP không
        if (data.requires_otp) {
            // Chuyển hướng đến trang xác thực OTP
            navigate('/verify-otp', {
                state: {
                    username: username,
                    emailHint: data.email_hint || '',
                    message: data.message || 'OTP đã được gửi đến email của bạn'
                }
            });
        } else {
            // Đăng nhập bình thường (không cần OTP)
            const { access_token, role } = data;
            login(access_token, { username, role });
            navigate('/dashboard');
        }
    } catch (err: any) {
        setError(err.response?.data?.detail || 'Tên đăng nhập hoặc mật khẩu không đúng');
        console.error(err);
    } finally {
        setIsLoading(false);
    }
};
```

**Giải thích**:

1. **URLSearchParams**:
   - Tạo form data dạng `username=xxx&password=yyy`
   - Phù hợp với OAuth2PasswordRequestForm

2. **Kiểm tra requires_otp**:
   - Nếu `requires_otp === true` → Chuyển đến trang OTP
   - Nếu không → Đăng nhập ngay

3. **Error Handling**:
   - Catch lỗi và hiển thị thông báo
   - `err.response?.data?.detail`: Lấy thông báo lỗi từ backend

---

## 6. FRONTEND - OTP VERIFICATION PAGE

### 6.1. File: `lms_frontend/src/pages/OtpVerify.tsx`

File này chứa giao diện và logic xác thực OTP.

#### a) State và khởi tạo

```typescript
const [otp, setOtp] = useState('');
const [error, setError] = useState('');
const [isLoading, setIsLoading] = useState(false);
const [otpMessage, setOtpMessage] = useState('');
const [resendCooldown, setResendCooldown] = useState(60);
const [username, setUsername] = useState('');
const [emailHint, setEmailHint] = useState('');
```

**Giải thích**:
- `otp`: Mã OTP người dùng nhập
- `resendCooldown`: Thời gian chờ trước khi có thể gửi lại OTP (60 giây)

#### b) Khởi tạo từ state hoặc sessionStorage

```typescript
useEffect(() => {
    const state = location.state as LocationState | null;

    if (state?.username) {
        setUsername(state.username);
        setEmailHint(state.emailHint || '');
        setOtpMessage(state.message || 'OTP đã được gửi đến email của bạn');
        // Lưu vào sessionStorage để giữ lại khi refresh trang
        sessionStorage.setItem('otp_username', state.username);
        sessionStorage.setItem('otp_emailHint', state.emailHint || '');
    } else {
        // Nếu không có state, thử lấy từ sessionStorage
        const savedUsername = sessionStorage.getItem('otp_username');
        const savedEmailHint = sessionStorage.getItem('otp_emailHint');

        if (savedUsername) {
            setUsername(savedUsername);
            setEmailHint(savedEmailHint || '');
            setOtpMessage('Vui lòng nhập mã OTP');
        } else {
            // Không có thông tin, quay lại trang đăng nhập
            navigate('/login', { replace: true });
        }
    }
}, []);
```

**Giải thích**:
- `useEffect`: Chạy khi component mount
- `sessionStorage`: Lưu trữ tạm thời (mất khi đóng tab)
- Nếu không có thông tin → Quay lại trang đăng nhập

#### c) Hàm xác thực OTP

```typescript
const handleOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    try {
        const response = await api.post('/auth/verify-otp', {
            username: username,
            otp: otp
        });

        const { access_token, role } = response.data;
        
        // Xóa thông tin tạm thời
        sessionStorage.removeItem('otp_username');
        sessionStorage.removeItem('otp_emailHint');
        
        // Đăng nhập thành công
        login(access_token, { username, role });
        navigate('/dashboard');
    } catch (err: any) {
        const errorMessage = err.response?.data?.detail || 'Mã OTP không hợp lệ';
        setError(errorMessage);
        setOtp('');  // Xóa OTP đã nhập
    } finally {
        setIsLoading(false);
    }
};
```

**Giải thích**:
- Gửi username và OTP đến backend
- Nếu thành công → Lưu token và chuyển đến dashboard
- Nếu thất bại → Hiển thị lỗi và xóa OTP đã nhập

#### d) Hàm gửi lại OTP

```typescript
const handleResendOtp = async () => {
    if (resendCooldown > 0) return;  // Đang trong thời gian chờ

    setError('');
    setIsLoading(true);

    try {
        const response = await api.post('/auth/resend-otp', new URLSearchParams({
            username: username,
        }), {
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        });

        setOtpMessage(response.data.message || 'OTP mới đã được gửi');
        setResendCooldown(60);  // Reset cooldown
        setOtp('');
        setError('');
    } catch (err: any) {
        setError(err.response?.data?.detail || 'Không thể gửi lại OTP');
    } finally {
        setIsLoading(false);
    }
};
```

**Giải thích**:
- Kiểm tra cooldown trước khi gửi lại
- Gửi request đến `/auth/resend-otp`
- Reset cooldown về 60 giây

#### e) Cooldown timer

```typescript
useEffect(() => {
    if (resendCooldown > 0) {
        const timer = setTimeout(() => setResendCooldown(resendCooldown - 1), 1000);
        return () => clearTimeout(timer);
    }
}, [resendCooldown]);
```

**Giải thích**:
- Mỗi giây giảm `resendCooldown` đi 1
- Hiển thị "Gửi lại (59s)", "Gửi lại (58s)", ...
- Khi về 0 → Có thể gửi lại

---

## 7. FRONTEND - AUTH CONTEXT

### 7.1. File: `lms_frontend/src/context/AuthContext.tsx`

File này quản lý trạng thái đăng nhập toàn cục.

```typescript
import React, { createContext, useContext, useState, useEffect } from 'react';

interface AuthContextType {
    token: string | null;
    user: any | null;
    login: (token: string, user: any) => void;
    logout: () => void;
    isAuthenticated: boolean;
    isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [token, setToken] = useState<string | null>(localStorage.getItem('token'));
    const [user, setUser] = useState<any | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    // Khôi phục token từ localStorage khi app khởi động
    useEffect(() => {
        const storedToken = localStorage.getItem('token');
        const storedUser = localStorage.getItem('user');
        if (storedToken) {
            setToken(storedToken);
            if (storedUser) setUser(JSON.parse(storedUser));
        }
        setIsLoading(false);
    }, []);

    const login = (newToken: string, newUser: any) => {
        localStorage.setItem('token', newToken);
        localStorage.setItem('user', JSON.stringify(newUser));
        setToken(newToken);
        setUser(newUser);
    };

    const logout = () => {
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        setToken(null);
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ 
            token, 
            user, 
            login, 
            logout, 
            isAuthenticated: !!token, 
            isLoading 
        }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};
```

**Giải thích**:

1. **Context API**:
   - Tạo context để chia sẻ state giữa các component
   - Không cần truyền props qua nhiều cấp

2. **localStorage**:
   - Lưu token và user info
   - Giữ lại khi refresh trang

3. **useAuth Hook**:
   - Hook tùy chỉnh để dùng AuthContext
   - Đảm bảo chỉ dùng trong AuthProvider

---

## 8. FRONTEND - API SERVICE

### 8.1. File: `lms_frontend/src/services/api.ts`

File này cấu hình axios và interceptors.

```typescript
import axios from 'axios';

const api = axios.create({
    baseURL: 'http://localhost:8000',
    headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
    },
});

// Request interceptor: Tự động thêm JWT token vào header
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

// Response interceptor: Xử lý lỗi 401 (unauthorized)
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            // Token hết hạn hoặc không hợp lệ
            localStorage.removeItem('token');
            window.location.href = '/login';
        }
        return Promise.reject(error);
    }
);

export default api;
```

**Giải thích**:

1. **Request Interceptor**:
   - Tự động thêm `Authorization: Bearer <token>` vào mọi request
   - Không cần thêm thủ công mỗi lần gọi API

2. **Response Interceptor**:
   - Nếu nhận 401 → Token không hợp lệ
   - Xóa token và chuyển đến trang đăng nhập

---

## 9. DATABASE MODELS

### 9.1. File: `lms_backend/app/models/user.py`

```python
from sqlalchemy import Column, Integer, String, Enum, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
from app.models.enums import UserRole

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)  # Dùng để gửi OTP
    hashed_password = Column(String, nullable=False)
    role = Column(Enum(UserRole), nullable=False)  # DEAN, LECTURER, STUDENT
    full_name = Column(String)
    phone_number = Column(String)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    student = relationship("Student", uselist=False, back_populates="user")
    lecturer = relationship("Lecturer", uselist=False, back_populates="user")
```

**Giải thích**:

1. **email**: 
   - Unique và indexed
   - Dùng để gửi OTP

2. **role**: 
   - Enum: DEAN, LECTURER, STUDENT
   - Chỉ DEAN cần OTP

3. **is_active**: 
   - Có thể vô hiệu hóa tài khoản
   - Nếu False → Không thể đăng nhập

---

## 10. TỔNG HỢP VÀ BEST PRACTICES

### 10.1. Tổng hợp các file

| File | Chức năng | Vị trí |
|------|-----------|--------|
| `auth.py` | Router xử lý đăng nhập và OTP | `lms_backend/app/routers/` |
| `otp_service.py` | Tạo, lưu, xác thực OTP, gửi email | `lms_backend/app/services/` |
| `security.py` | Hash password, JWT token | `lms_backend/app/auth/` |
| `config.py` | Cấu hình hệ thống | `lms_backend/app/core/` |
| `Login.tsx` | Giao diện đăng nhập | `lms_frontend/src/pages/` |
| `OtpVerify.tsx` | Giao diện xác thực OTP | `lms_frontend/src/pages/` |
| `AuthContext.tsx` | Quản lý trạng thái đăng nhập | `lms_frontend/src/context/` |
| `api.ts` | Cấu hình axios | `lms_frontend/src/services/` |

### 10.2. Best Practices

#### a) Bảo mật

1. ✅ **Mật khẩu được hash bằng bcrypt**
2. ✅ **OTP có thời gian hết hạn (10 phút)**
3. ✅ **Giới hạn số lần thử OTP (10 lần)**
4. ✅ **OTP chỉ dùng được 1 lần**
5. ✅ **JWT token có thời gian hết hạn (30 phút)**
6. ✅ **Email được mã hóa khi gửi (TLS)**

#### b) User Experience

1. ✅ **Hiển thị email hint (ẩn một phần)**
2. ✅ **Thông báo rõ ràng khi cần OTP**
3. ✅ **Cooldown khi gửi lại OTP (60 giây)**
4. ✅ **Lưu thông tin vào sessionStorage (giữ lại khi refresh)**
5. ✅ **Hiển thị số lần thử còn lại**

#### c) Code Quality

1. ✅ **Tách biệt concerns (router, service, security)**
2. ✅ **Error handling đầy đủ**
3. ✅ **Type hints và TypeScript**
4. ✅ **Comments và docstrings**

### 10.3. Cải thiện có thể thực hiện

1. **Lưu OTP trong Redis thay vì memory**:
   - OTP không bị mất khi server restart
   - Có thể scale horizontal

2. **Rate limiting**:
   - Giới hạn số lần đăng nhập trong một khoảng thời gian
   - Chống brute-force attack

3. **Audit logging**:
   - Ghi log mọi lần đăng nhập
   - Theo dõi các hoạt động đáng ngờ

4. **Email template**:
   - Tách email template ra file riêng
   - Dễ chỉnh sửa và maintain

---

## TÓM TẮT PHẦN 3

Trong phần này, chúng ta đã tìm hiểu **CODE IMPLEMENTATION CHI TIẾT**:

1. ✅ **Backend Router**: Xử lý đăng nhập, xác thực OTP, gửi lại OTP
2. ✅ **OTP Service**: Tạo, lưu, xác thực OTP, gửi email
3. ✅ **Security Module**: Hash password, JWT token
4. ✅ **Configuration**: Cấu hình hệ thống
5. ✅ **Frontend Pages**: Login và OTP verification
6. ✅ **Auth Context**: Quản lý trạng thái đăng nhập
7. ✅ **API Service**: Cấu hình axios và interceptors
8. ✅ **Database Models**: Cấu trúc dữ liệu user

**Tiếp theo**: Phần 4 sẽ giải thích **CƠ CHẾ BẢO MẬT VÀ CÁC LỚP BẢO VỆ**.

---

**📄 Xem tiếp**: `BAO_CAO_BAO_MAT_OTP_TRUONG_KHOA_PHAN_4_CO_CHE_BAO_MAT.md`




