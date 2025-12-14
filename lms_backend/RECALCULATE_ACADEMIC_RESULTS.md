# Hướng dẫn Recalculate Kết Quả Học Tập

## Vấn đề

Khi xóa lớp học, `AcademicResult` (kết quả học tập theo học kỳ) có thể vẫn còn trong database với dữ liệu cũ, dẫn đến:
- Hiển thị điểm của các lớp đã bị xóa
- GPA/CPA không chính xác
- Semester không còn lớp học vẫn hiển thị trong kết quả

## Giải pháp

Có 2 cách để recalculate và cleanup kết quả học tập:

### Cách 1: Sử dụng Web Interface (Khuyến nghị)

1. Đăng nhập vào web admin với tài khoản Dean
2. Vào trang **"Kết Quả Học Tập"** (`/academic-results`)
3. Click nút **"Recalculate Tất Cả"** (màu cam) ở góc trên bên phải
4. Xác nhận trong popup
5. Đợi quá trình hoàn thành (có thể mất vài phút nếu có nhiều sinh viên)

### Cách 2: Sử dụng Script (Command Line)

Chạy script Python:

```bash
cd lms_backend
uv run python recalculate_all_academic_results.py
```

Hoặc nếu dùng Python trực tiếp:

```bash
cd lms_backend
python recalculate_all_academic_results.py
```

### Cách 3: Sử dụng API Endpoint

```bash
POST /deans/recalculate-all-academic-results
Authorization: Bearer <token>
```

Response:
```json
{
  "message": "Academic results recalculation completed",
  "total_students": 100,
  "total_semesters": 5,
  "recalculated": 450,
  "deleted": 50,
  "errors": 0,
  "error_details": []
}
```

## Chức năng

Script/Endpoint sẽ:

1. **Recalculate tất cả semester results** cho tất cả students
   - Tính lại GPA từ enrollments hiện có
   - Cập nhật total_credits, completed_credits, failed_credits

2. **Xóa AcademicResult không còn enrollments**
   - Nếu một semester không còn lớp học nào (total_credits = 0)
   - AcademicResult sẽ bị xóa tự động

3. **Update Cumulative Results (CPA)**
   - Tính lại CPA cho tất cả students
   - Cập nhật tổng số tín chỉ đã đăng ký/đạt/trượt

## Khi nào cần chạy?

- ✅ Sau khi xóa nhiều lớp học
- ✅ Sau khi import dữ liệu từ hệ thống khác
- ✅ Khi phát hiện GPA/CPA không chính xác
- ✅ Sau khi sửa lỗi trong logic tính điểm
- ✅ Định kỳ để đảm bảo dữ liệu đồng bộ

## Lưu ý

- ⚠️ Quá trình này có thể mất vài phút nếu có nhiều students/semesters
- ⚠️ Không nên chạy đồng thời nhiều lần
- ⚠️ Đảm bảo database backup trước khi chạy (nếu có nhiều dữ liệu)
- ✅ Script an toàn, chỉ cập nhật/xóa dữ liệu, không ảnh hưởng đến enrollments/grades

## Kết quả mong đợi

Sau khi chạy:
- ✅ Các semester không còn lớp học sẽ không còn hiển thị
- ✅ GPA/CPA được cập nhật chính xác theo enrollments hiện có
- ✅ Kết quả học tập phản ánh đúng trạng thái hiện tại của hệ thống
