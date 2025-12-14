# Hướng dẫn xử lý vấn đề Timetable không hiển thị trên Mobile App

## Vấn đề
Khi tạo lớp học và thêm vào học kỳ, timetable được generate nhưng không hiển thị trên app mobile.

## Nguyên nhân

Timetable trên app mobile chỉ hiển thị các lớp mà **student đã được enroll**. 

Luồng hoạt động:
1. ✅ Tạo lớp học → Timetable được tự động generate
2. ❌ **THIẾU BƯỚC**: Enroll student vào lớp học
3. ❌ Kết quả: Timetable không hiển thị trên app mobile

## Giải pháp

### Cách 1: Enroll student qua API (Khuyến nghị)

Sử dụng endpoint `/deans/classes/{class_id}/enrollments/bulk`:

```bash
POST /deans/classes/{class_id}/enrollments/bulk
{
  "student_ids": [14, 15, 16]
}
```

### Cách 2: Enroll qua Frontend Admin

1. Vào trang quản lý lớp học
2. Chọn lớp cần enroll student
3. Click "Thêm sinh viên"
4. Chọn các student cần enroll
5. Click "Thêm"

## Kiểm tra

### 1. Kiểm tra lớp học có timetable chưa

```python
# Chạy script debug
uv run python debug_timetable_issue.py
```

### 2. Kiểm tra student đã enroll chưa

Query database:
```sql
SELECT e.*, c.code as class_code, u.full_name 
FROM enrollments e
JOIN classes c ON e.class_id = c.id
JOIN students s ON e.student_id = s.user_id
JOIN users u ON s.user_id = u.id
WHERE c.id = <class_id>;
```

### 3. Kiểm tra API response

```bash
GET /students/my-timetable
Authorization: Bearer <student_token>
```

Response sẽ chỉ trả về timetable của các lớp mà student đã enroll.

## Điều kiện để Timetable hiển thị

Để timetable hiển thị trên app mobile, cần đảm bảo **TẤT CẢ** các điều kiện sau:

1. ✅ Lớp học có `semester` code hợp lệ
2. ✅ Semester tồn tại trong database và có `start_date`
3. ✅ Lớp học có `day_of_week`, `start_week`, `end_week`
4. ✅ Timetable đã được generate (có records trong bảng `timetables`)
5. ✅ **Student đã được enroll vào lớp học** ← **QUAN TRỌNG NHẤT**

Nếu thiếu bất kỳ điều kiện nào, timetable sẽ không hiển thị!

## Script hỗ trợ

Sử dụng `debug_timetable_issue.py` để kiểm tra:
- Danh sách tất cả lớp học và trạng thái timetable
- Danh sách student và các lớp đã enroll
- Kết quả query giống như API `/students/my-timetable`

## Lưu ý

- Khi tạo lớp học mới, timetable được tự động generate
- Nhưng student **PHẢI** được enroll thủ công
- Có thể enroll nhiều student cùng lúc qua bulk enrollment API
