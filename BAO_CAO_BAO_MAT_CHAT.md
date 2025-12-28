# BÁO CÁO VỀ CƠ CHẾ BẢO MẬT TRONG CHỨC NĂNG CHAT

## MỤC LỤC

1. [Tổng quan về hệ thống chat](#1-tổng-quan-về-hệ-thống-chat)
2. [Các khái niệm bảo mật cơ bản](#2-các-khái-niệm-bảo-mật-cơ-bản)
3. [Cơ chế bảo mật được triển khai](#3-cơ-chế-bảo-mật-được-triển-khai)
4. [Ảnh hưởng và tầm quan trọng](#4-ảnh-hưởng-và-tầm-quan-trọng)
5. [Kết luận](#5-kết-luận)

---

## 1. TỔNG QUAN VỀ HỆ THỐNG CHAT

Hệ thống chat trong LMS (Learning Management System) là một tính năng quan trọng cho phép giảng viên và sinh viên giao tiếp với nhau trong các nhóm chat được tạo theo từng lớp học. Hệ thống được xây dựng với kiến trúc client-server, sử dụng:

- **Backend**: FastAPI (Python) với Socket.IO cho giao tiếp real-time
- **Mobile Client**: Flutter (Dart) cho ứng dụng di động
- **Database**: PostgreSQL để lưu trữ dữ liệu

Hệ thống chat hoạt động theo mô hình nhóm (group-based), nơi mỗi lớp học có thể có một nhóm chat riêng. Giảng viên có quyền tạo nhóm chat cho lớp học của mình, và tất cả sinh viên đăng ký vào lớp đó sẽ tự động trở thành thành viên của nhóm chat.

---

## 2. CÁC KHÁI NIỆM BẢO MẬT CƠ BẢN

### 2.1. Xác thực (Authentication)

Xác thực là quá trình xác minh danh tính của người dùng khi họ muốn truy cập vào hệ thống. Trong hệ thống chat, xác thực được thực hiện thông qua JWT (JSON Web Token), một chuẩn mã hóa phổ biến cho phép truyền thông tin xác thực một cách an toàn.

### 2.2. Phân quyền (Authorization)

Phân quyền là quá trình kiểm tra xem người dùng đã được xác thực có quyền thực hiện một hành động cụ thể hay không. Hệ thống sử dụng phân quyền dựa trên vai trò (role-based) và quyền thành viên (membership-based).

### 2.3. Mã hóa (Encryption)

Mã hóa là quá trình chuyển đổi thông tin từ dạng có thể đọc được (plaintext) sang dạng không thể đọc được (ciphertext) để bảo vệ dữ liệu khỏi việc truy cập trái phép. Hệ thống sử dụng mã hóa AES (Advanced Encryption Standard) để bảo vệ nội dung tin nhắn.

### 2.4. Bảo mật kết nối (Connection Security)

Bảo mật kết nối đảm bảo rằng dữ liệu được truyền giữa client và server được bảo vệ khỏi các cuộc tấn công nghe lén (eavesdropping) và giả mạo (spoofing).

---

## 3. CƠ CHẾ BẢO MẬT ĐƯỢC TRIỂN KHAI

### 3.1. Xác thực JWT cho API REST

Hệ thống sử dụng JWT để xác thực tất cả các yêu cầu API. Khi người dùng đăng nhập, hệ thống tạo một token JWT chứa thông tin về người dùng (user_id, username). Token này có thời gian hết hạn (thường là 30 phút) và được lưu trữ an toàn trên thiết bị của người dùng.

Mỗi khi client gửi yêu cầu đến server, token JWT được đính kèm trong header `Authorization: Bearer <token>`. Server sẽ xác minh token này trước khi xử lý yêu cầu. Nếu token không hợp lệ hoặc đã hết hạn, yêu cầu sẽ bị từ chối.

**Lợi ích:**
- Không cần lưu trữ session trên server, giảm tải cho server
- Token có thể được xác minh độc lập mà không cần truy vấn database
- Dễ dàng mở rộng cho các dịch vụ phân tán

### 3.2. Xác thực Socket.IO

Kết nối Socket.IO cũng được bảo vệ bằng JWT. Khi client muốn kết nối với server qua WebSocket, client phải gửi token JWT trong quá trình handshake. Server sẽ xác minh token này trước khi cho phép kết nối. Nếu token không hợp lệ, kết nối sẽ bị từ chối.

Sau khi kết nối thành công, server lưu trữ mapping giữa socket ID (sid) và user ID để có thể xác định người dùng trong các sự kiện tiếp theo.

**Lợi ích:**
- Ngăn chặn kết nối trái phép từ các client không được xác thực
- Đảm bảo mỗi socket chỉ có thể thực hiện các hành động với quyền của người dùng đã xác thực

### 3.3. Mã hóa tin nhắn với AES

Một trong những tính năng bảo mật quan trọng nhất là mã hóa nội dung tin nhắn trước khi gửi. Hệ thống sử dụng thuật toán AES (Advanced Encryption Standard) với chế độ CBC (Cipher Block Chaining) và IV (Initialization Vector) ngẫu nhiên.

**Quy trình mã hóa:**
1. Khi người dùng gửi tin nhắn, client tạo một khóa mã hóa dựa trên ID của nhóm chat
2. Client tạo một IV ngẫu nhiên (16 bytes) cho mỗi tin nhắn
3. Nội dung tin nhắn được mã hóa bằng AES với khóa và IV này
4. IV và dữ liệu đã mã hóa được kết hợp và mã hóa Base64 để truyền tải
5. Chỉ nội dung đã mã hóa được gửi đến server và lưu trữ trong database

**Quy trình giải mã:**
1. Khi nhận tin nhắn, client trích xuất IV và dữ liệu đã mã hóa
2. Client tạo lại khóa mã hóa dựa trên ID nhóm chat (giống như khi mã hóa)
3. Sử dụng khóa và IV để giải mã nội dung
4. Hiển thị nội dung đã giải mã cho người dùng

**Lợi ích:**
- Ngay cả khi ai đó có quyền truy cập vào database, họ cũng không thể đọc được nội dung tin nhắn
- Mỗi nhóm chat có khóa mã hóa riêng, đảm bảo tính bảo mật độc lập
- IV ngẫu nhiên đảm bảo rằng cùng một tin nhắn sẽ được mã hóa khác nhau mỗi lần

### 3.4. Kiểm tra quyền thành viên

Trước khi cho phép người dùng gửi tin nhắn hoặc tham gia vào một nhóm chat, hệ thống kiểm tra xem người dùng có phải là thành viên của nhóm đó không. Điều này được thực hiện bằng cách truy vấn bảng `chat_group_members` trong database.

**Các điểm kiểm tra:**
- Khi gửi tin nhắn: Server kiểm tra xem user_id có trong danh sách thành viên của nhóm không
- Khi lấy danh sách tin nhắn: Chỉ thành viên mới có thể xem tin nhắn của nhóm
- Khi lấy danh sách thành viên: Chỉ thành viên mới có thể xem danh sách thành viên

**Lợi ích:**
- Ngăn chặn người dùng gửi tin nhắn vào các nhóm họ không thuộc về
- Bảo vệ quyền riêng tư của các nhóm chat
- Đảm bảo tính toàn vẹn của dữ liệu

### 3.5. Phân quyền dựa trên vai trò

Hệ thống có các vai trò khác nhau (giảng viên, sinh viên) với các quyền khác nhau:

- **Giảng viên (Lecturer):**
  - Tạo nhóm chat cho lớp học của mình
  - Thêm/xóa thành viên khỏi nhóm chat
  - Chỉ có thể tạo nhóm chat cho các lớp mà họ là giảng viên

- **Sinh viên (Student):**
  - Tham gia nhóm chat (tự động khi đăng ký lớp)
  - Gửi và nhận tin nhắn trong các nhóm họ là thành viên
  - Không thể tạo nhóm chat hoặc quản lý thành viên

**Lợi ích:**
- Đảm bảo chỉ những người có quyền mới có thể thực hiện các hành động quản lý
- Ngăn chặn việc lạm dụng quyền
- Duy trì trật tự và cấu trúc của hệ thống

### 3.6. Lưu trữ token an toàn

Trên client (Flutter), token JWT được lưu trữ trong Flutter Secure Storage, một cơ chế lưu trữ an toàn sử dụng Keychain trên iOS và Keystore trên Android. Điều này đảm bảo rằng token không thể bị truy cập bởi các ứng dụng khác hoặc bị đọc từ bộ nhớ không an toàn.

**Lợi ích:**
- Bảo vệ token khỏi các cuộc tấn công trên thiết bị
- Tuân thủ các tiêu chuẩn bảo mật của nền tảng di động
- Giảm nguy cơ token bị đánh cắp

### 3.7. Room-based Broadcasting

Khi một tin nhắn được gửi, server chỉ phát sóng tin nhắn đó đến các client đã tham gia vào "room" tương ứng với nhóm chat. Điều này đảm bảo rằng:
- Chỉ thành viên của nhóm mới nhận được tin nhắn
- Tin nhắn không bị rò rỉ đến các nhóm khác
- Giảm tải mạng không cần thiết

---

## 4. ẢNH HƯỞNG VÀ TẦM QUAN TRỌNG

### 4.1. Bảo vệ quyền riêng tư

Cơ chế mã hóa đảm bảo rằng nội dung tin nhắn chỉ có thể được đọc bởi các thành viên của nhóm chat. Ngay cả quản trị viên hệ thống hoặc người có quyền truy cập database cũng không thể đọc được nội dung tin nhắn nếu không có khóa mã hóa.

### 4.2. Ngăn chặn tấn công

Các cơ chế xác thực và phân quyền ngăn chặn nhiều loại tấn công:
- **Tấn công giả mạo (Spoofing)**: Không thể giả mạo danh tính người dùng do yêu cầu JWT hợp lệ
- **Tấn công nghe lén (Eavesdropping)**: Nội dung đã được mã hóa, kẻ tấn công không thể đọc được
- **Tấn công Man-in-the-Middle**: JWT và mã hóa bảo vệ dữ liệu trong quá trình truyền
- **Tấn công truy cập trái phép**: Kiểm tra quyền thành viên ngăn chặn truy cập vào các nhóm không được phép

### 4.3. Tuân thủ quy định

Với việc mã hóa dữ liệu và bảo vệ quyền riêng tư, hệ thống có thể tuân thủ các quy định về bảo vệ dữ liệu cá nhân như GDPR (General Data Protection Regulation) ở mức độ nhất định.

### 4.4. Xây dựng niềm tin

Khi người dùng biết rằng tin nhắn của họ được bảo vệ bằng mã hóa và chỉ có thể được đọc bởi những người được phép, họ sẽ tin tưởng hệ thống hơn và sẵn sàng sử dụng nó cho các cuộc trò chuyện quan trọng.

### 4.5. Bảo vệ dữ liệu nhạy cảm

Trong môi trường giáo dục, có thể có các thông tin nhạy cảm được trao đổi qua chat (điểm số, đánh giá, thông tin cá nhân). Cơ chế bảo mật đảm bảo rằng những thông tin này được bảo vệ khỏi việc truy cập trái phép.

---

## 5. KẾT LUẬN

Hệ thống chat trong LMS được xây dựng với nhiều lớp bảo mật để đảm bảo tính bảo mật, tính toàn vẹn và tính khả dụng của dữ liệu. Các cơ chế bảo mật được triển khai bao gồm:

1. **Xác thực JWT** cho cả API REST và Socket.IO
2. **Mã hóa AES** cho nội dung tin nhắn
3. **Kiểm tra quyền thành viên** trước mọi thao tác
4. **Phân quyền dựa trên vai trò** để kiểm soát quyền truy cập
5. **Lưu trữ token an toàn** trên thiết bị di động
6. **Room-based broadcasting** để đảm bảo tin nhắn chỉ đến đúng người nhận

Những cơ chế này làm việc cùng nhau để tạo ra một hệ thống chat an toàn, đáng tin cậy, phù hợp cho môi trường giáo dục nơi quyền riêng tư và bảo mật thông tin là ưu tiên hàng đầu.

Việc triển khai các cơ chế bảo mật này không chỉ bảo vệ người dùng khỏi các mối đe dọa bảo mật mà còn xây dựng niềm tin và đảm bảo tuân thủ các quy định về bảo vệ dữ liệu. Đây là nền tảng quan trọng cho sự phát triển và mở rộng của hệ thống trong tương lai.

---

**Tài liệu này cung cấp cái nhìn tổng quan về các cơ chế bảo mật trong hệ thống chat. Để biết thêm chi tiết kỹ thuật và code implementation, vui lòng tham khảo tài liệu "BAO_CAO_BAO_MAT_CHAT_CHUYEN_SAU.md".**

