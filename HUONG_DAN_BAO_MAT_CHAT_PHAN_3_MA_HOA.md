# HƯỚNG DẪN CHUYÊN SÂU VỀ BẢO MẬT CHAT - PHẦN 3: MÃ HÓA TIN NHẮN TỪNG BƯỚC

## MỤC LỤC

1. [Mã hóa là gì và tại sao cần nó?](#1-mã-hóa-là-gì-và-tại-sao-cần-nó)
2. [AES Encryption - Khái niệm cơ bản](#2-aes-encryption---khái-niệm-cơ-bản)
3. [Cách tạo khóa mã hóa](#3-cách-tạo-khóa-mã-hóa)
4. [Cách mã hóa tin nhắn - Code chi tiết](#4-cách-mã-hóa-tin-nhắn---code-chi-tiết)
5. [Cách giải mã tin nhắn - Code chi tiết](#5-cách-giải-mã-tin-nhắn---code-chi-tiết)
6. [Ví dụ thực tế từng bước](#6-ví-dụ-thực-tế-từng-bước)
7. [Tại sao dùng IV ngẫu nhiên?](#7-tại-sao-dùng-iv-ngẫu-nhiên)

---

## 1. MÃ HÓA LÀ GÌ VÀ TẠI SAO CẦN NÓ?

### 1.1. Vấn đề không có mã hóa

**Tình huống:**
- Bạn gửi tin nhắn: "Mật khẩu WiFi là 123456"
- Tin nhắn được gửi qua internet
- Hacker có thể "nghe" được dữ liệu đang truyền
- Hacker đọc được: "Mật khẩu WiFi là 123456" ❌

**Nếu lưu vào database:**
- Database lưu: "Mật khẩu WiFi là 123456"
- Nếu hacker có quyền truy cập database
- Hacker đọc được tất cả tin nhắn ❌

### 1.2. Giải pháp: Mã hóa

**Với mã hóa:**
- Bạn gửi tin nhắn: "Mật khẩu WiFi là 123456"
- **Mã hóa** thành: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
- Gửi qua internet: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
- Hacker "nghe" được: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
- Hacker **KHÔNG ĐỌC ĐƯỢC** ✅

**Lưu vào database:**
- Database lưu: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
- Nếu hacker có quyền truy cập database
- Hacker chỉ thấy: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
- Hacker **KHÔNG ĐỌC ĐƯỢC** ✅

**Chỉ người có khóa mới giải mã được:**
- Người nhận có khóa → Giải mã → "Mật khẩu WiFi là 123456" ✅
- Hacker không có khóa → Không giải mã được ❌

### 1.3. Mã hóa đối xứng vs Bất đối xứng

**Mã hóa đối xứng (Symmetric Encryption):**
- Dùng **CÙNG MỘT KHÓA** để mã hóa và giải mã
- Ví dụ: AES
- ✅ Nhanh
- ❌ Phải chia sẻ khóa an toàn

**Mã hóa bất đối xứng (Asymmetric Encryption):**
- Dùng **2 KHÓA KHÁC NHAU**: Public key và Private key
- Ví dụ: RSA
- ✅ Không cần chia sẻ private key
- ❌ Chậm hơn

**Hệ thống chat dùng:** Mã hóa đối xứng (AES) vì:
- Nhanh (quan trọng cho real-time chat)
- Đủ an toàn cho mục đích này
- Dễ triển khai

---

## 2. AES ENCRYPTION - KHÁI NIỆM CƠ BẢN

### 2.1. AES là gì?

**AES = Advanced Encryption Standard**
- Là thuật toán mã hóa được sử dụng rộng rãi nhất
- Được chính phủ Mỹ sử dụng để bảo vệ thông tin mật
- Có 3 phiên bản: AES-128, AES-192, AES-256
- Hệ thống dùng **AES-256** (256-bit key = rất mạnh!)

### 2.2. Cách AES hoạt động (đơn giản hóa)

```
Input: "Xin chào" (Plaintext)
Key: "chat_group_5" (sau khi hash thành 256-bit)
        ↓
AES Encryption
        ↓
Output: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT" (Ciphertext)
```

**Quy trình:**
1. Chia plaintext thành các block 16 bytes
2. Mỗi block được mã hóa với key
3. Kết hợp các block đã mã hóa thành ciphertext

### 2.3. CBC Mode (Cipher Block Chaining)

**Vấn đề với ECB Mode (không dùng):**
- Cùng một block → Cùng một ciphertext
- Dễ phát hiện pattern

**Giải pháp: CBC Mode:**
- Mỗi block phụ thuộc vào block trước
- Cùng một block → Ciphertext khác nhau (tùy block trước)
- An toàn hơn!

**Cần IV (Initialization Vector):**
- Block đầu tiên cần IV (16 bytes ngẫu nhiên)
- IV không cần bí mật, nhưng phải ngẫu nhiên
- Đảm bảo cùng một message mã hóa khác nhau mỗi lần

---

## 3. CÁCH TẠO KHÓA MÃ HÓA

### 3.1. Vấn đề: Cần khóa 256-bit

**Yêu cầu:**
- AES-256 cần khóa 256-bit (32 bytes)
- Nhưng group ID chỉ là số (ví dụ: 5)
- Làm sao tạo khóa 256-bit từ group ID?

**Giải pháp: Hash với SHA-256**

### 3.2. Code tạo khóa

**File: `lms_mobile/lib/features/chat/services/encryption_service.dart`**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';  // Thư viện hash

class EncryptionService {
  /// Tạo khóa mã hóa từ group ID
  /// 
  /// Input: groupId = 5
  /// Output: Key object (256-bit)
  encrypt.Key _generateKeyFromGroupId(int groupId) {
    // BƯỚC 1: Tạo key string từ group ID
    // Ví dụ: groupId = 5 → keyString = "chat_group_5"
    final keyString = 'chat_group_$groupId';
    
    // BƯỚC 2: Convert string sang UTF-8 bytes
    // "chat_group_5" → [99, 104, 97, 116, 95, 103, 114, 111, 117, 112, 95, 53]
    final bytes = utf8.encode(keyString);
    
    // BƯỚC 3: Hash bằng SHA-256
    // SHA-256 luôn cho kết quả 256-bit (32 bytes)
    // Ví dụ: SHA256([99, 104, 97, 116, ...]) → [0x1A, 0x2B, 0x3C, ...] (32 bytes)
    final hash = sha256.convert(bytes);
    
    // BƯỚC 4: Convert hash bytes thành Key object
    // [0x1A, 0x2B, 0x3C, ...] → Key object (32 bytes cho AES-256)
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }
}
```

### 3.3. Ví dụ từng bước

**Input:**
```dart
groupId = 5
```

**Bước 1: Tạo key string**
```dart
keyString = 'chat_group_5'
// String: "chat_group_5"
```

**Bước 2: Encode sang UTF-8 bytes**
```dart
bytes = utf8.encode('chat_group_5')
// [99, 104, 97, 116, 95, 103, 114, 111, 117, 112, 95, 53]
//  c   h   a   t   _   g   r   o   u   p   _   5
```

**Bước 3: Hash bằng SHA-256**
```dart
hash = sha256.convert(bytes)
// SHA-256 luôn cho 32 bytes
// Ví dụ: [0x1A, 0x2B, 0x3C, 0x4D, 0x5E, 0x6F, 0x70, 0x81, ...] (32 bytes)
```

**Bước 4: Convert thành Key**
```dart
key = encrypt.Key(Uint8List.fromList(hash.bytes))
// Key object với 32 bytes (256-bit) - phù hợp cho AES-256
```

### 3.4. Tại sao dùng SHA-256?

**Ưu điểm:**
- ✅ **Deterministic**: Cùng group ID → Cùng khóa (cả client và server có thể tạo lại)
- ✅ **Uniform distribution**: SHA-256 tạo ra 256-bit key phù hợp cho AES-256
- ✅ **One-way**: Không thể reverse từ hash về group ID
- ✅ **Collision-resistant**: Rất khó tìm 2 group ID có cùng hash

**Ví dụ:**
```dart
// Group 5
keyString = "chat_group_5"
hash = SHA256(keyString)  // → [0x1A, 0x2B, ...] (32 bytes)

// Group 6
keyString = "chat_group_6"
hash = SHA256(keyString)  // → [0x9F, 0x8E, ...] (32 bytes) - KHÁC HOÀN TOÀN!
```

---

## 4. CÁCH MÃ HÓA TIN NHẮN - CODE CHI TIẾT

### 4.1. File: `lms_mobile/lib/features/chat/services/encryption_service.dart`

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  /// Mã hóa tin nhắn
  /// 
  /// Input: 
  ///   - message: "Xin chào mọi người!" (Plaintext)
  ///   - groupId: 5
  /// 
  /// Output: 
  ///   - "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0=" (Base64 encoded)
  Future<String> encryptMessage(String message, int groupId) async {
    try {
      // BƯỚC 1: Tạo khóa mã hóa từ group ID
      // Sử dụng hàm _generateKeyFromGroupId() đã viết ở trên
      final key = _generateKeyFromGroupId(groupId);
      // key = Key object (32 bytes, 256-bit)
      
      // BƯỚC 2: Tạo IV (Initialization Vector) ngẫu nhiên
      // IV = 16 bytes ngẫu nhiên
      // Mỗi lần mã hóa, IV khác nhau → Ciphertext khác nhau
      final iv = encrypt.IV.fromLength(16);
      // iv = IV object với 16 bytes ngẫu nhiên
      // Ví dụ: [0x1A, 0x2B, 0x3C, 0x4D, 0x5E, 0x6F, 0x70, 0x81, ...]
      
      // BƯỚC 3: Tạo encrypter với AES
      // Encrypter sử dụng AES-256-CBC mode
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      // encrypter = Encrypter object với AES-256-CBC
      
      // BƯỚC 4: Mã hóa message
      // encrypter.encrypt() sẽ:
      // 1. Chia message thành các block 16 bytes
      // 2. Mã hóa từng block với AES-256-CBC
      // 3. Kết hợp các block đã mã hóa
      final encrypted = encrypter.encrypt(message, iv: iv);
      // encrypted = Encrypted object chứa ciphertext
      
      // BƯỚC 5: Kết hợp IV và encrypted data
      // Tại sao cần IV? Vì khi giải mã, cần IV để giải mã block đầu tiên
      // IV không cần bí mật, nhưng phải gửi kèm với encrypted data
      final combined = {
        'iv': base64Encode(iv.bytes),      // IV dạng Base64
        'data': encrypted.base64,          // Encrypted data dạng Base64
      };
      // combined = {
      //   'iv': 'Gi1sPA==',           // IV đã encode Base64
      //   'data': 'xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT'
      // }
      
      // BƯỚC 6: Encode toàn bộ thành JSON, rồi Base64
      // Tại sao Base64? Để có thể truyền qua network và lưu vào database dễ dàng
      // Base64 chỉ chứa ký tự ASCII (A-Z, a-z, 0-9, +, /, =)
      final jsonString = json.encode(combined);
      // jsonString = '{"iv":"Gi1sPA==","data":"xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}'
      
      final finalOutput = base64Encode(utf8.encode(jsonString));
      // finalOutput = "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
      
      return finalOutput;
      
    } catch (e) {
      print('Encryption error: $e');
      rethrow;  // Throw exception để caller xử lý
    }
  }
}
```

### 4.2. Ví dụ từng bước chi tiết

**Input:**
```dart
message = "Xin chào mọi người!"
groupId = 5
```

**Bước 1: Tạo khóa**
```dart
keyString = "chat_group_5"
bytes = utf8.encode(keyString)  // [99, 104, 97, 116, 95, 103, 114, 111, 117, 112, 95, 53]
hash = sha256.convert(bytes)    // [0x1A, 0x2B, 0x3C, ...] (32 bytes)
key = encrypt.Key(hash.bytes)  // Key object (256-bit)
```

**Bước 2: Tạo IV ngẫu nhiên**
```dart
iv = encrypt.IV.fromLength(16)
// IV = [0x1A, 0x2B, 0x3C, 0x4D, 0x5E, 0x6F, 0x70, 0x81, 0x92, 0xA3, 0xB4, 0xC5, 0xD6, 0xE7, 0xF8, 0x09]
// Mỗi lần chạy, IV khác nhau!
```

**Bước 3: Tạo encrypter**
```dart
encrypter = encrypt.Encrypter(encrypt.AES(key))
// Encrypter với AES-256-CBC mode
```

**Bước 4: Mã hóa**
```dart
encrypted = encrypter.encrypt("Xin chào mọi người!", iv: iv)
// encrypted.base64 = "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
```

**Bước 5: Kết hợp IV và data**
```dart
combined = {
  'iv': base64Encode(iv.bytes),           // "Gi1sPA=="
  'data': encrypted.base64                // "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
}
```

**Bước 6: Encode Base64**
```dart
jsonString = json.encode(combined)
// '{"iv":"Gi1sPA==","data":"xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}'

finalOutput = base64Encode(utf8.encode(jsonString))
// "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
```

**Output:**
```
"eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
```

---

## 5. CÁCH GIẢI MÃ TIN NHẮN - CODE CHI TIẾT

### 5.1. File: `lms_mobile/lib/features/chat/services/encryption_service.dart`

```dart
/// Giải mã tin nhắn
/// 
/// Input: 
///   - encryptedMessage: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
///   - groupId: 5
/// 
/// Output: 
///   - "Xin chào mọi người!" (Plaintext)
Future<String> decryptMessage(String encryptedMessage, int groupId) async {
  try {
    // BƯỚC 1: Tạo lại khóa (phải giống như khi mã hóa)
    // Sử dụng cùng group ID → Cùng key string → Cùng hash → Cùng key
    final key = _generateKeyFromGroupId(groupId);
    // key = Key object (32 bytes, 256-bit) - GIỐNG như khi mã hóa
    
    // BƯỚC 2: Decode Base64 để lấy JSON string
    // "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
    // → '{"iv":"Gi1sPA==","data":"xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}'
    final decodedMessage = utf8.decode(base64Decode(encryptedMessage));
    
    // BƯỚC 3: Parse JSON để tách IV và encrypted data
    // '{"iv":"Gi1sPA==","data":"xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}'
    // → {"iv": "Gi1sPA==", "data": "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}
    final combined = json.decode(decodedMessage);
    
    // BƯỚC 4: Decode IV và encrypted data từ Base64
    // IV: "Gi1sPA==" → [0x1A, 0x2B, 0x3C, ...] (16 bytes)
    final iv = encrypt.IV(base64Decode(combined['iv']));
    
    // Encrypted data: "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
    // → Encrypted object
    final encryptedData = encrypt.Encrypted.fromBase64(combined['data']);
    
    // BƯỚC 5: Tạo encrypter (cùng khóa)
    // Phải dùng cùng key như khi mã hóa!
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    // BƯỚC 6: Giải mã
    // encrypter.decrypt() sẽ:
    // 1. Chia encrypted data thành các block 16 bytes
    // 2. Giải mã từng block với AES-256-CBC
    // 3. Kết hợp các block đã giải mã
    final decrypted = encrypter.decrypt(encryptedData, iv: iv);
    // decrypted = "Xin chào mọi người!"
    
    return decrypted;
    
  } catch (e) {
    print('Decryption error: $e');
    // Trả về message lỗi thay vì throw exception
    // Vì nếu throw, app có thể crash
    return '[Không thể giải mã tin nhắn]';
  }
}
```

### 5.2. Ví dụ từng bước chi tiết

**Input:**
```dart
encryptedMessage = "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
groupId = 5
```

**Bước 1: Tạo lại khóa**
```dart
key = _generateKeyFromGroupId(5)
// Cùng như khi mã hóa: Key object (32 bytes, 256-bit)
```

**Bước 2: Decode Base64**
```dart
decodedMessage = utf8.decode(base64Decode("eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="))
// '{"iv":"Gi1sPA==","data":"xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"}'
```

**Bước 3: Parse JSON**
```dart
combined = json.decode(decodedMessage)
// {
//   "iv": "Gi1sPA==",
//   "data": "xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT"
// }
```

**Bước 4: Decode IV và data**
```dart
iv = encrypt.IV(base64Decode("Gi1sPA=="))
// IV = [0x1A, 0x2B, 0x3C, ...] (16 bytes) - GIỐNG như khi mã hóa

encryptedData = encrypt.Encrypted.fromBase64("xK9j2LmN3pQ4rS5tU6vW7xY8zA9bC0dE1fG2hI3jK4lM5nO6pP7qQ8rR9sS0tT")
// Encrypted object
```

**Bước 5: Tạo encrypter**
```dart
encrypter = encrypt.Encrypter(encrypt.AES(key))
// Cùng key như khi mã hóa
```

**Bước 6: Giải mã**
```dart
decrypted = encrypter.decrypt(encryptedData, iv: iv)
// "Xin chào mọi người!"
```

**Output:**
```
"Xin chào mọi người!"
```

---

## 6. VÍ DỤ THỰC TẾ TỪNG BƯỚC

### 6.1. Kịch bản: User A gửi tin nhắn cho nhóm 5

**Bước 1: User A nhập tin nhắn**
```dart
// User A nhập trên UI
message = "Xin chào mọi người!"
groupId = 5
```

**Bước 2: Client mã hóa**
```dart
final encryptionService = EncryptionService();
final encrypted = await encryptionService.encryptMessage(message, groupId);
// encrypted = "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
```

**Bước 3: Client gửi đến server**
```dart
// Gửi qua Socket.IO
socket.emit('send_message', {
  'group_id': 5,
  'encrypted_content': "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
});
```

**Bước 4: Server lưu vào database**
```python
# Server KHÔNG giải mã!
# Chỉ lưu encrypted_content
message = ChatMessage(
    group_id=5,
    sender_id=10,  # User A
    encrypted_content="eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
)
db.add(message)
db.commit()
```

**Bước 5: Server broadcast đến các thành viên**
```python
# Gửi encrypted_content (KHÔNG giải mã!)
await sio.emit('new_message', {
    'id': 123,
    'group_id': 5,
    'sender_id': 10,
    'encrypted_content': "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
}, room="group_5")
```

**Bước 6: Client nhận và giải mã**
```dart
// Client nhận message
socket.on('new_message', (data) {
  final encryptedContent = data['encrypted_content'];
  final groupId = data['group_id'];
  
  // Giải mã
  final decrypted = await encryptionService.decryptMessage(
    encryptedContent, 
    groupId
  );
  // decrypted = "Xin chào mọi người!"
  
  // Hiển thị trên UI
  displayMessage(decrypted);
});
```

### 6.2. Điểm quan trọng

**Server KHÔNG BAO GIỜ thấy plaintext:**
- Server chỉ thấy: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
- Server không thể đọc được: "Xin chào mọi người!"

**Chỉ client mới giải mã được:**
- Client có group ID → Tạo lại khóa → Giải mã
- Server không có khóa → Không giải mã được

**Mỗi nhóm có khóa riêng:**
- Group 5 → Key từ "chat_group_5"
- Group 6 → Key từ "chat_group_6"
- Khác nhau hoàn toàn!

---

## 7. TẠI SAO DÙNG IV NGẪU NHIÊN?

### 7.1. Vấn đề nếu không có IV

**Nếu dùng cùng IV mỗi lần:**
```
Message 1: "Xin chào"
Key: "chat_group_5"
IV: [0x00, 0x00, ...] (cố định)
→ Encrypted: "ABC123..."

Message 2: "Xin chào" (cùng message)
Key: "chat_group_5"
IV: [0x00, 0x00, ...] (cùng IV)
→ Encrypted: "ABC123..." (CÙNG KẾT QUẢ!)
```

**Vấn đề:**
- Hacker thấy 2 tin nhắn giống nhau → Biết nội dung giống nhau
- Hacker có thể phát hiện pattern

### 7.2. Giải pháp: IV ngẫu nhiên

**Với IV ngẫu nhiên:**
```
Message 1: "Xin chào"
Key: "chat_group_5"
IV: [0x1A, 0x2B, ...] (ngẫu nhiên lần 1)
→ Encrypted: "ABC123..."

Message 2: "Xin chào" (cùng message)
Key: "chat_group_5"
IV: [0x9F, 0x8E, ...] (ngẫu nhiên lần 2)
→ Encrypted: "XYZ789..." (KHÁC KẾT QUẢ!)
```

**Ưu điểm:**
- ✅ Cùng một message → Ciphertext khác nhau mỗi lần
- ✅ Hacker không thể phát hiện pattern
- ✅ An toàn hơn!

**IV không cần bí mật:**
- IV được gửi kèm với encrypted data
- Hacker có thể thấy IV, nhưng không sao
- Quan trọng là IV phải **NGẪU NHIÊN** mỗi lần

---

## TÓM TẮT PHẦN 3

Trong phần này, bạn đã học được:

1. ✅ **Mã hóa là gì** - Chuyển plaintext thành ciphertext không đọc được
2. ✅ **AES Encryption** - Thuật toán mã hóa mạnh, dùng AES-256-CBC
3. ✅ **Cách tạo khóa** - Hash group ID bằng SHA-256 để tạo 256-bit key
4. ✅ **Cách mã hóa** - Sử dụng AES với IV ngẫu nhiên
5. ✅ **Cách giải mã** - Sử dụng cùng key và IV để giải mã
6. ✅ **Tại sao dùng IV ngẫu nhiên** - Đảm bảo cùng message mã hóa khác nhau

**Điểm quan trọng:**
- ✅ Server KHÔNG BAO GIỜ thấy plaintext
- ✅ Mỗi nhóm có khóa riêng
- ✅ IV ngẫu nhiên đảm bảo an toàn

**Tiếp theo:** Phần 4 sẽ hướng dẫn về Socket.IO - cách giao tiếp real-time an toàn!

---

**📌 Lưu ý:** Mã hóa rất quan trọng! Phải:
- ✅ Dùng IV ngẫu nhiên mỗi lần
- ✅ Giữ khóa bí mật (không lộ group ID)
- ✅ Xử lý lỗi khi giải mã thất bại

