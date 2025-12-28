# HƯỚNG DẪN CHUYÊN SÂU VỀ BẢO MẬT CHAT - PHẦN 2: XÁC THỰC JWT TỪNG BƯỚC

## MỤC LỤC

1. [JWT là gì và tại sao cần nó?](#1-jwt-là-gì-và-tại-sao-cần-nó)
2. [Luồng đăng nhập và tạo JWT](#2-luồng-đăng-nhập-và-tạo-jwt)
3. [Cách tạo JWT token - Code chi tiết](#3-cách-tạo-jwt-token---code-chi-tiết)
4. [Cách sử dụng JWT trong REST API](#4-cách-sử-dụng-jwt-trong-rest-api)
5. [Cách client gửi JWT token](#5-cách-client-gửi-jwt-token)
6. [Cách xác minh JWT token](#6-cách-xác-minh-jwt-token)
7. [Ví dụ thực tế từng bước](#7-ví-dụ-thực-tế-từng-bước)

---

## 1. JWT LÀ GÌ VÀ TẠI SAO CẦN NÓ?

### 1.1. Vấn đề không có JWT

**Cách cũ (Session-based):**

```
Bước 1: User đăng nhập
  Username: "user123"
  Password: "pass123"
        ↓
Bước 2: Server tạo session
  Session ID: "abc123xyz"
  Lưu vào memory/database: 
    "abc123xyz" → user_id = 5
        ↓
Bước 3: User gửi request
  Cookie: session_id = "abc123xyz"
        ↓
Bước 4: Server kiểm tra
  Tra cứu: "abc123xyz" → user_id = 5
  "OK, bạn là user 5"
```

**Vấn đề:**
- Server phải lưu trữ session → Tốn bộ nhớ
- Nếu có nhiều server → Phải chia sẻ session → Phức tạp
- Mỗi request phải query database → Chậm

### 1.2. Giải pháp với JWT

**Cách mới (JWT-based):**

```
Bước 1: User đăng nhập
  Username: "user123"
  Password: "pass123"
        ↓
Bước 2: Server tạo JWT token
  Token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  (Chứa thông tin: user_id = 5)
        ↓
Bước 3: User gửi request
  Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
        ↓
Bước 4: Server xác minh token
  Giải mã token → Lấy user_id = 5
  "OK, bạn là user 5"
  (KHÔNG cần query database!)
```

**Ưu điểm:**
- ✅ Server không cần lưu trữ → Tiết kiệm bộ nhớ
- ✅ Có thể xác minh độc lập → Không cần database
- ✅ Dễ mở rộng → Nhiều server có thể xác minh cùng token

### 1.3. Cấu trúc JWT token

JWT token có 3 phần, ngăn cách bởi dấu chấm (.):

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
│──────────────────────││──────────────────────────────────────────││──────────────────────────│
        HEADER                  PAYLOAD (thông tin)                      SIGNATURE (chữ ký)
```

**HEADER (Phần đầu):**
- Chứa thông tin về thuật toán mã hóa
- Luôn là: `{"alg": "HS256", "typ": "JWT"}`

**PAYLOAD (Phần thông tin):**
- Chứa dữ liệu về user (user_id, username, thời gian hết hạn)
- Ví dụ: `{"sub": "user123", "user_id": 5, "exp": 1616239022}`

**SIGNATURE (Chữ ký):**
- Được tạo từ: `HMACSHA256(base64UrlEncode(header) + "." + base64UrlEncode(payload), secret)`
- Đảm bảo token không bị giả mạo

---

## 2. LUỒNG ĐĂNG NHẬP VÀ TẠO JWT

### 2.1. Sơ đồ luồng

```
┌──────────┐                    ┌──────────┐                    ┌──────────┐
│  Client  │                    │  Server  │                    │ Database │
└────┬─────┘                    └────┬─────┘                    └────┬─────┘
     │                               │                               │
     │ 1. POST /auth/login           │                               │
     │    {username, password}        │                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │                               │ 2. Query user                 │
     │                               ├──────────────────────────────►│
     │                               │                               │
     │                               │ 3. Check password             │
     │                               │    (bcrypt.compare)           │
     │                               │                               │
     │                               │ 4. User found & password OK   │
     │                               │◄──────────────────────────────┤
     │                               │                               │
     │                               │ 5. Create JWT token           │
     │                               │    create_access_token()      │
     │                               │                               │
     │ 6. Return JWT token            │                               │
     │◄──────────────────────────────┤                               │
     │                               │                               │
     │ 7. Save token to Secure       │                               │
     │    Storage                     │                               │
```

### 2.2. Ví dụ request/response

**Request (Client gửi):**
```http
POST /auth/login HTTP/1.1
Host: localhost:8000
Content-Type: application/json

{
  "username": "nguyenvana",
  "password": "mypassword123"
}
```

**Response (Server trả về):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
  "token_type": "bearer"
}
```

---

## 3. CÁCH TẠO JWT TOKEN - CODE CHI TIẾT

### 3.1. File: `lms_backend/app/auth/security.py`

Hãy xem code từng dòng một:

```python
# Import các thư viện cần thiết
from datetime import datetime, timedelta  # Để xử lý thời gian
from typing import Optional  # Để type hint
from jose import JWTError, jwt  # Thư viện JWT
import bcrypt  # Để hash password
from app.core.config import settings  # Cấu hình (SECRET_KEY, etc.)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Tạo JWT access token
    
    Hàm này nhận vào:
    - data: Dictionary chứa thông tin user (ví dụ: {"sub": "username", "user_id": 5})
    - expires_delta: Thời gian hết hạn (tùy chọn, mặc định 30 phút)
    
    Trả về:
    - JWT token dạng string
    """
    
    # BƯỚC 1: Copy dữ liệu đầu vào
    # Tại sao copy? Để không làm thay đổi dictionary gốc
    to_encode = data.copy()
    # Ví dụ: to_encode = {"sub": "nguyenvana", "user_id": 5}
    
    # BƯỚC 2: Thiết lập thời gian hết hạn
    if expires_delta:
        # Nếu có chỉ định thời gian hết hạn
        expire = datetime.utcnow() + expires_delta
    else:
        # Mặc định: 30 phút từ bây giờ
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Ví dụ: 
    # datetime.utcnow() = 2024-01-15 10:00:00
    # expire = 2024-01-15 10:30:00 (30 phút sau)
    
    # BƯỚC 3: Thêm thời gian hết hạn vào payload
    to_encode.update({"exp": expire})
    # Bây giờ: to_encode = {
    #   "sub": "nguyenvana", 
    #   "user_id": 5, 
    #   "exp": 2024-01-15 10:30:00
    # }
    
    # BƯỚC 4: Mã hóa thành JWT token
    encoded_jwt = jwt.encode(
        to_encode,              # Payload (dữ liệu cần mã hóa)
        settings.SECRET_KEY,    # Secret key (bí mật, chỉ server biết)
        algorithm=settings.ALGORITHM  # Thuật toán: "HS256"
    )
    
    # jwt.encode() sẽ:
    # 1. Tạo header: {"alg": "HS256", "typ": "JWT"}
    # 2. Encode header thành Base64: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
    # 3. Encode payload thành Base64: "eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ"
    # 4. Tạo signature: HMACSHA256(header + "." + payload, SECRET_KEY)
    # 5. Kết hợp: header + "." + payload + "." + signature
    
    # BƯỚC 5: Trả về token
    return encoded_jwt
    # Kết quả: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
```

### 3.2. Giải thích từng bước với ví dụ

**Input:**
```python
data = {
    "sub": "nguyenvana",  # Username
    "user_id": 5          # User ID
}
expires_delta = None  # Dùng mặc định (30 phút)
```

**Bước 1: Copy data**
```python
to_encode = {"sub": "nguyenvana", "user_id": 5}
```

**Bước 2: Tính thời gian hết hạn**
```python
# Giả sử bây giờ là: 2024-01-15 10:00:00
# settings.ACCESS_TOKEN_EXPIRE_MINUTES = 30
expire = datetime.utcnow() + timedelta(minutes=30)
# expire = 2024-01-15 10:30:00
```

**Bước 3: Thêm exp vào payload**
```python
to_encode.update({"exp": 2024-01-15 10:30:00})
# to_encode = {
#     "sub": "nguyenvana",
#     "user_id": 5,
#     "exp": 2024-01-15 10:30:00
# }
```

**Bước 4: Mã hóa**
```python
# jwt.encode() thực hiện:
# 1. Tạo header
header = {"alg": "HS256", "typ": "JWT"}
header_base64 = base64_encode(header)  # "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"

# 2. Encode payload
payload_base64 = base64_encode(to_encode)  # "eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ"

# 3. Tạo signature
signature = HMACSHA256(header_base64 + "." + payload_base64, SECRET_KEY)
signature_base64 = base64_encode(signature)  # "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"

# 4. Kết hợp
token = header_base64 + "." + payload_base64 + "." + signature_base64
```

**Output:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

### 3.3. Cấu hình SECRET_KEY

**File: `lms_backend/app/core/config.py`**

```python
class Settings(BaseSettings):
    # SECRET_KEY: Khóa bí mật để ký JWT token
    # ⚠️ QUAN TRỌNG: Phải giữ bí mật! Không được công khai!
    # Nếu ai đó biết SECRET_KEY, họ có thể tạo token giả mạo
    SECRET_KEY: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    
    # ALGORITHM: Thuật toán mã hóa
    # HS256 = HMAC với SHA-256
    ALGORITHM: str = "HS256"
    
    # ACCESS_TOKEN_EXPIRE_MINUTES: Thời gian hết hạn token (phút)
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

settings = Settings()
```

**Tại sao SECRET_KEY quan trọng?**
- SECRET_KEY được dùng để tạo signature
- Nếu hacker biết SECRET_KEY, họ có thể:
  - Tạo token giả mạo
  - Giả mạo bất kỳ user nào
  - Truy cập hệ thống trái phép

**Best practice:**
- ✅ Lưu SECRET_KEY trong biến môi trường (`.env`)
- ✅ Không commit SECRET_KEY vào Git
- ✅ Dùng SECRET_KEY phức tạp, ngẫu nhiên

---

## 4. CÁCH SỬ DỤNG JWT TRONG REST API

### 4.1. Dependency Injection trong FastAPI

FastAPI có cơ chế **Dependency Injection** - tự động inject dependencies vào hàm.

**File: `lms_backend/app/auth/dependencies.py`**

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from app.core.config import settings
from app.crud.user import get_user_by_username
from app.database import get_db
from app.schemas.user import TokenData
from app.models.user import User

# OAuth2PasswordBearer: Tự động extract token từ header
# tokenUrl: URL để lấy token (không quan trọng lắm, chỉ để documentation)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme),  # ← FastAPI tự động extract token từ header
    db: Session = Depends(get_db)         # ← FastAPI tự động tạo database session
) -> User:
    """
    Dependency function để xác thực user từ JWT token
    
    Hàm này được gọi TỰ ĐỘNG bởi FastAPI khi:
    - Có request đến endpoint có Depends(get_current_user)
    - FastAPI tự động extract token từ header "Authorization: Bearer <token>"
    - FastAPI tự động gọi hàm này và truyền token vào
    
    Quy trình:
    1. FastAPI extract token từ header
    2. Giải mã token để lấy username
    3. Tìm user trong database
    4. Trả về user object hoặc raise exception
    """
    
    # Tạo exception để throw nếu xác thực thất bại
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,  # 401 Unauthorized
        detail="Could not validate credentials",    # Thông báo lỗi
        headers={"WWW-Authenticate": "Bearer"},    # Header yêu cầu Bearer token
    )
    
    try:
        # BƯỚC 1: Giải mã token
        # jwt.decode() sẽ:
        # - Kiểm tra signature (có đúng không?)
        # - Kiểm tra expiration (có hết hạn chưa?)
        # - Trả về payload nếu hợp lệ
        payload = jwt.decode(
            token,                    # JWT token string
            settings.SECRET_KEY,      # Secret key để verify signature
            algorithms=[settings.ALGORITHM]  # Thuật toán: ["HS256"]
        )
        
        # payload = {
        #     "sub": "nguyenvana",
        #     "user_id": 5,
        #     "exp": 1616239022
        # }
        
        # BƯỚC 2: Lấy username từ payload
        # "sub" (subject) là field chuẩn trong JWT để lưu username
        username: str = payload.get("sub")
        
        if username is None:
            # Nếu không có username trong token → Token không hợp lệ
            raise credentials_exception
        
        # BƯỚC 3: Tạo TokenData object
        token_data = TokenData(username=username)
        
    except JWTError:
        # Nếu có lỗi khi decode (token không hợp lệ, đã hết hạn, signature sai)
        # → Throw exception
        raise credentials_exception
    
    # BƯỚC 4: Tìm user trong database
    # Query database để lấy thông tin user đầy đủ
    user = get_user_by_username(db, username=token_data.username)
    
    if user is None:
        # Nếu không tìm thấy user → Token có username không tồn tại
        raise credentials_exception
    
    # BƯỚC 5: Trả về user object
    # Nếu đến đây, nghĩa là:
    # - Token hợp lệ
    # - User tồn tại
    # → Trả về user object để sử dụng trong endpoint
    return user
```

### 4.2. Sử dụng trong Router

**File: `lms_backend/app/routers/chat.py`**

```python
from app.auth.dependencies import get_current_user

@router.get("/groups", response_model=List[ChatGroupResponse])
def get_chat_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)  # ← Đây là magic!
):
    """
    Lấy danh sách nhóm chat của user hiện tại
    
    Khi client gọi endpoint này:
    1. FastAPI tự động gọi get_current_user()
    2. get_current_user() extract token từ header
    3. get_current_user() xác minh token
    4. get_current_user() trả về User object
    5. FastAPI truyền User object vào current_user parameter
    6. Hàm này được gọi với current_user đã được xác thực
    """
    
    # Bây giờ current_user đã được xác thực, có thể sử dụng an toàn
    # current_user.id = 5 (từ token)
    # current_user.role = "lecturer" hoặc "student"
    
    # Lấy danh sách nhóm mà user này là thành viên
    memberships = db.query(ChatGroupMember).filter(
        ChatGroupMember.user_id == current_user.id  # ← Dùng user_id từ token
    ).all()
    
    # ... xử lý tiếp
```

### 4.3. Luồng xử lý chi tiết

```
┌─────────────────────────────────────────────────────────────────┐
│ CLIENT GỬI REQUEST                                              │
│ GET /chat/groups                                                │
│ Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...│
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ FASTAPI ROUTER NHẬN REQUEST                                     │
│ @router.get("/groups")                                           │
│ def get_chat_groups(..., current_user = Depends(get_current_user))│
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ FASTAPI TỰ ĐỘNG GỌI get_current_user()                         │
│ 1. OAuth2PasswordBearer extract token từ header                │
│    Token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."            │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ get_current_user() XỬ LÝ                                        │
│ 1. jwt.decode(token) → payload = {"sub": "nguyenvana", ...}   │
│ 2. username = payload.get("sub") = "nguyenvana"                │
│ 3. user = get_user_by_username(db, "nguyenvana")                │
│ 4. return user (User object)                                   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ FASTAPI TRUYỀN user VÀO current_user                            │
│ current_user = User(id=5, username="nguyenvana", ...)          │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ HÀM get_chat_groups() ĐƯỢC GỌI                                 │
│ Với current_user đã được xác thực                                │
│ Có thể sử dụng current_user.id, current_user.role, ...         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. CÁCH CLIENT GỬI JWT TOKEN

### 5.1. Lưu token sau khi đăng nhập

**File: `lms_mobile/lib/core/api_client.dart`**

Khi user đăng nhập thành công, token được lưu vào SharedPreferences:

```dart
// Sau khi đăng nhập thành công
final response = await dio.post('/auth/login', data: {
  'username': 'nguyenvana',
  'password': 'mypassword123'
});

// Lấy token từ response
final token = response.data['access_token'];
// token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// Lưu token vào SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('access_token', token);
```

### 5.2. Tự động thêm token vào mọi request

**File: `lms_mobile/lib/core/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiClient() {
    // Thêm interceptor - đây là "middleware" của Dio
    // Interceptor chạy TỰ ĐỘNG trước mỗi request
    _dio.interceptors.add(
      InterceptorsWrapper(
        // onRequest: Chạy trước khi gửi request
        onRequest: (options, handler) async {
          // BƯỚC 1: Lấy token từ SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          // token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." hoặc null

          // BƯỚC 2: Nếu có token, thêm vào header
          if (token != null) {
            // Thêm Authorization header
            options.headers['Authorization'] = 'Bearer $token';
            // Header sẽ là: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
          }

          // BƯỚC 3: Tiếp tục xử lý request
          return handler.next(options);
        },
      ),
    );
  }

  Dio get client => _dio;
}
```

### 5.3. Ví dụ sử dụng

```dart
// Tạo ApiClient
final apiClient = ApiClient();

// Gọi API - token được tự động thêm vào header!
final response = await apiClient.client.get('/chat/groups');
// Request sẽ có header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

// Không cần thêm token thủ công!
```

---

## 6. CÁCH XÁC MINH JWT TOKEN

### 6.1. Hàm decode_access_token

**File: `lms_backend/app/auth/security.py`**

```python
def decode_access_token(token: str):
    """
    Giải mã và xác minh JWT token
    
    Hàm này:
    1. Giải mã token
    2. Kiểm tra signature (có đúng không?)
    3. Kiểm tra expiration (có hết hạn chưa?)
    4. Trả về payload nếu hợp lệ, None nếu không hợp lệ
    """
    try:
        # jwt.decode() thực hiện:
        # 1. Tách token thành 3 phần: header.payload.signature
        # 2. Decode header và payload từ Base64
        # 3. Tạo lại signature từ header + payload + SECRET_KEY
        # 4. So sánh signature tạo lại với signature trong token
        #    - Nếu khác → Token bị giả mạo → Raise exception
        # 5. Kiểm tra exp (expiration)
        #    - Nếu đã hết hạn → Raise exception
        # 6. Trả về payload nếu tất cả đều OK
        
        payload = jwt.decode(
            token,                    # Token cần xác minh
            settings.SECRET_KEY,      # Secret key để verify
            algorithms=[settings.ALGORITHM]  # Thuật toán
        )
        
        # Nếu đến đây, token hợp lệ
        return payload
        # payload = {
        #     "sub": "nguyenvana",
        #     "user_id": 5,
        #     "exp": 1616239022
        # }
        
    except JWTError:
        # Nếu có lỗi (token không hợp lệ, đã hết hạn, signature sai)
        # → Trả về None
        return None
```

### 6.2. Các trường hợp lỗi

**Trường hợp 1: Token không hợp lệ (sai format)**
```python
token = "invalid_token"
payload = decode_access_token(token)
# → None (JWTError: Invalid token format)
```

**Trường hợp 2: Token đã hết hạn**
```python
# Token có exp = 1616239022 (đã qua)
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
payload = decode_access_token(token)
# → None (JWTError: Token expired)
```

**Trường hợp 3: Signature sai (token bị giả mạo)**
```python
# Hacker tạo token với SECRET_KEY khác
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."  # Signature sai
payload = decode_access_token(token)
# → None (JWTError: Signature verification failed)
```

**Trường hợp 4: Token hợp lệ**
```python
# Token được tạo bởi server với đúng SECRET_KEY, chưa hết hạn
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
payload = decode_access_token(token)
# → {"sub": "nguyenvana", "user_id": 5, "exp": 1616239022}
```

---

## 7. VÍ DỤ THỰC TẾ TỪNG BƯỚC

### 7.1. Kịch bản: User đăng nhập và lấy danh sách nhóm chat

**Bước 1: User đăng nhập**

```dart
// Client (Flutter)
final response = await dio.post('http://localhost:8000/auth/login', data: {
  'username': 'nguyenvana',
  'password': 'mypassword123'
});

// Response:
// {
//   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJuZ3V5ZW52YW5hIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
//   "token_type": "bearer"
// }

// Lưu token
final prefs = await SharedPreferences.getInstance();
await prefs.setString('access_token', response.data['access_token']);
```

**Bước 2: User gọi API lấy danh sách nhóm**

```dart
// Client (Flutter)
final apiClient = ApiClient();
final response = await apiClient.client.get('/chat/groups');

// ApiClient tự động:
// 1. Lấy token từ SharedPreferences
// 2. Thêm vào header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
// 3. Gửi request
```

**Bước 3: Server nhận request**

```python
# Server (FastAPI)
# Request đến: GET /chat/groups
# Header: Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

@router.get("/groups")
def get_chat_groups(
    current_user: User = Depends(get_current_user)  # ← FastAPI tự động gọi
):
    # FastAPI gọi get_current_user():
    # 1. Extract token từ header
    # 2. jwt.decode(token) → payload = {"sub": "nguyenvana", "user_id": 5, ...}
    # 3. get_user_by_username(db, "nguyenvana") → User object
    # 4. return User(id=5, username="nguyenvana", ...)
    
    # Bây giờ current_user = User(id=5, username="nguyenvana", ...)
    # Có thể sử dụng an toàn!
    
    memberships = db.query(ChatGroupMember).filter(
        ChatGroupMember.user_id == current_user.id  # ← Dùng user_id từ token
    ).all()
    
    return groups
```

**Bước 4: Server trả về response**

```json
[
  {
    "id": 1,
    "name": "Lớp Toán 101",
    "class_id": 10,
    "member_count": 25
  },
  {
    "id": 2,
    "name": "Lớp Lý 201",
    "class_id": 20,
    "member_count": 30
  }
]
```

### 7.2. Kịch bản: Token hết hạn

**Bước 1: User gọi API với token đã hết hạn**

```dart
// Client (Flutter)
// Token đã hết hạn (exp = 1616239022, hiện tại = 1616240000)
final response = await apiClient.client.get('/chat/groups');
// → Error: 401 Unauthorized
```

**Bước 2: Server xử lý**

```python
# Server (FastAPI)
# get_current_user() được gọi:
payload = jwt.decode(token, ...)
# → JWTError: Token expired

# get_current_user() raise exception:
raise HTTPException(
    status_code=401,
    detail="Could not validate credentials"
)
```

**Bước 3: Client nhận lỗi**

```dart
// Client nhận response:
// Status: 401 Unauthorized
// Body: {"detail": "Could not validate credentials"}

// Client cần:
// 1. Xóa token cũ
// 2. Yêu cầu user đăng nhập lại
```

---

## TÓM TẮT PHẦN 2

Trong phần này, bạn đã học được:

1. ✅ **JWT là gì** - Token chứa thông tin user, không cần lưu session
2. ✅ **Cách tạo JWT** - Sử dụng `jwt.encode()` với payload và SECRET_KEY
3. ✅ **Cách sử dụng JWT trong API** - Dependency Injection với `Depends(get_current_user)`
4. ✅ **Cách client gửi token** - Tự động thêm vào header qua Interceptor
5. ✅ **Cách xác minh token** - Sử dụng `jwt.decode()` để verify signature và expiration
6. ✅ **Ví dụ thực tế** - Luồng đăng nhập và sử dụng token

**Tiếp theo:** Phần 3 sẽ hướng dẫn chi tiết về mã hóa tin nhắn - cách mã hóa và giải mã với AES!

---

**📌 Lưu ý:** JWT token rất quan trọng! Phải:
- ✅ Giữ SECRET_KEY bí mật
- ✅ Kiểm tra expiration
- ✅ Lưu token an toàn trên client
- ✅ Xử lý lỗi khi token hết hạn

