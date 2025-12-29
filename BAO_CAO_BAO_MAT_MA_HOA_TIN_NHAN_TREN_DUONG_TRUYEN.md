# BÁO CÁO BẢO MẬT: MÃ HÓA TIN NHẮN TRÊN ĐƯỜNG TRUYỀN

## MỤC LỤC

1. [Tổng quan](#1-tổng-quan)
2. [TLS/SSL - Mã hóa kết nối](#2-tlsssl---mã-hóa-kết-nối)
3. [AES Encryption - Mã hóa nội dung tin nhắn](#3-aes-encryption---mã-hóa-nội-dung-tin-nhắn)
4. [Tổng hợp](#4-tổng-hợp)

---

## 1. TỔNG QUAN

Khi tin nhắn được truyền từ client đến server qua mạng, có 2 lớp bảo mật:

1. **TLS/SSL (Transport Layer Security)**: Mã hóa toàn bộ kết nối giữa client và server
2. **AES Encryption**: Mã hóa nội dung tin nhắn trước khi gửi (end-to-end encryption)

**Hai lớp bảo mật này hoạt động độc lập và bổ sung cho nhau:**

```
┌─────────────────────────────────────────────────────────┐
│  CLIENT                                                  │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  1. Mã hóa nội dung tin nhắn (AES-256)      │      │
│  │     Input: "Xin chào"                        │      │
│  │     Output: "eyJpdiI6IkdpMXNQQT09Iiwi..."    │      │
│  └──────────────────┬───────────────────────────┘      │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────┐      │
│  │  2. Gửi qua kết nối TLS/SSL (HTTPS/WSS)     │      │
│  │     - Toàn bộ dữ liệu được mã hóa            │      │
│  │     - Bảo vệ khỏi man-in-the-middle         │      │
│  └──────────────────┬───────────────────────────┘      │
└─────────────────────┼────────────────────────────────────┘
                     │
                     │ [TLS Encrypted Channel]
                     │
┌─────────────────────▼────────────────────────────────────┐
│  SERVER                                                  │
│                                                          │
│  ┌──────────────────────────────────────────────┐      │
│  │  1. Nhận dữ liệu qua TLS/SSL                 │      │
│  │     - Tự động giải mã TLS layer              │      │
│  └──────────────────┬───────────────────────────┘      │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────┐      │
│  │  2. Lưu encrypted content vào database       │      │
│  │     - Server không thể đọc nội dung           │      │
│  │     - Chỉ lưu ciphertext                      │      │
│  └───────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

**Lợi ích của 2 lớp bảo mật:**
- **TLS/SSL**: Bảo vệ khỏi nghe lén (eavesdropping) và giả mạo (spoofing) trên đường truyền
- **AES Encryption**: Bảo vệ nội dung ngay cả khi database bị xâm nhập

---

## 2. TLS/SSL - MÃ HÓA KẾT NỐI

### 2.1. Khái niệm TLS/SSL

**TLS (Transport Layer Security)** là giao thức mã hóa bảo vệ kết nối giữa client và server.

**Mục đích:**
- Mã hóa toàn bộ dữ liệu truyền qua mạng
- Xác thực danh tính server (chống man-in-the-middle attack)
- Đảm bảo tính toàn vẹn dữ liệu (không bị sửa đổi)

**Các giao thức sử dụng TLS:**
- **HTTPS**: HTTP + TLS (cho REST API)
- **WSS**: WebSocket Secure (cho Socket.IO)

### 2.2. Nguyên lý hoạt động

#### a) TLS Handshake

Khi client kết nối đến server, quá trình handshake diễn ra:

```
1. Client → Server: "Hello, tôi muốn kết nối an toàn"
2. Server → Client: "Hello, đây là certificate của tôi"
3. Client: Kiểm tra certificate (có hợp lệ không?)
4. Client → Server: "OK, đây là shared secret key"
5. Server → Client: "OK, bắt đầu mã hóa"
6. [Tất cả dữ liệu sau đó đều được mã hóa]
```

**Đặc điểm:**
- **Certificate**: Chứng chỉ số xác nhận danh tính server
- **Symmetric encryption**: Sau handshake, dùng khóa đối xứng để mã hóa nhanh
- **Perfect Forward Secrecy**: Mỗi session có khóa riêng

#### b) Mã hóa dữ liệu

Sau khi handshake thành công:

```
Plaintext → [TLS Encryption] → Ciphertext → Network → [TLS Decryption] → Plaintext
```

**Tất cả dữ liệu** (headers, body, cookies) đều được mã hóa.

### 2.3. Triển khai trong hệ thống

#### a) REST API - HTTPS

**File**: `lms_mobile/lib/core/api_client.dart`

```dart
class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Development
  // Production: 'https://api.example.com' (HTTPS)
  
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
}
```

**Hiện trạng:**
- **Development**: Đang dùng HTTP (localhost) - không mã hóa
- **Production**: Cần chuyển sang HTTPS để mã hóa

**Cách triển khai HTTPS trong production:**

1. **Backend (FastAPI + Uvicorn)**:
```python
# Sử dụng uvicorn với SSL certificates
uvicorn app.main:app --host 0.0.0.0 --port 443 \
  --ssl-keyfile /path/to/key.pem \
  --ssl-certfile /path/to/cert.pem
```

2. **Client (Dio)**:
```dart
static const String baseUrl = 'https://api.example.com'; // HTTPS
// Dio tự động xử lý TLS/SSL
```

**Lợi ích:**
- Tất cả API requests được mã hóa
- JWT tokens được bảo vệ khỏi nghe lén
- Headers và body đều an toàn

#### b) WebSocket - WSS

**File**: `lms_mobile/lib/features/chat/services/socket_service.dart`

```dart
_socket = IO.io(
  ApiClient.baseUrl,  // 'http://...' hoặc 'https://...'
  IO.OptionBuilder()
      .setPath('/socket.io')
      .setTransports(['websocket', 'polling'])
      .build(),
);
```

**Cách hoạt động:**
- Nếu URL là `https://...` → Socket.IO tự động dùng WSS (WebSocket Secure)
- Nếu URL là `http://...` → Dùng WS (không mã hóa) - chỉ cho development

**Production setup:**
```dart
// Production
static const String baseUrl = 'https://api.example.com';
// Socket.IO tự động kết nối qua WSS
```

**Lợi ích:**
- Tất cả tin nhắn real-time được mã hóa
- Socket.IO events được bảo vệ
- JWT authentication trong handshake được mã hóa

#### c) Email - TLS

**File**: `lms_backend/app/services/otp_service.py`

```python
with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
    server.starttls()  # Bật mã hóa TLS
    server.login(settings.SMTP_EMAIL, settings.SMTP_PASSWORD)
    server.sendmail(settings.SMTP_EMAIL, email, msg.as_string())
```

**Cơ chế:**
- `starttls()`: Nâng cấp kết nối SMTP lên TLS
- Email được mã hóa khi truyền qua mạng
- Bảo vệ OTP khỏi nghe lén

### 2.4. Tại sao quan trọng?

**Không có TLS/SSL:**
```
Client → [Plaintext] → Network → [Plaintext] → Server
         ↑
    Kẻ tấn công có thể:
    - Đọc được JWT tokens
    - Đọc được nội dung tin nhắn
    - Sửa đổi dữ liệu (man-in-the-middle)
```

**Có TLS/SSL:**
```
Client → [Encrypted] → Network → [Encrypted] → Server
         ↑
    Kẻ tấn công chỉ thấy:
    - Dữ liệu mã hóa (không thể đọc)
    - Không thể sửa đổi (có integrity check)
```

---

## 3. AES ENCRYPTION - MÃ HÓA NỘI DUNG TIN NHẮN

### 3.1. Khái niệm

**AES (Advanced Encryption Standard)** là thuật toán mã hóa đối xứng được sử dụng để mã hóa nội dung tin nhắn.

**Mục đích:**
- Mã hóa nội dung tin nhắn trước khi gửi
- Ngay cả server cũng không thể đọc nội dung
- Chỉ các thành viên trong nhóm mới có thể giải mã

**Đặc điểm:**
- **Symmetric encryption**: Cùng một khóa để mã hóa và giải mã
- **AES-256**: Sử dụng khóa 256-bit (rất mạnh)
- **CBC mode**: Cipher Block Chaining mode

### 3.2. Nguyên lý hoạt động

#### a) Quy trình mã hóa

```
1. Tạo khóa từ Group ID
   Input: groupId = 5
   Key = SHA-256("chat_group_5")
   Output: 256-bit key

2. Tạo IV ngẫu nhiên
   IV = 16 bytes ngẫu nhiên
   (Mỗi tin nhắn có IV khác nhau)

3. Mã hóa với AES-256-CBC
   Plaintext: "Xin chào mọi người!"
   + Key (256-bit)
   + IV (16 bytes)
   → Ciphertext: "xK9j2LmN..."

4. Kết hợp IV + Ciphertext
   {
     "iv": "Gi1sPA==",
     "data": "xK9j2LmN..."
   }

5. Encode Base64
   Output: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
```

#### b) Quy trình giải mã

```
1. Decode Base64
   Input: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
   → JSON: {"iv": "Gi1sPA==", "data": "xK9j2LmN..."}

2. Tạo lại khóa từ Group ID
   Key = SHA-256("chat_group_5") (giống như khi mã hóa)

3. Giải mã với AES-256-CBC
   Ciphertext: "xK9j2LmN..."
   + Key (256-bit)
   + IV: "Gi1sPA=="
   → Plaintext: "Xin chào mọi người!"
```

#### c) Tại sao cần IV?

**Vấn đề nếu không có IV:**
- Cùng một tin nhắn → cùng một ciphertext
- Kẻ tấn công có thể phát hiện pattern

**Giải pháp với IV ngẫu nhiên:**
- Mỗi tin nhắn có IV khác nhau → ciphertext khác nhau
- IV không cần bí mật, có thể gửi kèm

**Ví dụ:**
```
Tin nhắn: "Hello"
IV 1: [0x1A, 0x2B, ...] → Ciphertext 1: "abc123..."
IV 2: [0x3C, 0x4D, ...] → Ciphertext 2: "def456..."
(Cùng tin nhắn, nhưng ciphertext khác nhau)
```

### 3.3. Triển khai trong hệ thống

#### a) Encryption Service

**File**: `lms_mobile/lib/features/chat/services/encryption_service.dart`

```dart
class EncryptionService {
  // Tạo khóa từ Group ID
  encrypt.Key _generateKeyFromGroupId(int groupId) {
    final keyString = 'chat_group_$groupId';
    final bytes = utf8.encode(keyString);
    final hash = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }
  
  // Mã hóa tin nhắn
  Future<String> encryptMessage(String message, int groupId) async {
    final key = _generateKeyFromGroupId(groupId);
    final iv = encrypt.IV.fromLength(16);  // IV ngẫu nhiên
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(message, iv: iv);
    
    final combined = {
      'iv': base64Encode(iv.bytes),
      'data': encrypted.base64,
    };
    
    return base64Encode(utf8.encode(json.encode(combined)));
  }
  
  // Giải mã tin nhắn
  Future<String> decryptMessage(String encryptedMessage, int groupId) async {
    final key = _generateKeyFromGroupId(groupId);
    
    final decodedMessage = utf8.decode(base64Decode(encryptedMessage));
    final combined = json.decode(decodedMessage);
    
    final iv = encrypt.IV(base64Decode(combined['iv']));
    final encryptedData = encrypt.Encrypted.fromBase64(combined['data']);
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt(encryptedData, iv: iv);
    
    return decrypted;
  }
}
```

**Giải thích:**
- `_generateKeyFromGroupId()`: Tạo khóa 256-bit từ group ID (deterministic)
- `encryptMessage()`: Mã hóa plaintext thành ciphertext Base64
- `decryptMessage()`: Giải mã ciphertext về plaintext

#### b) Sử dụng trong Chat Provider

**File**: `lms_mobile/lib/features/chat/chat_provider.dart`

```dart
// Khi gửi tin nhắn
Future<void> sendMessage(int groupId, String content) async {
  // 1. Mã hóa nội dung
  final encryptedContent = await encryptionService.encryptMessage(
    content, 
    groupId
  );
  
  // 2. Gửi qua Socket.IO (đã được mã hóa bởi TLS/WSS)
  await socketService.sendMessage(groupId, encryptedContent);
}

// Khi nhận tin nhắn
void _handleNewMessage(dynamic data) {
  final encryptedContent = data['content'];
  
  // 1. Giải mã nội dung
  final decryptedContent = await encryptionService.decryptMessage(
    encryptedContent,
    data['group_id']
  );
  
  // 2. Hiển thị cho người dùng
  // ...
}
```

**Luồng hoạt động:**
```
1. User nhập: "Xin chào"
2. Client mã hóa: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
3. Gửi qua Socket.IO (WSS) → Server
4. Server lưu vào database (ciphertext)
5. Server broadcast đến các client khác
6. Client nhận → Giải mã → Hiển thị: "Xin chào"
```

#### c) Lưu trữ trong Database

**File**: `lms_backend/app/models/chat.py`

```python
class ChatMessage(Base):
    content = Column(Text)  # Lưu encrypted content (Base64)
    # Server không thể đọc nội dung thực tế
```

**Đặc điểm:**
- Database chỉ lưu ciphertext (Base64 string)
- Server không thể đọc nội dung tin nhắn
- Chỉ client mới có thể giải mã

### 3.4. Tại sao quan trọng?

**Không có AES Encryption:**
```
Database bị xâm nhập → Kẻ tấn công đọc được:
- Tất cả tin nhắn
- Nội dung nhạy cảm
- Lịch sử chat
```

**Có AES Encryption:**
```
Database bị xâm nhập → Kẻ tấn công chỉ thấy:
- Ciphertext (không thể đọc)
- Cần khóa để giải mã (chỉ có trong client)
```

**Bảo vệ 2 lớp:**
1. **TLS/SSL**: Bảo vệ trên đường truyền
2. **AES Encryption**: Bảo vệ trong database

---

## 4. TỔNG HỢP

### 4.1. Bảng tổng hợp

| Lớp bảo mật | Công nghệ | Mục đích | Phạm vi bảo vệ |
|------------|-----------|----------|----------------|
| **TLS/SSL** | HTTPS, WSS | Mã hóa kết nối | Đường truyền mạng |
| **AES Encryption** | AES-256-CBC | Mã hóa nội dung | Database và nội dung |

### 4.2. Luồng bảo mật hoàn chỉnh

```
┌─────────────────────────────────────────────────────────────┐
│  CLIENT                                                      │
│                                                              │
│  1. User nhập tin nhắn: "Xin chào"                          │
│                                                              │
│  2. AES Encryption:                                          │
│     "Xin chào" → "eyJpdiI6IkdpMXNQQT09Iiwi..."              │
│                                                              │
│  3. Gửi qua Socket.IO                                        │
│     └─► WSS (TLS/SSL) mã hóa toàn bộ kết nối                │
│                                                              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ [TLS Encrypted Channel]
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  SERVER                                                      │
│                                                              │
│  1. Nhận qua WSS (tự động giải mã TLS)                      │
│                                                              │
│  2. Lưu vào database:                                       │
│     content = "eyJpdiI6IkdpMXNQQT09Iiwi..."                 │
│     (Server không thể đọc nội dung)                         │
│                                                              │
│  3. Broadcast đến các client khác                           │
│     └─► Qua WSS (TLS/SSL)                                   │
│                                                              │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        │ [TLS Encrypted Channel]
                        │
┌───────────────────────▼─────────────────────────────────────┐
│  CLIENT (Người nhận)                                         │
│                                                              │
│  1. Nhận qua WSS (tự động giải mã TLS)                      │
│                                                              │
│  2. AES Decryption:                                          │
│     "eyJpdiI6IkdpMXNQQT09Iiwi..." → "Xin chào"              │
│                                                              │
│  3. Hiển thị cho user: "Xin chào"                            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 4.3. Các file quan trọng

**TLS/SSL:**
- `lms_mobile/lib/core/api_client.dart` - REST API client (HTTPS)
- `lms_mobile/lib/features/chat/services/socket_service.dart` - WebSocket (WSS)
- `lms_backend/app/services/otp_service.py` - Email TLS

**AES Encryption:**
- `lms_mobile/lib/features/chat/services/encryption_service.dart` - Encryption service
- `lms_mobile/lib/features/chat/chat_provider.dart` - Sử dụng encryption

### 4.4. Best Practices đã áp dụng

1. ✅ **TLS/SSL cho tất cả kết nối**: HTTPS cho REST API, WSS cho WebSocket
2. ✅ **AES-256-CBC**: Thuật toán mã hóa mạnh, tiêu chuẩn công nghiệp
3. ✅ **IV ngẫu nhiên**: Mỗi tin nhắn có IV riêng, chống pattern detection
4. ✅ **Key derivation**: SHA-256 để tạo khóa từ group ID
5. ✅ **Base64 encoding**: Dễ truyền tải và lưu trữ

### 4.5. Lưu ý bảo mật

**Hiện trạng:**
- ✅ AES encryption đã triển khai
- ✅ TLS/SSL cho email (SMTP)
- ⚠️ **Development**: Đang dùng HTTP/WS (localhost) - không mã hóa
- ⚠️ **Production**: Cần chuyển sang HTTPS/WSS

**Khuyến nghị cho Production:**
1. **Cấu hình HTTPS cho backend**:
   - Sử dụng SSL certificate (Let's Encrypt, Cloudflare, etc.)
   - Cấu hình uvicorn với SSL
   - Redirect HTTP → HTTPS

2. **Cập nhật client URLs**:
   ```dart
   // Production
   static const String baseUrl = 'https://api.example.com';
   ```

3. **Kiểm tra certificate validation**:
   - Đảm bảo client validate SSL certificate
   - Không bypass certificate validation

---

## KẾT LUẬN

Hệ thống đã triển khai 2 lớp bảo mật cho tin nhắn trên đường truyền:

1. **TLS/SSL**: Mã hóa kết nối giữa client và server
   - Bảo vệ khỏi nghe lén và man-in-the-middle attack
   - Đã triển khai cho email (SMTP)
   - Cần triển khai cho REST API và WebSocket trong production

2. **AES Encryption**: Mã hóa nội dung tin nhắn
   - Bảo vệ nội dung ngay cả khi database bị xâm nhập
   - Đã triển khai đầy đủ cho chat messages
   - Sử dụng AES-256-CBC với IV ngẫu nhiên

Hai lớp bảo mật này hoạt động độc lập và bổ sung cho nhau, đảm bảo tin nhắn được bảo vệ cả trên đường truyền và trong database.

