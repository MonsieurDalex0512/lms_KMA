# PHÂN TÍCH CHI TIẾT BACKEND LMS MVP

## MỤC LỤC
1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Cấu trúc Database](#2-cấu-trúc-database)
3. [Hệ thống Authentication & Authorization](#3-hệ-thống-authentication--authorization)
4. [Luồng xử lý chính](#4-luồng-xử-lý-chính)
5. [Quản lý học tập (Academic Management)](#5-quản-lý-học-tập-academic-management)
6. [Tính toán điểm số (GPA/CPA)](#6-tính-toán-điểm-số-gpacpa)
7. [Quản lý học phí (Tuition Management)](#7-quản-lý-học-phí-tuition-management)
8. [API Endpoints](#8-api-endpoints)

---

## 1. TỔNG QUAN KIẾN TRÚC

### 1.1. Công nghệ sử dụng
- **Framework**: FastAPI (Python)
- **Database**: PostgreSQL
- **ORM**: SQLAlchemy
- **Authentication**: JWT (JSON Web Token) với OAuth2
- **Password Hashing**: bcrypt

### 1.2. Cấu trúc thư mục
```
lms_backend/
├── app/
│   ├── main.py              # Entry point, khởi tạo FastAPI app
│   ├── database.py           # Cấu hình database connection
│   ├── core/
│   │   └── config.py        # Cấu hình hệ thống (DB URL, SECRET_KEY, etc.)
│   ├── auth/
│   │   ├── security.py      # Bảo mật: hash password, tạo JWT token
│   │   └── dependencies.py   # Dependency injection cho authentication
│   ├── models/               # SQLAlchemy models (Database schema)
│   ├── schemas/              # Pydantic schemas (Request/Response validation)
│   ├── routers/              # API endpoints (routes)
│   ├── services/             # Business logic layer
│   ├── crud/                 # Database operations
│   └── utils/                # Utility functions
```

**Vị trí code**: `lms_backend/app/`

### 1.3. Kiến trúc phân lớp (Layered Architecture)

```
┌─────────────────────────────────────┐
│      Routers (API Endpoints)        │  ← HTTP requests/responses
├─────────────────────────────────────┤
│      Services (Business Logic)      │  ← Xử lý nghiệp vụ
├─────────────────────────────────────┤
│      CRUD (Data Access)             │  ← Truy vấn database
├─────────────────────────────────────┤
│      Models (Database Schema)       │  ← SQLAlchemy ORM
└─────────────────────────────────────┘
```

---

## 2. CẤU TRÚC DATABASE

### 2.1. Sơ đồ quan hệ (ERD)

#### **Bảng Users (Người dùng)**
**Vị trí**: `app/models/user.py:7-25`

```python
users
├── id (PK)
├── username (unique)
├── email (unique)
├── hashed_password
├── role (Enum: STUDENT, LECTURER, DEAN)
├── full_name
├── phone_number
├── is_active
└── created_at
```

**Quan hệ**:
- `1:1` với `students` (nếu role = STUDENT)
- `1:1` với `lecturers` (nếu role = LECTURER)

#### **Bảng Students (Sinh viên)**
**Vị trí**: `app/models/user.py:27-39`

```python
students
├── user_id (PK, FK → users.id)
├── student_code (unique)
└── department_id (FK → departments.id)
```

**Quan hệ**:
- `N:1` với `departments`
- `1:N` với `enrollments`
- `1:N` với `academic_results`
- `1:1` với `cumulative_results`
- `1:N` với `tuitions`

#### **Bảng Lecturers (Giảng viên)**
**Vị trí**: `app/models/user.py:41-50`

```python
lecturers
├── user_id (PK, FK → users.id)
├── lecturer_code (unique)
└── department_id (FK → departments.id)
```

**Quan hệ**:
- `N:1` với `departments`
- `1:N` với `classes`

#### **Bảng Departments (Khoa)**
**Vị trí**: `app/models/academic.py:5-13`

```python
departments
├── id (PK)
├── name (unique)
└── description
```

#### **Bảng Courses (Môn học)**
**Vị trí**: `app/models/academic.py:15-22`

```python
courses
├── id (PK)
├── code (unique)        # VD: "CS101"
├── name                # VD: "Lập trình Cơ bản"
└── credits             # Số tín chỉ
```

#### **Bảng Classes (Lớp học)**
**Vị trí**: `app/models/academic.py:24-45`

```python
classes
├── id (PK)
├── code (unique)        # VD: "CS101-01"
├── course_id (FK → courses.id)
├── lecturer_id (FK → lecturers.user_id)
├── semester            # Mã học kỳ: "20222"
├── max_students
├── start_week
├── end_week
├── day_of_week         # 2=Mon, 8=Sun
├── start_period
├── end_period
└── room
```

**Quan hệ**:
- `N:1` với `courses`
- `N:1` với `lecturers`
- `1:N` với `enrollments`
- `1:N` với `schedules`
- `1:N` với `timetables`

#### **Bảng Enrollments (Đăng ký học)**
**Vị trí**: `app/models/academic.py:59-67`

```python
enrollments
├── id (PK)
├── student_id (FK → students.user_id)
└── class_id (FK → classes.id)
```

**Quan hệ**:
- `N:1` với `students`
- `N:1` với `classes`
- `1:N` với `grades`

#### **Bảng Grades (Điểm số)**
**Vị trí**: `app/models/academic.py:70-79`

```python
grades
├── id (PK)
├── enrollment_id (FK → enrollments.id)
├── grade_type          # "midterm", "final", "lab", "assignment"
├── score               # Điểm thang 10
└── weight              # Trọng số (default 1.0)
```

#### **Bảng AcademicYears (Năm học)**
**Vị trí**: `app/models/academic_year.py:6-16`

```python
academic_years
├── id (PK)
├── year (unique)       # VD: "2022-2023"
├── start_date
├── end_date
├── is_active
└── is_deleted
```

#### **Bảng Semesters (Học kỳ)**
**Vị trí**: `app/models/academic_year.py:18-32`

```python
semesters
├── id (PK)
├── code (unique)       # VD: "20222" (2022 học kỳ 2)
├── name                # VD: "Học kỳ 2 năm học 2022-2023"
├── academic_year_id (FK → academic_years.id)
├── semester_number     # 1, 2, 3 (hè)
├── start_date
├── end_date
├── is_active
└── is_deleted
```

#### **Bảng AcademicResults (Kết quả học tập theo học kỳ)**
**Vị trí**: `app/models/academic_year.py:34-52`

```python
academic_results
├── id (PK)
├── student_id (FK → students.user_id)
├── semester_id (FK → semesters.id)
├── gpa                 # Điểm trung bình học kỳ (thang 4)
├── cpa                 # Điểm trung bình tích lũy (thang 4)
├── total_credits       # Tổng số tín chỉ đã đăng ký
├── completed_credits   # Số tín chỉ đã hoàn thành (>= 1.0)
├── failed_credits      # Số tín chỉ đã rớt (< 1.0)
├── cumulative_credits # Tổng tín chỉ tích lũy
└── calculated_at
```

#### **Bảng CumulativeResults (Kết quả tích lũy toàn khóa)**
**Vị trí**: `app/models/cumulative_result.py:6-21`

```python
cumulative_results
├── id (PK)
├── student_id (FK → students.user_id, unique)
├── cpa                 # CPA tích lũy
├── total_registered_credits
├── total_completed_credits
├── total_failed_credits
└── updated_at
```

#### **Bảng Timetables (Thời khóa biểu chi tiết)**
**Vị trí**: `app/models/timetable.py:5-17`

```python
timetables
├── id (PK)
├── class_id (FK → classes.id)
├── date                # Ngày cụ thể
├── start_period
├── end_period
├── room
├── is_makeup           # Là buổi học bù
└── note
```

#### **Bảng Tuitions (Học phí)**
**Vị trí**: `app/models/tuition.py:5-15`

```python
tuitions
├── id (PK)
├── student_id (FK → students.user_id)
├── semester            # Mã học kỳ
├── total_amount        # Tổng số tiền phải đóng
├── paid_amount         # Số tiền đã đóng
└── status              # PENDING, PARTIAL, COMPLETED
```

#### **Bảng Reports (Báo cáo/Khiếu nại)**
**Vị trí**: `app/models/report.py:19-35`

```python
reports
├── id (PK)
├── student_id (FK → students.user_id)
├── title
├── description
├── report_type         # ACADEMIC, ADMINISTRATIVE, TECHNICAL, OTHER
├── status              # PENDING, PROCESSING, RESOLVED, REJECTED
├── dean_response
├── created_at
├── updated_at
├── resolved_at
└── resolved_by (FK → users.id)
```

### 2.2. Quan hệ giữa các bảng

```
users
├── students (1:1)
│   ├── enrollments (1:N)
│   │   └── grades (1:N)
│   ├── academic_results (1:N)
│   ├── cumulative_results (1:1)
│   └── tuitions (1:N)
└── lecturers (1:1)
    └── classes (1:N)
        ├── enrollments (1:N)
        └── timetables (1:N)

academic_years
└── semesters (1:N)
    └── academic_results (1:N)

departments
├── students (1:N)
└── lecturers (1:N)

courses
└── classes (1:N)
```

---

## 3. HỆ THỐNG AUTHENTICATION & AUTHORIZATION

### 3.1. Authentication Flow

#### **Bước 1: Đăng ký (Register)**
**Vị trí**: `app/routers/auth.py:17-27`

```python
POST /auth/register
Body: {
    "username": "student1",
    "email": "student1@example.com",
    "password": "password123",
    "role": "student",
    "full_name": "Nguyễn Văn A",
    "phone_number": "0123456789"
}
```

**Luồng xử lý**:
1. Router nhận request → `app/routers/auth.py:18`
2. Kiểm tra username/email đã tồn tại → `app/crud/user.py:6-10`
3. Hash password → `app/auth/security.py:14-17` (sử dụng bcrypt)
4. Tạo User record → `app/crud/user.py:12-25`
5. Trả về User object (không có password)

#### **Bước 2: Đăng nhập (Login)**
**Vị trí**: `app/routers/auth.py:29-45`

```python
POST /auth/login
Form Data:
    username: "student1"
    password: "password123"
```

**Luồng xử lý**:
1. Router nhận credentials → `app/routers/auth.py:30-32`
2. Tìm user theo username → `app/crud/user.py:6-7`
3. Verify password → `app/auth/security.py:7-12` (bcrypt.checkpw)
4. Tạo JWT token → `app/auth/security.py:19-27`
   - Payload: `{"sub": username, "exp": expiry_time}`
   - Algorithm: HS256
   - Expiry: 30 phút (mặc định)
5. Trả về: `{access_token, token_type: "bearer", role}`

#### **Bước 3: Sử dụng Token**
**Vị trí**: `app/auth/dependencies.py:13-30`

Mỗi request cần authentication sẽ:
1. Extract token từ header: `Authorization: Bearer <token>`
2. Decode JWT → `app/auth/dependencies.py:20`
3. Lấy username từ payload
4. Query user từ database → `app/crud/user.py:6-7`
5. Trả về `current_user` object

**Dependency injection**:
```python
@router.get("/students/me")
def get_profile(current_user: User = Depends(get_current_active_user)):
    # current_user đã được inject tự động
    return current_user
```

### 3.2. Authorization (Phân quyền)

**Vị trí**: `app/models/enums.py:3-7`

Có 3 roles:
- **STUDENT**: Sinh viên
- **LECTURER**: Giảng viên
- **DEAN**: Trưởng khoa (admin)

**Kiểm tra quyền**:
- **Vị trí**: `app/routers/deans.py:99-102`
```python
def check_dean_role(user: User):
    if user.role != UserRole.DEAN:
        raise HTTPException(status_code=403, detail="Not authorized")
```

- **Vị trí**: `app/routers/students.py:20-21`
```python
if current_user.role != UserRole.STUDENT:
    raise HTTPException(status_code=403, detail="Not authorized")
```

### 3.3. Password Security

**Vị trí**: `app/auth/security.py:7-17`

- **Hash password**: Sử dụng bcrypt với salt tự động
- **Verify password**: `bcrypt.checkpw(plain, hashed)`
- **Lưu ý**: Password được encode UTF-8 trước khi hash

---

## 4. LUỒNG XỬ LÝ CHÍNH

### 4.1. Luồng đăng ký học phần (Enrollment)

**Vị trí**: `app/routers/deans.py:421-471`

```python
POST /deans/classes/{class_id}/enrollments/bulk
Body: {
    "student_ids": [1, 2, 3]
}
```

**Luồng xử lý**:
1. **Kiểm tra quyền**: Dean only → `app/routers/deans.py:429`
2. **Kiểm tra lớp tồn tại**: Query `Class` → `app/routers/deans.py:435-437`
3. **Kiểm tra sức chứa**: 
   - Đếm enrollments hiện tại → `app/routers/deans.py:440`
   - So sánh với `max_students` → `app/routers/deans.py:441-442`
4. **Kiểm tra trùng lịch**: 
   - Gọi `class_service.check_schedule_conflict()` → `app/services/class_service.py:116-137`
   - So sánh `Timetable` của lớp mới với các lớp đã đăng ký
5. **Tạo enrollments**: Insert vào bảng `enrollments` → `app/routers/deans.py:458-460`
6. **Tính học phí tự động**: 
   - Gọi `tuition_service.calculate_tuition()` → `app/services/tuition_service.py:54-94`
   - Tính dựa trên số tín chỉ đã đăng ký

### 4.2. Luồng nhập điểm (Grading)

**Vị trí**: `app/routers/deans.py:483-511` và `app/routers/lecturers.py:63-88`

#### **Cách 1: Dean nhập điểm**
```python
PUT /deans/grades/{grade_id}
Body: {"score": 8.5}
```

**Luồng xử lý**:
1. Update `Grade.score` → `app/routers/deans.py:496-497`
2. **Tự động tính lại GPA/CPA**:
   - Lấy `enrollment` → `app/routers/deans.py:503`
   - Lấy `semester` từ `class.semester` → `app/routers/deans.py:505`
   - Gọi `calculate_and_save_semester_result()` → `app/utils/academic_calculator.py:195-245`
   - Hàm này sẽ:
     - Tính GPA cho học kỳ
     - Cập nhật `AcademicResult`
     - Tính lại CPA tích lũy → `update_cumulative_result()`

#### **Cách 2: Lecturer nhập điểm**
```python
POST /lecturers/grades
Body: {
    "class_id": 1,
    "student_id": 1,
    "midterm": 7.5,
    "final": 8.0
}
```

**Vị trí**: `app/services/lecturer_service.py` (cần kiểm tra file này)

### 4.3. Luồng tính toán GPA/CPA

**Vị trí**: `app/utils/academic_calculator.py`

#### **Bước 1: Tính điểm cuối cùng của môn học**
**Vị trí**: `app/utils/academic_calculator.py:36-54`

```python
def calculate_final_score(grades: List[Grade]) -> Optional[float]:
    # Ưu tiên lấy điểm 'final'
    # Nếu không có, lấy điểm đầu tiên
```

#### **Bước 2: Quy đổi điểm thang 10 → thang 4**
**Vị trí**: `app/utils/academic_calculator.py:20-34`

```python
GRADE_CONVERSION = [
    (8.5, 10.0, 4.0, "A"),
    (8.0, 8.4, 3.5, "B+"),
    (7.0, 7.9, 3.0, "B"),
    (6.5, 6.9, 2.5, "C+"),
    (5.5, 6.4, 2.0, "C"),
    (5.0, 5.4, 1.5, "D+"),
    (4.0, 4.9, 1.0, "D"),
    (0.0, 3.9, 0.0, "F"),
]
```

#### **Bước 3: Tính GPA học kỳ**
**Vị trí**: `app/utils/academic_calculator.py:56-112`

```python
def calculate_semester_gpa(student_id, semester_code, db):
    # 1. Lấy tất cả enrollments trong học kỳ
    # 2. Với mỗi enrollment:
    #    - Tính điểm cuối cùng (final_score_10)
    #    - Quy đổi sang thang 4
    #    - Tính: weighted_score = score_4 × credits
    # 3. GPA = Σ(weighted_score) / Σ(credits)
    # 4. Phân loại: completed_credits (>=1.0), failed_credits (<1.0)
```

**Công thức**:
```
GPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(số_tín_chỉ)
```

#### **Bước 4: Tính CPA tích lũy**
**Vị trí**: `app/utils/academic_calculator.py:114-157`

```python
def calculate_cumulative_cpa_from_courses(student_id, db):
    # Tính từ TẤT CẢ các môn học từ đầu khóa
    # CPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(tín_chỉ_đã_đăng_ký)
```

**Lưu ý**: CPA tính từ tất cả enrollments, không chỉ các môn đã có điểm.

#### **Bước 5: Lưu kết quả**
**Vị trí**: `app/utils/academic_calculator.py:195-245`

```python
def calculate_and_save_semester_result(student_id, semester_id, db):
    # 1. Tính GPA học kỳ
    # 2. Lưu vào AcademicResult
    # 3. Tính lại CPA tích lũy
    # 4. Lưu vào CumulativeResult
```

### 4.4. Luồng tạo thời khóa biểu (Timetable Generation)

**Vị trí**: `app/services/class_service.py:53-114`

```python
POST /deans/classes/{class_id}/timetable/generate
```

**Luồng xử lý**:
1. Lấy thông tin lớp và học kỳ → `app/services/class_service.py:54-60`
2. Xóa timetable cũ → `app/services/class_service.py:64`
3. Tính toán các buổi học:
   - Dựa vào `start_week`, `end_week`, `day_of_week`
   - Tính ngày cụ thể cho mỗi tuần → `app/services/class_service.py:97-101`
4. Tạo `Timetable` records cho từng buổi học → `app/services/class_service.py:103-110`
5. Lưu vào database

**Ví dụ**:
- Lớp học: Thứ 2, tuần 1-15, tiết 1-3
- Học kỳ bắt đầu: 2024-01-01
- → Tạo 15 records Timetable (mỗi thứ 2 trong 15 tuần)

---

## 5. QUẢN LÝ HỌC TẬP (ACADEMIC MANAGEMENT)

### 5.1. Quản lý Năm học & Học kỳ

**Vị trí**: `app/routers/deans.py:596-743`

#### **Tạo Năm học**
```python
POST /deans/academic-years
Body: {
    "year": "2024-2025",
    "start_date": "2024-09-01",
    "end_date": "2025-06-30"
}
```

#### **Tạo Học kỳ**
```python
POST /deans/semesters
Body: {
    "code": "20241",
    "name": "Học kỳ 1 năm học 2024-2025",
    "academic_year_id": 1,
    "semester_number": 1,
    "start_date": "2024-09-01",
    "end_date": "2024-12-31"
}
```

#### **Kích hoạt Học kỳ**
```python
POST /deans/semesters/{semester_id}/activate
```
- Chỉ có 1 học kỳ được `is_active = True` tại một thời điểm
- Khi kích hoạt học kỳ mới, tất cả học kỳ khác sẽ được set `is_active = False`

### 5.2. Quản lý Khoa (Department)

**Vị trí**: `app/routers/deans.py:104-158`

- CRUD operations cho departments
- Mỗi student/lecturer thuộc 1 department

### 5.3. Quản lý Môn học (Course)

**Vị trí**: `app/routers/deans.py:160-213`

```python
POST /deans/courses
Body: {
    "code": "CS101",
    "name": "Lập trình Cơ bản",
    "credits": 3
}
```

### 5.4. Quản lý Lớp học (Class)

**Vị trí**: `app/routers/deans.py:339-418`

#### **Tạo lớp học**
```python
POST /deans/classes
Body: {
    "code": "CS101-01",
    "course_id": 1,
    "lecturer_id": 5,
    "semester": "20241",
    "max_students": 50,
    "start_week": 1,
    "end_week": 15,
    "day_of_week": 2,  # Thứ 2
    "start_period": 1,
    "end_period": 3,
    "room": "A101"
}
```

**Luồng xử lý**:
1. Kiểm tra lecturer tồn tại → `app/services/class_service.py:14-22`
2. Tạo Class record → `app/services/class_service.py:24-27`
3. **Tự động generate timetable** → `app/services/class_service.py:29`

### 5.5. Quản lý Đăng ký học (Enrollment)

**Vị trí**: `app/routers/deans.py:420-481`

- **Bulk enrollment**: Đăng ký nhiều sinh viên cùng lúc
- **Kiểm tra trùng lịch**: Tự động kiểm tra conflict
- **Tự động tính học phí**: Khi đăng ký thành công

### 5.6. Quản lý Điểm số (Grades)

**Vị trí**: 
- Dean: `app/routers/deans.py:483-582`
- Lecturer: `app/routers/lecturers.py:63-88`

#### **Cấu trúc điểm**
- Mỗi enrollment có thể có nhiều loại điểm:
  - `midterm`: Điểm giữa kỳ
  - `final`: Điểm cuối kỳ
  - `lab`: Điểm thực hành
  - `assignment`: Điểm bài tập

- Điểm cuối cùng được tính từ các loại điểm này (ưu tiên `final`)

---

## 6. TÍNH TOÁN ĐIỂM SỐ (GPA/CPA)

### 6.1. Quy đổi điểm

**Vị trí**: `app/utils/academic_calculator.py:9-34`

| Điểm thang 10 | Điểm thang 4 | Điểm chữ |
|--------------|--------------|----------|
| 8.5 - 10.0   | 4.0          | A        |
| 8.0 - 8.4    | 3.5          | B+       |
| 7.0 - 7.9    | 3.0          | B        |
| 6.5 - 6.9    | 2.5          | C+       |
| 5.5 - 6.4    | 2.0          | C        |
| 5.0 - 5.4    | 1.5          | D+       |
| 4.0 - 4.9    | 1.0          | D        |
| 0.0 - 3.9    | 0.0          | F        |

### 6.2. Tính GPA (Grade Point Average - Điểm trung bình học kỳ)

**Vị trí**: `app/utils/academic_calculator.py:56-112`

**Công thức**:
```
GPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(số_tín_chỉ)
```

**Ví dụ**:
- Giải tích 1 (3 tín): 7.5/10 → 3.0 (B)
- Đại số (3 tín): 5.0/10 → 1.5 (D+)
- Vật lý (4 tín): 4.0/10 → 1.0 (D)

```
GPA = (3.0×3 + 1.5×3 + 1.0×4) / (3+3+4)
    = 17.5 / 10
    = 1.75
```

**Phân loại tín chỉ**:
- `completed_credits`: Điểm >= 1.0 (đã qua)
- `failed_credits`: Điểm < 1.0 (rớt)

### 6.3. Tính CPA (Cumulative Point Average - Điểm trung bình tích lũy)

**Vị trí**: `app/utils/academic_calculator.py:114-157`

**Công thức**:
```
CPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(tín_chỉ_đã_đăng_ký)
```

**Lưu ý**: CPA tính từ **TẤT CẢ** các môn học từ đầu khóa, không chỉ môn trong học kỳ hiện tại.

### 6.4. Tự động tính lại khi có thay đổi

**Vị trí**: `app/routers/deans.py:502-509`

Khi cập nhật điểm:
1. Update `Grade.score`
2. Tự động gọi `calculate_and_save_semester_result()`
3. Hàm này sẽ:
   - Tính lại GPA cho học kỳ
   - Cập nhật `AcademicResult`
   - Tính lại CPA tích lũy
   - Cập nhật `CumulativeResult`

### 6.5. Tính toán hàng loạt

**Vị trí**: `app/routers/deans.py:747-759`

```python
POST /deans/semesters/{semester_id}/calculate-results
```

- Tính kết quả cho tất cả sinh viên trong học kỳ
- Sử dụng: `calculate_all_students_in_semester()` → `app/utils/academic_calculator.py:247-271`

---

## 7. QUẢN LÝ HỌC PHÍ (TUITION MANAGEMENT)

### 7.1. Cấu trúc

**Vị trí**: `app/models/tuition.py:5-15`

- Mỗi sinh viên có 1 record `Tuition` cho mỗi học kỳ
- Trạng thái: `PENDING`, `PARTIAL`, `COMPLETED`

### 7.2. Tính học phí tự động

**Vị trí**: `app/services/tuition_service.py:54-94`

**Khi nào tính**:
- Khi sinh viên đăng ký lớp mới → `app/routers/deans.py:464-469`

**Cách tính**:
1. Lấy tất cả enrollments của sinh viên trong học kỳ
2. Tính tổng số tín chỉ: `Σ(course.credits)`
3. Lấy giá mỗi tín chỉ từ `Setting` (key: `tuition_price_per_credit`)
4. `total_amount = total_credits × price_per_credit`

**Vị trí cấu hình giá**: `app/services/tuition_service.py:9-13`
- Default: 500,000 VNĐ/tín chỉ
- Có thể thay đổi qua API: `POST /deans/tuition-settings`

### 7.3. Cập nhật thanh toán

**Vị trí**: `app/services/tuition_service.py:96-112`

```python
PUT /deans/tuitions/{tuition_id}
Body: {"paid_amount": 5000000}
```

**Luồng xử lý**:
1. Update `paid_amount`
2. Tự động cập nhật `status`:
   - `COMPLETED`: `paid_amount >= total_amount`
   - `PARTIAL`: `0 < paid_amount < total_amount`
   - `PENDING`: `paid_amount == 0`

### 7.4. Xem học phí

**Sinh viên**: `GET /students/me/tuitions` → `app/routers/tuitions.py:15-23`
**Dean**: `GET /deans/tuitions` → `app/routers/tuitions.py:25-37`

---

## 8. API ENDPOINTS

### 8.1. Authentication

**Base URL**: `/auth`

| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/auth/register` | Đăng ký tài khoản | `app/routers/auth.py:17` |
| POST | `/auth/login` | Đăng nhập | `app/routers/auth.py:29` |
| POST | `/auth/change-password` | Đổi mật khẩu | `app/routers/auth.py:48` |

### 8.2. Student Endpoints

**Base URL**: `/students`

| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| GET | `/students/me` | Xem profile | `app/routers/students.py:15` |
| PUT | `/students/me` | Cập nhật profile | `app/routers/students.py:39` |
| GET | `/students/my-grades` | Xem điểm số | `app/routers/students.py:59` |
| GET | `/students/my-classes` | Xem lớp đã đăng ký | `app/routers/students.py:73` |
| GET | `/students/my-projects` | Xem đồ án | `app/routers/students.py:87` |
| GET | `/students/academic-summary` | Tóm tắt học tập | `app/routers/students.py:101` |
| GET | `/students/my-results/{semester_code}` | Chi tiết học kỳ | `app/routers/students.py:115` |
| GET | `/students/my-timetable` | Thời khóa biểu | `app/routers/students.py:134` |

### 8.3. Lecturer Endpoints

**Base URL**: `/lecturers`

| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| GET | `/lecturers/me` | Xem profile | `app/routers/lecturers.py:18` |
| GET | `/lecturers/my-classes` | Xem lớp đang dạy | `app/routers/lecturers.py:27` |
| GET | `/lecturers/classes/{class_id}/students` | Xem sinh viên trong lớp | `app/routers/lecturers.py:39` |
| GET | `/lecturers/classes/{class_id}/grades` | Xem điểm lớp | `app/routers/lecturers.py:54` |
| POST/PUT | `/lecturers/grades` | Nhập/cập nhật điểm | `app/routers/lecturers.py:63` |

### 8.4. Dean Endpoints

**Base URL**: `/deans`

#### **Quản lý Khoa**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/departments` | Tạo khoa | `app/routers/deans.py:105` |
| GET | `/deans/departments` | Danh sách khoa | `app/routers/deans.py:117` |
| PUT | `/deans/departments/{id}` | Cập nhật khoa | `app/routers/deans.py:126` |
| DELETE | `/deans/departments/{id}` | Xóa khoa | `app/routers/deans.py:146` |

#### **Quản lý Môn học**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/courses` | Tạo môn học | `app/routers/deans.py:161` |
| GET | `/deans/courses` | Danh sách môn học | `app/routers/deans.py:173` |
| PUT | `/deans/courses/{id}` | Cập nhật môn học | `app/routers/deans.py:181` |
| DELETE | `/deans/courses/{id}` | Xóa môn học | `app/routers/deans.py:201` |

#### **Quản lý Giảng viên**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/lecturers` | Tạo giảng viên | `app/routers/deans.py:216` |
| GET | `/deans/lecturers` | Danh sách giảng viên | `app/routers/deans.py:228` |
| PUT | `/deans/lecturers/{id}` | Cập nhật giảng viên | `app/routers/deans.py:238` |
| DELETE | `/deans/lecturers/{id}` | Xóa giảng viên | `app/routers/deans.py:262` |

#### **Quản lý Sinh viên**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/students` | Tạo sinh viên | `app/routers/deans.py:277` |
| GET | `/deans/students` | Danh sách sinh viên | `app/routers/deans.py:289` |
| PUT | `/deans/students/{id}` | Cập nhật sinh viên | `app/routers/deans.py:299` |
| DELETE | `/deans/students/{id}` | Xóa sinh viên | `app/routers/deans.py:325` |

#### **Quản lý Lớp học**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/classes` | Tạo lớp học | `app/routers/deans.py:340` |
| GET | `/deans/classes` | Danh sách lớp học | `app/routers/deans.py:354` |
| GET | `/deans/classes/{id}` | Chi tiết lớp học | `app/routers/deans.py:584` |
| PUT | `/deans/classes/{id}` | Cập nhật lớp học | `app/routers/deans.py:370` |
| DELETE | `/deans/classes/{id}` | Xóa lớp học | `app/routers/deans.py:385` |
| POST | `/deans/classes/{id}/timetable/generate` | Tạo thời khóa biểu | `app/routers/deans.py:399` |
| GET | `/deans/classes/{id}/timetable` | Xem thời khóa biểu | `app/routers/deans.py:410` |

#### **Quản lý Đăng ký học**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/classes/{id}/enrollments/bulk` | Đăng ký hàng loạt | `app/routers/deans.py:421` |
| GET | `/deans/classes/{id}/students` | Danh sách SV trong lớp | `app/routers/deans.py:473` |

#### **Quản lý Điểm số**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/grades` | Tạo điểm | `app/routers/deans.py:513` |
| PUT | `/deans/grades/{id}` | Cập nhật điểm | `app/routers/deans.py:483` |
| GET | `/deans/classes/{id}/grades` | Xem điểm lớp | `app/routers/deans.py:549` |

#### **Quản lý Năm học & Học kỳ**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| POST | `/deans/academic-years` | Tạo năm học | `app/routers/deans.py:598` |
| GET | `/deans/academic-years` | Danh sách năm học | `app/routers/deans.py:611` |
| POST | `/deans/semesters` | Tạo học kỳ | `app/routers/deans.py:662` |
| GET | `/deans/semesters` | Danh sách học kỳ | `app/routers/deans.py:678` |
| POST | `/deans/semesters/{id}/activate` | Kích hoạt học kỳ | `app/routers/deans.py:725` |
| POST | `/deans/semesters/{id}/calculate-results` | Tính kết quả hàng loạt | `app/routers/deans.py:747` |

#### **Quản lý Kết quả học tập**
| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| GET | `/deans/academic-results` | Danh sách kết quả | `app/routers/deans.py:53` |
| GET | `/deans/students/{id}/academic-results` | Kết quả của SV | `app/routers/deans.py:74` |
| POST | `/deans/recalculate-all-cpa` | Tính lại CPA tất cả | `app/routers/deans.py:89` |

### 8.5. Tuition Endpoints

**Base URL**: `/`

| Method | Endpoint | Mô tả | Vị trí |
|--------|----------|-------|--------|
| GET | `/students/me/tuitions` | Học phí của tôi (SV) | `app/routers/tuitions.py:15` |
| GET | `/deans/tuitions` | Tất cả học phí (Dean) | `app/routers/tuitions.py:25` |
| PUT | `/deans/tuitions/{id}` | Cập nhật thanh toán | `app/routers/tuitions.py:39` |
| GET | `/deans/tuition-settings` | Xem cài đặt giá | `app/routers/tuitions.py:55` |
| POST | `/deans/tuition-settings` | Cập nhật giá | `app/routers/tuitions.py:66` |

---

## KẾT LUẬN

Backend LMS MVP được xây dựng với kiến trúc rõ ràng, phân lớp tốt:
- **Models**: Định nghĩa database schema
- **Routers**: Xử lý HTTP requests/responses
- **Services**: Business logic
- **Utils**: Các hàm tiện ích (tính toán điểm, etc.)

**Điểm mạnh**:
- Authentication/Authorization rõ ràng
- Tự động tính toán GPA/CPA khi có thay đổi điểm
- Tự động tính học phí khi đăng ký lớp
- Kiểm tra trùng lịch khi đăng ký
- Tự động generate thời khóa biểu

**Có thể cải thiện**:
- Thêm validation cho input
- Thêm logging/audit trail
- Thêm caching cho các query phức tạp
- Thêm unit tests

