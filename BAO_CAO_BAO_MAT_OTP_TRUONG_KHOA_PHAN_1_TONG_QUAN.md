# BÁO CÁO BẢO MẬT CHUYÊN SÂU: ĐĂNG NHẬP OTP CHO TÀI KHOẢN TRƯỞNG KHOA

## MỤC LỤC

1. [Tổng quan về hệ thống](#1-tổng-quan-về-hệ-thống)
2. [Khái niệm OTP và xác thực hai yếu tố](#2-khái-niệm-otp-và-xác-thực-hai-yếu-tố)
3. [Tại sao cần OTP cho trưởng khoa?](#3-tại-sao-cần-otp-cho-trưởng-khoa)
4. [Kiến trúc hệ thống](#4-kiến-trúc-hệ-thống)
5. [Các thành phần chính](#5-các-thành-phần-chính)

---

## 1. TỔNG QUAN VỀ HỆ THỐNG

### 1.1. Hệ thống LMS (Learning Management System)

Hệ thống LMS là một ứng dụng quản lý học tập cho phép:
- **Trưởng khoa (Dean)**: Quản lý toàn bộ hệ thống, tạo giảng viên, sinh viên, lớp học, khóa học
- **Giảng viên (Lecturer)**: Quản lý lớp học, chấm điểm, giao tiếp với sinh viên
- **Sinh viên (Student)**: Xem điểm, đăng ký lớp, giao tiếp với giảng viên

### 1.2. Vấn đề bảo mật

Trưởng khoa có quyền cao nhất trong hệ thống, có thể:
- Tạo/xóa/sửa tất cả tài khoản
- Quản lý toàn bộ dữ liệu học tập
- Xem và chỉnh sửa điểm số
- Quản lý học phí

**Nếu tài khoản trưởng khoa bị xâm nhập, toàn bộ hệ thống sẽ bị ảnh hưởng nghiêm trọng!**

### 1.3. Giải pháp: Xác thực hai yếu tố (2FA) với OTP

Để bảo vệ tài khoản trưởng khoa, hệ thống yêu cầu:
1. **Yếu tố 1**: Username + Password (cái bạn biết)
2. **Yếu tố 2**: Mã OTP gửi qua email (cái bạn có)

Chỉ khi có CẢ HAI yếu tố, trưởng khoa mới có thể đăng nhập.

---

## 2. KHÁI NIỆM OTP VÀ XÁC THỰC HAI YẾU TỐ

### 2.1. OTP là gì?

**OTP (One-Time Password)** = Mật khẩu một lần

- Là một chuỗi số ngẫu nhiên (thường 6 chữ số)
- Chỉ sử dụng được **MỘT LẦN DUY NHẤT**
- Có **thời gian hết hạn** (thường 5-10 phút)
- Được gửi qua email hoặc SMS

**Ví dụ**: Bạn nhận được email với mã `123456`. Bạn nhập mã này để đăng nhập. Sau khi đăng nhập thành công, mã này không còn dùng được nữa.

### 2.2. Xác thực hai yếu tố (2FA - Two-Factor Authentication)

**2FA** là phương pháp bảo mật yêu cầu **2 yếu tố khác nhau** để xác thực:

1. **Yếu tố 1 - Cái bạn biết (Something you know)**:
   - Mật khẩu
   - Câu hỏi bảo mật
   - PIN

2. **Yếu tố 2 - Cái bạn có (Something you have)**:
   - Mã OTP qua email/SMS
   - Ứng dụng xác thực (Google Authenticator)
   - Thiết bị vật lý (USB key)

3. **Yếu tố 3 - Cái bạn là (Something you are)** (tùy chọn):
   - Vân tay
   - Nhận diện khuôn mặt
   - Giọng nói

### 2.3. Tại sao 2FA an toàn hơn?

**Kịch bản tấn công không có 2FA:**
```
Kẻ tấn công → Đánh cắp mật khẩu → Đăng nhập thành công → Xâm nhập hệ thống
```

**Kịch bản tấn công có 2FA:**
```
Kẻ tấn công → Đánh cắp mật khẩu → Đăng nhập bước 1 → Cần mã OTP
→ Không có quyền truy cập email → KHÔNG THỂ đăng nhập → THẤT BẠI
```

**Lợi ích:**
- Ngay cả khi mật khẩu bị lộ, kẻ tấn công vẫn không thể đăng nhập
- Mã OTP chỉ có hiệu lực trong thời gian ngắn
- Mã OTP chỉ dùng được một lần
- Mã OTP được gửi đến email mà chỉ chủ tài khoản mới có quyền truy cập

---

## 3. TẠI SAO CẦN OTP CHO TRƯỞNG KHOA?

### 3.1. Quyền hạn cao

Trưởng khoa có quyền:
- ✅ Tạo/xóa/sửa tất cả tài khoản (giảng viên, sinh viên)
- ✅ Xem và chỉnh sửa điểm số của tất cả sinh viên
- ✅ Quản lý học phí
- ✅ Quản lý lớp học, khóa học, học kỳ
- ✅ Xem báo cáo thống kê toàn hệ thống

### 3.2. Rủi ro nếu bị xâm nhập

Nếu tài khoản trưởng khoa bị hack:
- ❌ Kẻ tấn công có thể tạo tài khoản giả
- ❌ Có thể thay đổi điểm số
- ❌ Có thể xóa dữ liệu quan trọng
- ❌ Có thể truy cập thông tin cá nhân của tất cả người dùng
- ❌ Có thể gây thiệt hại không thể khắc phục

### 3.3. So sánh với các vai trò khác

| Vai trò | Quyền hạn | Có OTP? | Lý do |
|---------|-----------|---------|-------|
| **Trưởng khoa** | Toàn quyền hệ thống | ✅ Có | Quyền cao nhất, cần bảo vệ tối đa |
| **Giảng viên** | Quản lý lớp học, chấm điểm | ❌ Không | Quyền hạn giới hạn trong lớp học của mình |
| **Sinh viên** | Xem điểm, đăng ký lớp | ❌ Không | Quyền hạn rất hạn chế, chỉ xem thông tin cá nhân |

---

## 4. KIẾN TRÚC HỆ THỐNG

### 4.1. Sơ đồ tổng quan

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Frontend  │ ◄─────► │   Backend   │ ◄─────► │  Database   │
│  (React)    │  HTTP   │  (FastAPI)  │  SQL    │ (PostgreSQL) │
└─────────────┘         └─────────────┘         └─────────────┘
                              │
                              │ SMTP
                              ▼
                       ┌─────────────┐
                       │ Email Server│
                       │  (Gmail)    │
                       └─────────────┘
```

### 4.2. Các thành phần

1. **Frontend (React + TypeScript)**
   - Giao diện đăng nhập
   - Trang xác thực OTP
   - Quản lý token JWT

2. **Backend (FastAPI + Python)**
   - API xử lý đăng nhập
   - Tạo và xác thực OTP
   - Gửi email OTP
   - Tạo JWT token

3. **Database (PostgreSQL)**
   - Lưu trữ thông tin người dùng
   - Lưu trữ OTP tạm thời (trong bộ nhớ)

4. **Email Server (Gmail SMTP)**
   - Gửi email chứa mã OTP

---

## 5. CÁC THÀNH PHẦN CHÍNH

### 5.1. Backend Components

#### a) Router: `lms_backend/app/routers/auth.py`
- Xử lý các endpoint đăng nhập
- `/auth/login` - Đăng nhập ban đầu
- `/auth/verify-otp` - Xác thực OTP
- `/auth/resend-otp` - Gửi lại OTP

#### b) Service: `lms_backend/app/services/otp_service.py`
- `generate_otp()` - Tạo mã OTP ngẫu nhiên
- `store_otp()` - Lưu OTP với thời gian hết hạn
- `verify_otp()` - Xác thực OTP
- `send_otp_email()` - Gửi email chứa OTP

#### c) Security: `lms_backend/app/auth/security.py`
- `verify_password()` - Kiểm tra mật khẩu
- `create_access_token()` - Tạo JWT token
- `decode_access_token()` - Giải mã JWT token

#### d) Config: `lms_backend/app/core/config.py`
- Cấu hình SMTP (email server)
- Cấu hình OTP (độ dài, thời gian hết hạn)
- Cấu hình JWT (secret key, thời gian hết hạn)

### 5.2. Frontend Components

#### a) Page: `lms_frontend/src/pages/Login.tsx`
- Form đăng nhập
- Xử lý phản hồi từ server
- Chuyển hướng đến trang OTP nếu cần

#### b) Page: `lms_frontend/src/pages/OtpVerify.tsx`
- Form nhập OTP
- Gửi OTP để xác thực
- Nút gửi lại OTP

#### c) Context: `lms_frontend/src/context/AuthContext.tsx`
- Quản lý trạng thái đăng nhập
- Lưu trữ token JWT
- Cung cấp hàm login/logout

#### d) Service: `lms_frontend/src/services/api.ts`
- Cấu hình axios
- Tự động thêm JWT token vào header
- Xử lý lỗi 401 (unauthorized)

### 5.3. Database Models

#### Model: `lms_backend/app/models/user.py`
- Bảng `users`: Lưu thông tin người dùng
  - `id`: ID người dùng
  - `username`: Tên đăng nhập
  - `email`: Email (để gửi OTP)
  - `hashed_password`: Mật khẩu đã mã hóa
  - `role`: Vai trò (DEAN, LECTURER, STUDENT)
  - `is_active`: Trạng thái hoạt động

---

## TÓM TẮT PHẦN 1

Trong phần này, chúng ta đã tìm hiểu:

1. ✅ **Hệ thống LMS** là gì và tại sao cần bảo mật
2. ✅ **OTP và 2FA** là gì, hoạt động như thế nào
3. ✅ **Tại sao** trưởng khoa cần OTP (quyền cao, rủi ro lớn)
4. ✅ **Kiến trúc hệ thống** (Frontend, Backend, Database, Email)
5. ✅ **Các thành phần chính** trong code

**Tiếp theo**: Phần 2 sẽ giải thích **LUỒNG HOẠT ĐỘNG CHI TIẾT** từng bước một, từ khi người dùng nhập username/password đến khi nhận được JWT token.

---

**📄 Xem tiếp**: `BAO_CAO_BAO_MAT_OTP_TRUONG_KHOA_PHAN_2_LUONG_HOAT_DONG.md`

