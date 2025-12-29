# BÁO CÁO KỸ THUẬT JWT (JSON Web Token)

## MỤC LỤC

1. [Khái niệm JWT](#1-khái-niệm-jwt)
2. [Nguyên lý hoạt động của JWT](#2-nguyên-lý-hoạt-động-của-jwt)
3. [Triển khai JWT trong hệ thống LMS](#3-triển-khai-jwt-trong-hệ-thống-lms)
4. [Kết luận](#4-kết-luận)

---

## 1. KHÁI NIỆM JWT

### 1.1. Định nghĩa

**JWT (JSON Web Token)** là một chuẩn mở được định nghĩa trong RFC 7519, được sử dụng để truyền thông tin xác thực và ủy quyền giữa các thành phần của hệ thống một cách an toàn.

**Bản chất của JWT:**
- JWT là một chuỗi ký tự được mã hóa, chứa thông tin về người dùng dưới dạng JSON
- Token được ký bằng secret key (hoặc public/private key) để đảm bảo tính toàn vẹn và chống giả mạo
- Token có thể được truyền qua HTTP header, URL, hoặc POST body

**Tại sao gọi là "JSON Web Token"?**
- **JSON**: Dữ liệu bên trong token được lưu dưới dạng JSON
- **Web**: Được thiết kế để sử dụng trong các ứng dụng web
- **Token**: Là một "chứng chỉ" xác nhận danh tính người dùng

### 1.2. Đặc điểm chính

#### 1.2.1. Stateless (Không trạng thái)

**Khái niệm:**
- Server không cần lưu trữ session hay trạng thái đăng nhập của người dùng
- Mỗi request đều độc lập, không phụ thuộc vào request trước đó

**So sánh với Session-based:**
- **Session-based**: Server lưu session ID → Tra cứu session trong database/memory → Tốn tài nguyên
- **JWT**: Token chứa đầy đủ thông tin → Server chỉ cần verify token → Không cần lưu trữ

**Ưu điểm:**
- Tiết kiệm bộ nhớ server
- Dễ scale với nhiều server (không cần shared session store)
- Không cần query database mỗi request

#### 1.2.2. Self-contained (Tự chứa)

**Khái niệm:**
- Token chứa tất cả thông tin cần thiết để xác thực người dùng
- Không cần truy vấn database để lấy thông tin user (trừ khi cần thông tin đầy đủ)

**Thông tin trong token:**
- Username (sub)
- User ID
- Thời gian hết hạn (exp)
- Thời gian tạo (iat)
- Các thông tin khác tùy ứng dụng

**Lưu ý:**
- Không nên lưu thông tin nhạy cảm (mật khẩu, số thẻ tín dụng)
- Chỉ lưu thông tin tối thiểu cần thiết

#### 1.2.3. Compact (Nhỏ gọn)

**Khái niệm:**
- Token có kích thước nhỏ, dễ truyền tải
- Có thể truyền qua nhiều phương thức khác nhau

**Các cách truyền token:**
- **HTTP Header**: `Authorization: Bearer <token>` (phổ biến nhất)
- **URL Query Parameter**: `?token=<token>` (không khuyến khích vì có thể bị log)
- **POST Body**: Trong form data hoặc JSON body
- **Cookie**: Lưu trong cookie (cần cấu hình httpOnly để bảo mật)

**Kích thước:**
- Token thường dài 200-500 ký tự
- Nhỏ hơn nhiều so với việc gửi toàn bộ thông tin user mỗi request

#### 1.2.4. Secure (Bảo mật)

**Cơ chế bảo mật:**

1. **Signature (Chữ ký số):**
   - Token được ký bằng secret key (HS256) hoặc private key (RS256)
   - Không thể giả mạo nếu không có secret key
   - Nếu payload bị thay đổi, signature sẽ không khớp

2. **Expiration (Hết hạn):**
   - Token có thời gian hết hạn (thường 15-30 phút)
   - Tự động vô hiệu hóa sau một khoảng thời gian
   - Giảm thiểu rủi ro nếu token bị đánh cắp

3. **Algorithm (Thuật toán):**
   - HS256: Sử dụng secret key đối xứng (đơn giản, nhanh)
   - RS256: Sử dụng public/private key (phức tạp hơn, bảo mật hơn)

### 1.3. Vai trò trong hệ thống

#### 1.3.1. Xác thực (Authentication)

**Khái niệm:**
- Xác định người dùng là ai (Who are you?)
- Xác minh danh tính người dùng

**Cách JWT thực hiện:**
1. Người dùng đăng nhập với username/password
2. Server xác thực thông tin đăng nhập
3. Server tạo JWT token chứa thông tin user (username, user_id)
4. Client lưu token và gửi kèm mỗi request
5. Server verify token để xác định người dùng

**Ví dụ:**
- Token chứa `{"sub": "student001", "user_id": 5}`
- Server decode token → Biết đây là user "student001" với ID = 5

#### 1.3.2. Ủy quyền (Authorization)

**Khái niệm:**
- Xác định người dùng có quyền làm gì (What can you do?)
- Kiểm soát quyền truy cập tài nguyên

**Cách JWT thực hiện:**
1. Token có thể chứa thông tin về role/permissions
2. Server decode token để lấy thông tin role
3. Server kiểm tra role để quyết định cho phép hay từ chối

**Ví dụ trong hệ thống LMS:**
- Token chứa `{"sub": "dean001", "user_id": 1, "role": "dean"}`
- Server kiểm tra role → Nếu là "dean" → Cho phép truy cập các endpoint của Trưởng Khoa
- Nếu là "student" → Chỉ cho phép truy cập các endpoint của Sinh viên

#### 1.3.3. Trao đổi thông tin

**Khái niệm:**
- Truyền thông tin giữa client và server một cách an toàn
- Thông tin được mã hóa và ký số để đảm bảo tính toàn vẹn

**Cách sử dụng:**
- Client gửi token trong mỗi request
- Server decode token để lấy thông tin user
- Không cần gửi lại username/user_id trong mỗi request

---

### 1.4. Cấu trúc JWT

#### 1.4.1. Format tổng quan

JWT token có 3 phần, ngăn cách bởi dấu chấm (`.`):

```
header.payload.signature
```

**Ví dụ:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

#### 1.4.2. Header (Phần đầu)

**Chức năng:**
- Chứa metadata về token
- Mô tả cách token được mã hóa và loại token

**Các trường trong Header:**

1. **alg (Algorithm)**: Thuật toán mã hóa
   - `HS256`: HMAC với SHA-256 (sử dụng secret key đối xứng)
   - `RS256`: RSA với SHA-256 (sử dụng public/private key)
   - `ES256`: ECDSA với SHA-256
   - Hệ thống LMS sử dụng `HS256`

2. **typ (Type)**: Loại token
   - Luôn là `"JWT"` cho JSON Web Token
   - Có thể có các loại khác như `"JWE"` (JSON Web Encryption)

**Ví dụ Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Quy trình xử lý:**
1. Tạo JSON object chứa alg và typ
2. Mã hóa JSON thành Base64URL
3. Kết quả: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`

**Lưu ý:**
- Header chỉ chứa metadata, không chứa thông tin nhạy cảm
- Header có thể decode công khai (không cần secret key)

#### 1.4.3. Payload (Phần thân)

**Chức năng:**
- Chứa các claims (thông tin) về người dùng và token
- Đây là phần chứa dữ liệu thực tế

**Các loại Claims:**

1. **Registered Claims (Claims chuẩn):**
   - Được định nghĩa trong JWT specification
   - Các trường phổ biến:
     - `iss` (Issuer): Người phát hành token
     - `sub` (Subject): Chủ thể của token (thường là username)
     - `exp` (Expiration Time): Thời gian hết hạn (Unix timestamp)
     - `iat` (Issued At): Thời gian tạo token (Unix timestamp)
     - `nbf` (Not Before): Token không hợp lệ trước thời điểm này
     - `jti` (JWT ID): ID duy nhất của token

2. **Public Claims:**
   - Các trường công khai, có thể được định nghĩa bởi bất kỳ ai
   - Nên đăng ký trong IANA JWT Registry hoặc có namespace

3. **Private Claims:**
   - Các trường riêng của ứng dụng
   - Không xung đột với registered hoặc public claims

**Ví dụ Payload trong hệ thống LMS:**
```json
{
  "sub": "dean001",        // Subject (username) - Registered claim
  "user_id": 1,            // User ID - Private claim
  "exp": 1705324000,       // Expiration time - Registered claim
  "iat": 1705320400        // Issued at - Registered claim
}
```

**Quy trình xử lý:**
1. Tạo JSON object chứa các claims
2. Mã hóa JSON thành Base64URL
3. Kết quả: `eyJzdWIiOiJkZWFuMDAxIiwidXNlcl9pZCI6MSwiZXhwIjoxNzA1MzI0MDAwfQ`

**Lưu ý quan trọng:**
- ⚠️ Payload chỉ được mã hóa Base64URL, KHÔNG phải mã hóa (encryption)
- ⚠️ Bất kỳ ai cũng có thể decode payload để xem nội dung
- ✅ Không nên lưu thông tin nhạy cảm trong payload (mật khẩu, số thẻ tín dụng)
- ✅ Chỉ lưu thông tin tối thiểu cần thiết (username, user_id)

#### 1.4.4. Signature (Chữ ký)

**Chức năng:**
- Đảm bảo tính toàn vẹn của token
- Xác minh token không bị giả mạo hoặc thay đổi
- Xác nhận token được tạo bởi server có SECRET_KEY

**Cách tạo Signature:**

1. **Lấy header và payload đã encode:**
   ```
   encoded_header = base64UrlEncode(header)
   encoded_payload = base64UrlEncode(payload)
   ```

2. **Kết hợp với dấu chấm:**
   ```
   data = encoded_header + "." + encoded_payload
   ```

3. **Tạo signature bằng HMAC-SHA256:**
   ```
   signature = HMACSHA256(data, SECRET_KEY)
   ```

4. **Encode signature:**
   ```
   encoded_signature = base64UrlEncode(signature)
   ```

**Ví dụ cụ thể:**
```
Header (encoded):  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
Payload (encoded): eyJzdWIiOiJkZWFuMDAxIiwidXNlcl9pZCI6MSwiZXhwIjoxNzA1MzI0MDAwfQ
Data:              eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkZWFuMDAxIiwidXNlcl9pZCI6MSwiZXhwIjoxNzA1MzI0MDAwfQ
Signature:         HMACSHA256(data, SECRET_KEY)
Encoded Signature: SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Cách xác minh Signature:**

1. Server nhận token
2. Tách token thành 3 phần: `header.payload.signature`
3. Tạo lại signature từ header và payload với cùng SECRET_KEY
4. So sánh signature tạo lại với signature trong token
5. Nếu khớp → Token hợp lệ
6. Nếu không khớp → Token bị giả mạo hoặc bị thay đổi → Từ chối

**Mục đích của Signature:**
- ✅ **Chống giả mạo**: Không có SECRET_KEY thì không thể tạo signature đúng
- ✅ **Chống thay đổi**: Nếu payload bị sửa, signature sẽ không khớp
- ✅ **Xác minh nguồn gốc**: Chỉ server có SECRET_KEY mới tạo được token hợp lệ

**Lưu ý bảo mật:**
- SECRET_KEY phải được giữ bí mật
- Nếu SECRET_KEY bị lộ, hacker có thể tạo token giả mạo
- Nên sử dụng SECRET_KEY phức tạp, ngẫu nhiên

---

## 2. NGUYÊN LÝ HOẠT ĐỘNG CỦA JWT

### 2.1. Quy trình tạo JWT Token

**Bước 1: Thu thập thông tin**
- Server nhận username và password từ client
- Xác thực thông tin đăng nhập (kiểm tra database)
- Nếu hợp lệ, lấy thông tin user (username, user_id)

**Bước 2: Tạo Payload**
- Tạo dictionary chứa thông tin user:
  ```json
  {
    "sub": "username",      // Subject (username)
    "user_id": 5,            // User ID
    "exp": 1616239022        // Expiration time
  }
  ```

**Bước 3: Tạo Header**
- Header chứa metadata:
  ```json
  {
    "alg": "HS256",          // Thuật toán mã hóa
    "typ": "JWT"             // Loại token
  }
  ```

**Bước 4: Mã hóa Base64URL**
- Encode header thành Base64URL: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9`
- Encode payload thành Base64URL: `eyJzdWIiOiJ1c2VyMTIzIiwidXNlcl9pZCI6NSwiZXhwIjoxNjE2MjM5MDIyfQ`

**Bước 5: Tạo Signature**
- Sử dụng HMAC-SHA256:
  ```
  signature = HMACSHA256(
    base64UrlEncode(header) + "." + base64UrlEncode(payload),
    SECRET_KEY
  )
  ```
- Encode signature thành Base64URL

**Bước 6: Kết hợp**
- Kết hợp 3 phần: `header.payload.signature`
- Trả về JWT token cho client

### 2.2. Quy trình xác minh JWT Token

**Bước 1: Nhận token**
- Client gửi token trong header: `Authorization: Bearer <token>`
- Server extract token từ header

**Bước 2: Tách token**
- Tách token thành 3 phần: `header.payload.signature`

**Bước 3: Decode và kiểm tra Header**
- Decode header từ Base64URL
- Kiểm tra thuật toán (alg) có đúng không

**Bước 4: Tạo lại Signature**
- Decode header và payload
- Tạo lại signature với cùng SECRET_KEY
- So sánh với signature trong token
- Nếu khác → Token bị giả mạo → Từ chối

**Bước 5: Kiểm tra Expiration**
- Decode payload
- Kiểm tra `exp` (expiration time)
- Nếu đã hết hạn → Từ chối

**Bước 6: Lấy thông tin user**
- Lấy `sub` (username) từ payload
- Query database để lấy thông tin user đầy đủ
- Trả về User object

### 2.3. Luồng xác thực với JWT

```
┌──────────┐                    ┌──────────┐                    ┌──────────┐
│  Client  │                    │  Server  │                    │ Database │
└────┬─────┘                    └────┬─────┘                    └────┬─────┘
     │                               │                               │
     │ 1. POST /auth/login           │                               │
     │    {username, password}        │                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │                               │ 2. Verify credentials        │
     │                               ├──────────────────────────────►│
     │                               │                               │
     │                               │ 3. Create JWT token          │
     │                               │    (with user info)           │
     │                               │                               │
     │ 4. Return JWT token            │                               │
     │◄──────────────────────────────┤                               │
     │                               │                               │
     │ 5. Store token locally         │                               │
     │                               │                               │
     │ 6. Request with token          │                               │
     │    Authorization: Bearer <token>│                               │
     ├──────────────────────────────►│                               │
     │                               │                               │
     │                               │ 7. Verify token              │
     │                               │    (decode & check signature) │
     │                               │                               │
     │ 8. Return protected resource   │                               │
     │◄──────────────────────────────┤                               │
```

### 2.4. Tại sao JWT an toàn?

**Signature đảm bảo:**
- Token không thể bị giả mạo: Không có SECRET_KEY thì không thể tạo signature đúng
- Dữ liệu không bị thay đổi: Nếu payload bị sửa, signature sẽ không khớp
- Xác minh nguồn gốc: Chỉ server có SECRET_KEY mới tạo được token hợp lệ

**Expiration đảm bảo:**
- Token tự động hết hạn sau một khoảng thời gian
- Giảm thiểu rủi ro nếu token bị đánh cắp
- Buộc user phải đăng nhập lại định kỳ

---

## 3. TRIỂN KHAI JWT TRONG HỆ THỐNG LMS

### 3.1. Kiến trúc triển khai

Hệ thống LMS sử dụng JWT để xác thực người dùng trong các API endpoints. Kiến trúc bao gồm:

```
┌─────────────┐
│   Client    │ (Frontend/Mobile)
└──────┬──────┘
       │
       │ 1. POST /auth/login
       │    {username, password}
       ▼
┌─────────────────────────────────┐
│   FastAPI Backend                │
│                                  │
│  ┌──────────────────────────┐   │
│  │  /auth/login endpoint     │   │
│  │  - Verify credentials     │   │
│  │  - Create JWT token       │   │
│  └──────────────────────────┘   │
│                                  │
│  ┌──────────────────────────┐   │
│  │  Protected Endpoints      │   │
│  │  - /students/*            │   │
│  │  - /lecturers/*           │   │
│  │  - /chat/*                │   │
│  │  - Depends(get_current_user)│ │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
       │
       │ 2. GET /api/endpoint
       │    Authorization: Bearer <token>
       ▼
┌─────────────────────────────────┐
│  get_current_user()             │
│  - Extract token                │
│  - Verify signature             │
│  - Check expiration             │
│  - Return User object           │
└─────────────────────────────────┘
```

### 3.2. Cấu hình JWT

**File:** `lms_backend/app/core/config.py`

Hệ thống cấu hình JWT qua các biến môi trường:
- `SECRET_KEY`: Khóa bí mật để ký token (lưu trong `.env`, không commit vào Git)
- `ALGORITHM`: Thuật toán mã hóa (mặc định: "HS256")
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Thời gian hết hạn token (mặc định: 30 phút)

**Lưu ý bảo mật:**
- SECRET_KEY được lưu trong file `.env` (không có trong code)
- SECRET_KEY phải là chuỗi ngẫu nhiên, phức tạp
- Không được commit `.env` vào Git repository

### 3.3. Tạo JWT Token

**File:** `lms_backend/app/auth/security.py`

**Hàm `create_access_token()`:**
- **Input**: Dictionary chứa thông tin user (`{"sub": username, "user_id": id}`)
- **Process**:
  1. Copy dữ liệu đầu vào
  2. Tính thời gian hết hạn: `datetime.utcnow() + timedelta(minutes=30)`
  3. Thêm `exp` vào payload
  4. Mã hóa bằng `jwt.encode()` với SECRET_KEY và ALGORITHM
- **Output**: JWT token string

**Sử dụng trong:**
- `lms_backend/app/routers/auth.py`:
  - Sau khi xác thực username/password thành công (dòng 87-89)
  - Sau khi xác thực OTP thành công cho Trưởng Khoa (dòng 135-137)

**Ví dụ payload trong token:**
```json
{
  "sub": "dean001",        // Username
  "user_id": 1,            // User ID
  "exp": 1705324000        // Expiration (Unix timestamp)
}
```

### 3.4. Xác minh JWT Token

**File:** `lms_backend/app/auth/dependencies.py`

#### 3.4.1. Hàm `get_current_user()`

**Chức năng:**
- Xác minh JWT token và trả về User object
- Được sử dụng như một dependency trong FastAPI

**Input:**
- Token được extract tự động từ header `Authorization: Bearer <token>`
- FastAPI sử dụng `OAuth2PasswordBearer` để extract token

**Quy trình xử lý:**

1. **Extract token từ header:**
   - `OAuth2PasswordBearer` tự động tìm header `Authorization`
   - Lấy phần sau chữ "Bearer " (có khoảng trắng)
   - Nếu không có token → Raise exception 401

2. **Decode và verify token:**
   ```python
   payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
   ```
   - `jwt.decode()` tự động:
     - Kiểm tra format token (3 phần)
     - Decode header và payload
     - Verify signature (so sánh với SECRET_KEY)
     - Kiểm tra expiration (exp)
   - Nếu có lỗi → Raise JWTError

3. **Lấy username từ payload:**
   ```python
   username = payload.get("sub")
   ```
   - `sub` (subject) là field chuẩn trong JWT để lưu username
   - Nếu không có `sub` → Token không hợp lệ

4. **Query database để lấy User:**
   ```python
   user = get_user_by_username(db, username=username)
   ```
   - Tìm user trong database bằng username
   - Nếu không tìm thấy → User đã bị xóa hoặc không tồn tại

5. **Trả về User object:**
   - Nếu tất cả đều OK → Trả về User object
   - FastAPI truyền User object vào endpoint

**Output:**
- User object nếu token hợp lệ
- HTTPException 401 nếu token không hợp lệ

#### 3.4.2. Xử lý các trường hợp lỗi

**1. Token không có trong header:**
```python
# OAuth2PasswordBearer tự động raise exception
HTTPException(401, "Not authenticated")
```

**2. Token không hợp lệ (sai format):**
```python
# jwt.decode() raise JWTError
HTTPException(401, "Could not validate credentials")
```

**3. Token hết hạn:**
```python
# jwt.decode() tự động kiểm tra exp
# Nếu exp < current_time → Raise ExpiredSignatureError
HTTPException(401, "Could not validate credentials")
```

**4. Signature không khớp:**
```python
# jwt.decode() verify signature
# Nếu signature sai → Raise InvalidSignatureError
HTTPException(401, "Could not validate credentials")
```

**5. User không tồn tại:**
```python
# get_user_by_username() trả về None
HTTPException(401, "Could not validate credentials")
```

#### 3.4.3. OAuth2PasswordBearer

**Khái niệm:**
- Là một security scheme của FastAPI
- Tự động extract token từ header `Authorization: Bearer <token>`
- Tuân thủ chuẩn OAuth2

**Cách sử dụng:**
```python
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    # token đã được extract tự động
```

**Chức năng:**
- Tự động tìm header `Authorization`
- Kiểm tra format: `Bearer <token>`
- Extract phần token
- Nếu không có → Raise exception với thông báo yêu cầu authentication

### 3.5. Sử dụng trong API Endpoints

#### 3.5.1. Cơ chế Dependency Injection của FastAPI

**Khái niệm Dependency Injection:**
- FastAPI tự động inject dependencies vào các hàm endpoint
- Dependencies là các hàm được gọi trước khi endpoint được thực thi
- Kết quả của dependency được truyền vào endpoint như một tham số

**Cách hoạt động với JWT:**

1. **Khai báo dependency:**
   ```python
   @router.get("/students")
   def get_students(
       current_user: User = Depends(get_current_user)  # ← Dependency
   ):
       # current_user đã được xác thực
   ```

2. **FastAPI tự động thực hiện:**
   - Extract token từ header `Authorization: Bearer <token>`
   - Gọi hàm `get_current_user(token)` với token đã extract
   - `get_current_user()` verify token và trả về User object
   - Truyền User object vào tham số `current_user`
   - Nếu token không hợp lệ → `get_current_user()` raise exception → FastAPI trả về 401

3. **Lợi ích:**
   - Không cần viết code xác thực trong mỗi endpoint
   - Code sạch, dễ đọc, dễ bảo trì
   - Tự động xử lý lỗi authentication

#### 3.5.2. Ví dụ trong các router

**File:** `lms_backend/app/routers/students.py`

```python
@router.get("/students")
def get_students(
    current_user: User = Depends(get_current_user)  # ← Tự động xác thực
):
    # current_user đã được xác thực
    # Có thể sử dụng current_user.id, current_user.role, etc.
    # Không cần kiểm tra token thủ công
```

**Giải thích:**
- Khi client gửi `GET /students` với header `Authorization: Bearer <token>`
- FastAPI tự động gọi `get_current_user()` trước khi gọi `get_students()`
- Nếu token hợp lệ → `current_user` chứa User object
- Nếu token không hợp lệ → Trả về 401 Unauthorized, không gọi `get_students()`

**File:** `lms_backend/app/routers/chat.py`

- Tất cả endpoints đều sử dụng `Depends(get_current_user)`
- Đảm bảo chỉ user đã đăng nhập mới có thể truy cập
- Ví dụ: `GET /chat/groups`, `POST /chat/messages`, v.v.

**File:** `lms_backend/app/routers/lecturers.py`, `lms_backend/app/routers/deans.py`

- Tương tự, tất cả protected endpoints đều sử dụng JWT authentication
- Mỗi endpoint tự động có thông tin user đã xác thực

#### 3.5.3. So sánh với cách thủ công

**Cách thủ công (không dùng Dependency Injection):**
```python
@router.get("/students")
def get_students(request: Request):
    # Phải tự extract token
    token = request.headers.get("Authorization")
    if not token:
        raise HTTPException(401)
    
    # Phải tự verify token
    payload = jwt.decode(token, SECRET_KEY)
    user = get_user_by_username(payload["sub"])
    
    # Mới có thể sử dụng
    return students
```

**Cách với Dependency Injection:**
```python
@router.get("/students")
def get_students(current_user: User = Depends(get_current_user)):
    # current_user đã được xác thực tự động
    return students
```

**Ưu điểm:**
- Code ngắn gọn, dễ đọc
- Tái sử dụng logic xác thực
- Tự động xử lý lỗi
- Dễ test và maintain

### 3.6. Luồng hoạt động trong hệ thống

**Kịch bản 1: Đăng nhập thành công**

1. **Client** gửi `POST /auth/login` với username/password
2. **Server** (`auth.py`) xác thực credentials
3. **Server** gọi `create_access_token()` từ `security.py`
4. **Server** trả về JWT token cho client
5. **Client** lưu token (localStorage/sessionStorage)
6. **Client** sử dụng token trong các request tiếp theo

**Kịch bản 2: Truy cập protected endpoint**

1. **Client** gửi `GET /api/students` với header `Authorization: Bearer <token>`
2. **FastAPI** tự động extract token
3. **FastAPI** gọi `get_current_user()` từ `dependencies.py`
4. **get_current_user()** verify token:
   - Decode token
   - Kiểm tra signature
   - Kiểm tra expiration
   - Lấy username từ payload
   - Query database để lấy User object
5. **FastAPI** truyền User object vào endpoint
6. **Endpoint** xử lý request với thông tin user đã xác thực

**Kịch bản 3: Token hết hạn**

1. **Client** gửi request với token đã hết hạn
2. **get_current_user()** decode token → Phát hiện đã hết hạn
3. **get_current_user()** raise HTTPException 401
4. **Client** nhận 401 → Yêu cầu user đăng nhập lại

### 3.7. Tích hợp với OTP (Trưởng Khoa)

**File:** `lms_backend/app/routers/auth.py`

Đối với Trưởng Khoa, hệ thống yêu cầu 2 bước:
1. **Bước 1**: Xác thực username/password → Gửi OTP qua email
2. **Bước 2**: Xác thực OTP → Tạo JWT token

**Luồng:**
- Sau khi verify OTP thành công (dòng 111-123)
- Server gọi `create_access_token()` (dòng 135-137)
- Trả về JWT token giống như đăng nhập thông thường

### 3.8. Client-side Implementation

#### 3.8.1. Frontend (React/TypeScript)

**File:** `lms_frontend/src/services/api.ts`

**Chức năng:**

1. **Lưu trữ token:**
   - Sau khi đăng nhập thành công, nhận token từ response
   - Lưu token vào localStorage hoặc sessionStorage
   - localStorage: Token tồn tại đến khi user xóa
   - sessionStorage: Token chỉ tồn tại trong session hiện tại

2. **Tự động thêm token vào request:**
   - Sử dụng Axios Interceptor hoặc Fetch wrapper
   - Tự động thêm header `Authorization: Bearer <token>` vào mỗi request
   - Không cần thêm token thủ công cho từng request

3. **Xử lý lỗi token:**
   - Khi nhận response 401 (Unauthorized)
   - Token có thể đã hết hạn hoặc không hợp lệ
   - Xóa token cũ
   - Redirect user về trang đăng nhập

**Ví dụ luồng:**
```
Đăng nhập → Nhận token → Lưu localStorage → 
Mỗi request → Tự động thêm token → 
Nếu 401 → Xóa token → Redirect đăng nhập
```

#### 3.8.2. Mobile (Flutter/Dart)

**Chức năng:**

1. **Lưu trữ token:**
   - Sử dụng SharedPreferences để lưu token
   - Token được lưu local trên thiết bị
   - Tồn tại đến khi app bị gỡ hoặc user logout

2. **Tự động thêm token:**
   - Sử dụng Dio Interceptor
   - Interceptor tự động lấy token từ SharedPreferences
   - Thêm vào header `Authorization: Bearer <token>`
   - Chạy trước mỗi request

3. **Xử lý refresh token:**
   - Nếu có refresh token mechanism
   - Tự động refresh token khi access token hết hạn
   - Hoặc yêu cầu user đăng nhập lại

---

## 4. KẾT LUẬN

### 4.1. Tóm tắt

JWT là một công nghệ mạnh mẽ cho xác thực và ủy quyền trong các ứng dụng hiện đại:

- **Khái niệm**: Token tự chứa thông tin, được ký bằng secret key để đảm bảo tính toàn vẹn
- **Nguyên lý**: Stateless authentication - server không cần lưu trữ session, chỉ cần verify token
- **Triển khai**: Hệ thống LMS đã tích hợp JWT thành công với FastAPI và Dependency Injection

### 4.2. Ưu điểm của JWT trong hệ thống

- ✅ **Stateless**: Không cần lưu trữ session → Tiết kiệm bộ nhớ
- ✅ **Scalable**: Dễ mở rộng với nhiều server
- ✅ **Performance**: Không cần query database mỗi request (chỉ verify token)
- ✅ **Tích hợp dễ dàng**: FastAPI Dependency Injection tự động xử lý

### 4.3. Tổng hợp các file triển khai

**Cấu hình:**
- `lms_backend/app/core/config.py` - Cấu hình SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES

**Core functions:**
- `lms_backend/app/auth/security.py` - Hàm `create_access_token()` và `decode_access_token()`

**Authentication:**
- `lms_backend/app/auth/dependencies.py` - Hàm `get_current_user()` để xác minh token

**Endpoints:**
- `lms_backend/app/routers/auth.py` - Endpoint đăng nhập và tạo token
- `lms_backend/app/routers/students.py` - Protected endpoints sử dụng JWT
- `lms_backend/app/routers/lecturers.py` - Protected endpoints sử dụng JWT
- `lms_backend/app/routers/deans.py` - Protected endpoints sử dụng JWT
- `lms_backend/app/routers/chat.py` - Protected endpoints sử dụng JWT
- Các router khác - Tất cả đều sử dụng `Depends(get_current_user)`

---

---

## TÀI LIỆU THAM KHẢO

- [JWT.io](https://jwt.io/) - JWT Debugger và thông tin chi tiết
- [RFC 7519](https://tools.ietf.org/html/rfc7519) - JSON Web Token Specification
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/) - FastAPI JWT Tutorial

---

**Ngày tạo:** 2024  
**Phiên bản:** 1.0

