# Sửa lỗi: Điểm học kỳ không được cập nhật khi xóa/cập nhật lớp

## Vấn đề

Khi xóa hoặc cập nhật lớp học:
- ❌ Điểm số của học kỳ không được tự động cập nhật
- ❌ Dữ liệu của lớp đã bị xóa vẫn còn trong kết quả học kỳ
- ❌ Khi thay đổi semester của lớp, điểm số không được recalculate

## Nguyên nhân

1. **Khi xóa lớp**: Chỉ xóa lớp mà không recalculate semester results cho các students bị ảnh hưởng
2. **Khi cập nhật lớp**: Không recalculate semester results, đặc biệt khi semester thay đổi

## Giải pháp đã áp dụng

### 1. Sửa hàm `delete_class` (line 422-453)

**Trước:**
```python
@router.delete("/classes/{class_id}")
def delete_class(...):
    db_class = class_service.remove(db, id=class_id)
    return {"message": "Class deleted"}
```

**Sau:**
```python
@router.delete("/classes/{class_id}")
def delete_class(...):
    # Lấy thông tin lớp trước khi xóa
    db_class = db.query(Class).filter(Class.id == class_id).first()
    semester_code = db_class.semester
    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    student_ids = [e.student_id for e in enrollments]
    
    # Xóa lớp
    class_service.remove(db, id=class_id)
    
    # Recalculate semester results cho tất cả students bị ảnh hưởng
    if semester_code:
        semester = db.query(Semester).filter(Semester.code == semester_code).first()
        if semester:
            for student_id in student_ids:
                calculate_and_save_semester_result(student_id, semester.id, db)
```

**Chức năng:**
- Lấy danh sách students đã enroll vào lớp trước khi xóa
- Lấy semester code của lớp
- Xóa lớp (cascade delete sẽ xóa enrollments và grades)
- Recalculate semester results cho tất cả students bị ảnh hưởng

### 2. Sửa hàm `update_class` (line 370-420)

**Trước:**
```python
@router.put("/classes/{class_id}")
def update_class(...):
    updated_class = class_service.update_class(db, class_id, class_in)
    return updated_class
```

**Sau:**
```python
@router.put("/classes/{class_id}")
def update_class(...):
    # Lấy lớp hiện tại để so sánh semester
    db_class = db.query(Class).filter(Class.id == class_id).first()
    old_semester_code = db_class.semester
    new_semester_code = class_in.semester
    
    # Lấy danh sách students đã enroll
    enrollments = db.query(Enrollment).filter(Enrollment.class_id == class_id).all()
    student_ids = [e.student_id for e in enrollments]
    
    # Update lớp
    updated_class = class_service.update_class(db, class_id, class_in)
    
    # Recalculate semester results
    if student_ids:
        semesters_to_recalculate = set()
        
        # Nếu semester thay đổi, recalculate cả 2 semester (cũ và mới)
        if old_semester_code and old_semester_code != new_semester_code:
            old_semester = db.query(Semester).filter(Semester.code == old_semester_code).first()
            if old_semester:
                semesters_to_recalculate.add(old_semester.id)
        
        # Luôn recalculate semester hiện tại (mới)
        if new_semester_code:
            new_semester = db.query(Semester).filter(Semester.code == new_semester_code).first()
            if new_semester:
                semesters_to_recalculate.add(new_semester.id)
        
        # Recalculate cho tất cả students
        for student_id in student_ids:
            for semester_id in semesters_to_recalculate:
                calculate_and_save_semester_result(student_id, semester_id, db)
```

**Chức năng:**
- So sánh semester cũ và mới
- Nếu semester thay đổi: recalculate cả 2 semester (cũ và mới)
- Nếu semester không đổi: recalculate semester hiện tại
- Recalculate cho tất cả students bị ảnh hưởng

## Luồng hoạt động

### Khi xóa lớp:
```
1. Lấy thông tin lớp (semester, students)
2. Xóa lớp → Cascade delete enrollments và grades
3. Recalculate semester results cho tất cả students bị ảnh hưởng
4. Update cumulative results (CPA)
```

### Khi cập nhật lớp:
```
1. Lấy thông tin lớp hiện tại (semester, students)
2. So sánh semester cũ và mới
3. Update lớp
4. Nếu semester thay đổi:
   - Recalculate semester cũ
   - Recalculate semester mới
5. Nếu semester không đổi:
   - Recalculate semester hiện tại
6. Update cumulative results (CPA)
```

## Lợi ích

✅ **Tự động cập nhật điểm số** khi xóa/cập nhật lớp
✅ **Xóa dữ liệu đúng cách** - điểm số được recalculate sau khi xóa lớp
✅ **Xử lý thay đổi semester** - recalculate cả 2 semester khi cần
✅ **Error handling** - bắt lỗi và log để debug

## Lưu ý

- Recalculation có thể tốn thời gian nếu có nhiều students
- Các lỗi trong quá trình recalculation được log nhưng không làm crash API
- Cumulative results (CPA) cũng được tự động cập nhật

## Testing

Để test:
1. Tạo lớp học và enroll students
2. Nhập điểm cho students
3. Kiểm tra điểm học kỳ
4. Xóa lớp → Kiểm tra điểm học kỳ đã được cập nhật (lớp đã bị xóa)
5. Tạo lại lớp và enroll students
6. Cập nhật semester của lớp → Kiểm tra điểm học kỳ đã được cập nhật
