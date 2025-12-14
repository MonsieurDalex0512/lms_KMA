# Giải thích về Đồng bộ Realtime giữa Web và Mobile App

## Tình trạng hiện tại

### ❌ KHÔNG có đồng bộ realtime tự động

App mobile hiện tại **KHÔNG** có:
- ❌ WebSocket hoặc Server-Sent Events (SSE)
- ❌ Auto-refresh/polling tự động
- ❌ Push notifications khi có thay đổi
- ❌ Đồng bộ realtime giữa web và mobile

### ✅ Cơ chế hiện tại

App mobile chỉ fetch dữ liệu khi:
1. **Mở màn hình lần đầu** - `initState()` gọi `fetchTimetable()`
2. **Pull-to-refresh** (vừa được thêm) - Kéo xuống để refresh

## Cách hoạt động

### Luồng dữ liệu:

```
Web Admin (Tạo/Chỉnh sửa lớp) 
    ↓
Backend API (Lưu vào database)
    ↓
[KHÔNG CÓ TỰ ĐỘNG]
    ↓
Mobile App (Phải refresh thủ công)
```

### Khi nào dữ liệu được cập nhật trên mobile:

1. **Khi mở màn hình timetable** - Fetch từ API
2. **Khi pull-to-refresh** - Kéo xuống để refresh
3. **KHÔNG tự động** - Phải refresh thủ công

## Giải pháp đã thêm

### ✅ Pull-to-Refresh

Đã thêm `RefreshIndicator` vào `timetable_screen.dart`:
- Kéo xuống để refresh dữ liệu
- Tự động fetch lại từ API `/students/my-timetable`
- Cập nhật calendar với dữ liệu mới

**Cách sử dụng:**
1. Mở màn hình Thời khóa biểu
2. Kéo xuống (pull down)
3. Dữ liệu sẽ được refresh tự động

## Giải pháp nâng cao (Tùy chọn)

Nếu cần đồng bộ realtime, có thể thêm:

### 1. Auto-refresh khi quay lại màn hình

Sử dụng `RouteObserver` hoặc `AppLifecycleState`:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    _fetchTimetable(); // Refresh khi app quay lại foreground
  }
}
```

### 2. Polling tự động (Không khuyến nghị)

Refresh định kỳ mỗi X giây:
```dart
Timer.periodic(Duration(seconds: 30), (timer) {
  _fetchTimetable();
});
```

**Nhược điểm:** Tốn pin, tốn băng thông

### 3. WebSocket/SSE (Khuyến nghị cho tương lai)

Thực hiện đồng bộ realtime thực sự:
- Backend: Thêm WebSocket endpoint
- Frontend: Kết nối WebSocket
- Mobile: Lắng nghe events từ WebSocket

**Ưu điểm:** Đồng bộ ngay lập tức, không cần polling

## Khuyến nghị

### Hiện tại:
✅ **Sử dụng Pull-to-Refresh** - Đã được thêm vào
- Đơn giản, hiệu quả
- User có thể refresh khi cần

### Tương lai (nếu cần):
1. Thêm auto-refresh khi quay lại màn hình
2. Thêm WebSocket cho đồng bộ realtime
3. Thêm push notifications cho thay đổi quan trọng

## Lưu ý

- **Không có đồng bộ realtime tự động** - Phải refresh thủ công
- **Pull-to-refresh** là cách tốt nhất hiện tại để cập nhật dữ liệu
- Nếu cần realtime, cần implement WebSocket hoặc polling
