# BÁO CÁO CHUYÊN SÂU VỀ CƠ CHẾ BẢO MẬT TRONG CHỨC NĂNG CHAT

## MỤC LỤC

1. [Kiến trúc tổng quan](#1-kiến-trúc-tổng-quan)
2. [Xác thực JWT - Triển khai chi tiết](#2-xác-thực-jwt---triển-khai-chi-tiết)
3. [Mã hóa tin nhắn với AES - Triển khai chi tiết](#3-mã-hóa-tin-nhắn-với-aes---triển-khai-chi-tiết)
4. [Bảo mật Socket.IO - Triển khai chi tiết](#4-bảo-mật-socketio---triển-khai-chi-tiết)
5. [Kiểm tra quyền và phân quyền - Triển khai chi tiết](#5-kiểm-tra-quyền-và-phân-quyền---triển-khai-chi-tiết)
6. [Lưu trữ an toàn trên client](#6-lưu-trữ-an-toàn-trên-client)
7. [Luồng xử lý tin nhắn hoàn chỉnh](#7-luồng-xử-lý-tin-nhắn-hoàn-chỉnh)
8. [Các điểm cần cải thiện và khuyến nghị](#8-các-điểm-cần-cải-thiện-và-khuyến-nghị)

---

## 1. KIẾN TRÚC TỔNG QUAN

### 1.1. Sơ đồ kiến trúc

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│  Flutter Client │         │  FastAPI Server │         │   PostgreSQL    │
│                 │         │                 │         │                 │
│  ┌───────────┐  │         │  ┌───────────┐  │         │  ┌───────────┐  │
│  │   UI      │  │         │  │ REST API  │  │         │  │  Database │  │
│  └─────┬─────┘  │         │  └─────┬─────┘  │         │  └─────┬─────┘  │
│        │        │         │        │        │         │        │        │
│  ┌─────▼─────┐  │         │  ┌─────▼─────┐  │         │        │        │
│  │ Encryption│  │         │  │  JWT Auth │  │         │        │        │
│  │  Service  │  │         │  └─────┬─────┘  │         │        │        │
│  └─────┬─────┘  │         │        │        │         │        │        │
│        │        │         │  ┌─────▼─────┐  │         │        │        │
│  ┌─────▼─────┐  │         │  │ Socket.IO │  │         │        │        │
│  │  Socket   │◄─┼─────────┼─►│  Service  │  │         │        │        │
│  │  Service  │  │ WebSocket│  └─────┬─────┘  │         │        │        │
│  └───────────┘  │         │        │        │         │        │        │
└─────────────────┘         └────────┼────────┘         └────────┼────────┘
                                     │                           │
                                     └───────────────────────────┘
```

### 1.2. Các thành phần chính

- **Client (Flutter)**: 
  - `EncryptionService`: Mã hóa/giải mã tin nhắn
  - `SocketService`: Quản lý kết nối WebSocket
  - `ChatProvider`: Quản lý state và logic chat
  - `ApiClient`: Xử lý HTTP requests với JWT

- **Server (FastAPI)**:
  - `socket_service.py`: Xử lý Socket.IO events và authentication
  - `chat.py` (router): REST API endpoints với JWT authentication
  - `security.py`: JWT token generation và validation
  - `dependencies.py`: Dependency injection cho authentication

- **Database**:
  - `chat_groups`: Lưu thông tin nhóm chat
  - `chat_messages`: Lưu tin nhắn đã mã hóa
  - `chat_group_members`: Lưu danh sách thành viên

---

## 2. XÁC THỰC JWT - TRIỂN KHAI CHI TIẾT

### 2.1. Tạo JWT Token (Backend)

**File: `lms_backend/app/auth/security.py`**

```python
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
import bcrypt
from app.core.config import settings

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Tạo JWT access token
    
    Args:
        data: Dictionary chứa thông tin cần mã hóa (thường là user_id, username)
        expires_delta: Thời gian hết hạn tùy chỉnh (mặc định 30 phút)
    
    Returns:
        str: JWT token đã được mã hóa
    """
    to_encode = data.copy()
    
    # Thiết lập thời gian hết hạn
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Thêm thời gian hết hạn vào payload
    to_encode.update({"exp": expire})
    
    # Mã hóa token với secret key và algorithm
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    
    return encoded_jwt

def decode_access_token(token: str):
    """
    Giải mã và xác minh JWT token
    
    Args:
        token: JWT token string
    
    Returns:
        dict: Payload của token nếu hợp lệ, None nếu không hợp lệ
    """
    try:
        # Giải mã token và xác minh signature
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        # Token không hợp lệ, đã hết hạn, hoặc signature sai
        return None
```

**Giải thích từng bước:**

1. **Tạo payload**: Copy dữ liệu đầu vào và thêm thời gian hết hạn (`exp`)
2. **Mã hóa**: Sử dụng `jwt.encode()` với:
   - `to_encode`: Payload cần mã hóa
   - `settings.SECRET_KEY`: Khóa bí mật (phải giữ bí mật)
   - `algorithm`: Thuật toán mã hóa (HS256 - HMAC SHA-256)
3. **Trả về token**: Token là một string dạng `header.payload.signature`

**Cấu hình (config.py):**

```python
class Settings(BaseSettings):
    SECRET_KEY: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
```

### 2.2. Xác thực JWT trong REST API

**File: `lms_backend/app/auth/dependencies.py`**

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from app.core.config import settings
from app.crud.user import get_user_by_username
from app.database import get_db
from app.schemas.user import TokenData
from app.models.user import User

# OAuth2 scheme để tự động extract token từ header
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(get_db)
) -> User:
    """
    Dependency function để xác thực user từ JWT token
    
    Quy trình:
    1. FastAPI tự động extract token từ Authorization header
    2. Giải mã token để lấy username
    3. Tìm user trong database
    4. Trả về user object hoặc raise exception
    
    Args:
        token: JWT token (tự động extract từ header)
        db: Database session
    
    Returns:
        User: User object nếu xác thực thành công
    
    Raises:
        HTTPException: Nếu token không hợp lệ hoặc user không tồn tại
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Bước 1: Giải mã token
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        
        # Bước 2: Lấy username từ payload
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        
        # Bước 3: Tạo TokenData object
        token_data = TokenData(username=username)
        
    except JWTError:
        # Token không hợp lệ
        raise credentials_exception
    
    # Bước 4: Tìm user trong database
    user = get_user_by_username(db, username=token_data.username)
    if user is None:
        raise credentials_exception
    
    # Bước 5: Trả về user object
    return user
```

**Sử dụng trong router:**

```python
from app.auth.dependencies import get_current_user

@router.get("/groups", response_model=List[ChatGroupResponse])
def get_chat_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)  # ← Tự động xác thực
):
    # current_user đã được xác thực, có thể sử dụng an toàn
    memberships = db.query(ChatGroupMember).filter(
        ChatGroupMember.user_id == current_user.id
    ).all()
    # ...
```

**Luồng xử lý:**

```
Client Request
    │
    ├─► Authorization: Bearer <token>
    │
    ▼
FastAPI Router
    │
    ├─► Depends(get_current_user)
    │       │
    │       ├─► OAuth2PasswordBearer extract token
    │       │
    │       ├─► jwt.decode(token)
    │       │       │
    │       │       ├─► Verify signature
    │       │       ├─► Check expiration
    │       │       └─► Extract payload
    │       │
    │       ├─► get_user_by_username(db, username)
    │       │
    │       └─► Return User object
    │
    ▼
Handler Function (với current_user đã xác thực)
```

### 2.3. Gửi JWT Token từ Client

**File: `lms_mobile/lib/core/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://localhost:8000';
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    // Thêm interceptor để tự động thêm JWT token vào mọi request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Bước 1: Lấy token từ secure storage
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');

          // Bước 2: Thêm token vào Authorization header
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Xử lý lỗi (có thể refresh token ở đây)
          return handler.next(e);
        },
      ),
    );
  }

  Dio get client => _dio;
}
```

**Giải thích:**

1. **Interceptor**: Dio interceptor tự động chạy trước mỗi request
2. **Lấy token**: Đọc token từ SharedPreferences (được lưu khi login)
3. **Thêm header**: Thêm `Authorization: Bearer <token>` vào request headers
4. **Tự động**: Không cần thêm token thủ công cho mỗi request

---

## 3. MÃ HÓA TIN NHẮN VỚI AES - TRIỂN KHAI CHI TIẾT

### 3.1. Tổng quan về AES Encryption

AES (Advanced Encryption Standard) là thuật toán mã hóa đối xứng được sử dụng rộng rãi. Hệ thống sử dụng:
- **Algorithm**: AES-256 (256-bit key)
- **Mode**: CBC (Cipher Block Chaining)
- **IV**: 16-byte random Initialization Vector cho mỗi tin nhắn
- **Key derivation**: SHA-256 hash của `"chat_group_{groupId}"`

### 3.2. Triển khai Encryption Service (Client)

**File: `lms_mobile/lib/features/chat/services/encryption_service.dart`**

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class EncryptionService {
  final _storage = const FlutterSecureStorage();
  
  /// Tạo khóa mã hóa từ group ID
  /// 
  /// Quy trình:
  /// 1. Tạo string "chat_group_{groupId}"
  /// 2. Convert sang UTF-8 bytes
  /// 3. Hash bằng SHA-256
  /// 4. Convert hash bytes thành Key object
  encrypt.Key _generateKeyFromGroupId(int groupId) {
    // Bước 1: Tạo key string
    final keyString = 'chat_group_$groupId';
    
    // Bước 2: Encode sang UTF-8 bytes
    final bytes = utf8.encode(keyString);
    
    // Bước 3: Hash bằng SHA-256 (luôn cho kết quả 256-bit = 32 bytes)
    final hash = sha256.convert(bytes);
    
    // Bước 4: Convert hash bytes thành Key object (32 bytes cho AES-256)
    return encrypt.Key(Uint8List.fromList(hash.bytes));
  }
  
  /// Mã hóa tin nhắn
  /// 
  /// Input: Plaintext message + Group ID
  /// Output: Base64 encoded string chứa IV + Encrypted data
  /// 
  /// Quy trình:
  /// 1. Tạo khóa từ group ID
  /// 2. Tạo IV ngẫu nhiên (16 bytes)
  /// 3. Mã hóa message với AES-256-CBC
  /// 4. Kết hợp IV và encrypted data
  /// 5. Encode Base64 để truyền tải
  Future<String> encryptMessage(String message, int groupId) async {
    try {
      // Bước 1: Tạo khóa mã hóa
      final key = _generateKeyFromGroupId(groupId);
      
      // Bước 2: Tạo IV ngẫu nhiên (16 bytes cho AES)
      final iv = encrypt.IV.fromLength(16);
      
      // Bước 3: Tạo encrypter với AES
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Bước 4: Mã hóa message
      final encrypted = encrypter.encrypt(message, iv: iv);
      
      // Bước 5: Kết hợp IV và encrypted data
      final combined = {
        'iv': base64Encode(iv.bytes),      // IV dạng Base64
        'data': encrypted.base64,          // Encrypted data dạng Base64
      };
      
      // Bước 6: Encode toàn bộ thành JSON, rồi Base64
      return base64Encode(utf8.encode(json.encode(combined)));
      
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }
  
  /// Giải mã tin nhắn
  /// 
  /// Input: Base64 encoded encrypted message + Group ID
  /// Output: Plaintext message
  /// 
  /// Quy trình:
  /// 1. Decode Base64 để lấy JSON string
  /// 2. Parse JSON để tách IV và encrypted data
  /// 3. Tạo lại khóa từ group ID
  /// 4. Giải mã với AES-256-CBC
  Future<String> decryptMessage(String encryptedMessage, int groupId) async {
    try {
      // Bước 1: Tạo lại khóa (phải giống như khi mã hóa)
      final key = _generateKeyFromGroupId(groupId);
      
      // Bước 2: Decode Base64 để lấy JSON string
      final decodedMessage = utf8.decode(base64Decode(encryptedMessage));
      
      // Bước 3: Parse JSON để tách IV và data
      final combined = json.decode(decodedMessage);
      
      // Bước 4: Decode IV và encrypted data từ Base64
      final iv = encrypt.IV(base64Decode(combined['iv']));
      final encryptedData = encrypt.Encrypted.fromBase64(combined['data']);
      
      // Bước 5: Tạo encrypter (cùng khóa)
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Bước 6: Giải mã
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      
      return decrypted;
      
    } catch (e) {
      print('Decryption error: $e');
      // Trả về message lỗi thay vì throw exception
      return '[Không thể giải mã tin nhắn]';
    }
  }
}
```

### 3.3. Ví dụ chi tiết quy trình mã hóa

**Input:**
- Message: `"Xin chào mọi người!"`
- Group ID: `5`

**Bước 1: Tạo khóa**
```dart
keyString = "chat_group_5"
bytes = [99, 104, 97, 116, 95, 103, 114, 111, 117, 112, 95, 53]  // UTF-8
hash = SHA256(bytes)  // 32 bytes hash
key = Key(hash)  // AES-256 key
```

**Bước 2: Tạo IV**
```dart
iv = randomBytes(16)  // Ví dụ: [0x1A, 0x2B, 0x3C, ...]
```

**Bước 3: Mã hóa**
```dart
encrypted = AES.encrypt("Xin chào mọi người!", key, iv)
// Kết quả: Encrypted object chứa ciphertext
```

**Bước 4: Kết hợp và encode**
```dart
combined = {
  'iv': base64Encode(iv),           // "Gi1sPA=="
  'data': encrypted.base64          // "xK9j2LmN..."
}
jsonString = json.encode(combined)   // '{"iv":"Gi1sPA==","data":"xK9j2LmN..."}'
finalOutput = base64Encode(jsonString)  // "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
```

**Output:** Base64 string có thể truyền qua network và lưu vào database

### 3.4. Tại sao sử dụng IV ngẫu nhiên?

**Vấn đề nếu không có IV:**
- Cùng một message sẽ được mã hóa thành cùng một ciphertext
- Kẻ tấn công có thể phát hiện pattern và suy đoán nội dung

**Giải pháp với IV ngẫu nhiên:**
- Mỗi lần mã hóa, IV khác nhau → ciphertext khác nhau
- IV được gửi kèm với encrypted data (không cần bí mật)
- Đảm bảo tính ngẫu nhiên và bảo mật

### 3.5. Tại sao dùng SHA-256 để tạo khóa?

- **Deterministic**: Cùng group ID → cùng khóa (cả client và server có thể tạo lại)
- **Uniform distribution**: SHA-256 tạo ra 256-bit key phù hợp cho AES-256
- **One-way**: Không thể reverse từ hash về group ID
- **Collision-resistant**: Rất khó tìm 2 group ID có cùng hash

---

## 4. BẢO MẬT SOCKET.IO - TRIỂN KHAI CHI TIẾT

### 4.1. Xác thực khi kết nối Socket.IO

**File: `lms_backend/app/services/socket_service.py`**

```python
import socketio
from app.auth.security import decode_access_token
from typing import Dict

sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',
    logger=True,
    engineio_logger=True
)

# Dictionary lưu mapping: socket_id -> user_id
connected_users: Dict[str, int] = {}

@sio.event
async def connect(sid, environ, auth):
    """
    Xử lý khi client kết nối Socket.IO
    
    Args:
        sid: Socket ID (unique identifier cho mỗi connection)
        environ: Environment variables (WSGI environment)
        auth: Authentication data từ client
    
    Returns:
        bool: True nếu xác thực thành công, False nếu thất bại
    """
    try:
        # Bước 1: Kiểm tra auth data
        if not auth or 'token' not in auth:
            print(f"Connection rejected: No token provided (sid: {sid})")
            return False
        
        # Bước 2: Lấy token từ auth
        token = auth['token']
        
        # Bước 3: Giải mã và xác minh token
        payload = decode_access_token(token)
        
        if not payload:
            print(f"Connection rejected: Invalid token (sid: {sid})")
            return False
        
        # Bước 4: Lấy user_id từ payload
        user_id = payload.get('user_id')
        if not user_id:
            print(f"Connection rejected: No user_id in token (sid: {sid})")
            return False
        
        # Bước 5: Lưu mapping socket_id -> user_id
        connected_users[sid] = int(user_id)
        print(f"User {user_id} connected with sid {sid}")
        
        return True
        
    except Exception as e:
        print(f"Connection error: {e}")
        return False
```

**Luồng xử lý:**

```
Client: socket.connect()
    │
    ├─► Send auth: { token: "jwt_token" }
    │
    ▼
Server: connect(sid, environ, auth)
    │
    ├─► Check: auth['token'] exists?
    │       │
    │       ├─► NO → return False (reject connection)
    │       │
    │       └─► YES → Continue
    │
    ├─► decode_access_token(token)
    │       │
    │       ├─► Invalid/Expired → return False
    │       │
    │       └─► Valid → Continue
    │
    ├─► Extract user_id from payload
    │
    ├─► Store: connected_users[sid] = user_id
    │
    └─► return True (accept connection)
```

### 4.2. Client kết nối với authentication

**File: `lms_mobile/lib/features/chat/services/socket_service.dart`**

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';

class SocketService {
  IO.Socket? _socket;
  bool _isConnected = false;
  Function(dynamic)? _messageCallback;
  Function()? onConnectCallback;
  
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    // Kiểm tra nếu đã kết nối
    if (_socket != null) {
      if (_isConnected) return;
      _socket!.connect();
      return;
    }

    // Bước 1: Lấy token từ secure storage
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    print('Connecting to Socket.IO at: ${ApiClient.baseUrl}');
    
    // Bước 2: Tạo socket với authentication
    _socket = IO.io(
      ApiClient.baseUrl,
      IO.OptionBuilder()
          .setPath('/socket.io')
          .setTransports(['websocket', 'polling'])  // Ưu tiên WebSocket
          .enableAutoConnect()
          // Bước 3: Gửi token trong auth object
          .setAuth({'token': token})
          // Bước 4: Thêm token vào headers (backup)
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    // Bước 5: Setup event listeners
    _setupSocketListeners();
    
    // Bước 6: Kết nối
    _socket!.connect();
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('SocketService: Socket connected successfully');
      _isConnected = true;
      
      if (onConnectCallback != null) {
        onConnectCallback!();
      }
    });

    _socket!.onDisconnect((_) {
      print('SocketService: Socket disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((error) {
      print('SocketService: Socket connection error: $error');
      _isConnected = false;
    });
  }
}
```

### 4.3. Xử lý sự kiện gửi tin nhắn với kiểm tra quyền

**File: `lms_backend/app/services/socket_service.py`**

```python
@sio.event
async def send_message(sid, data):
    """
    Xử lý sự kiện gửi tin nhắn
    
    Quy trình bảo mật:
    1. Lấy user_id từ connected_users (đã xác thực khi connect)
    2. Validate input data
    3. Kiểm tra quyền thành viên trong database
    4. Lưu tin nhắn đã mã hóa
    5. Broadcast đến các thành viên trong room
    """
    try:
        # Bước 1: Extract data từ request
        group_id = data.get('group_id')
        encrypted_content = data.get('encrypted_content')
        user_id = connected_users.get(sid)  # ← Lấy từ authenticated session
        
        # Bước 2: Validate input
        if not user_id or not group_id or not encrypted_content:
            return {'success': False, 'error': 'Invalid data'}
        
        # Bước 3: Mở database session
        from app.database import SessionLocal
        db = SessionLocal()
        
        try:
            # Bước 4: KIỂM TRA QUYỀN THÀNH VIÊN
            member = db.query(ChatGroupMember).filter(
                ChatGroupMember.group_id == group_id,
                ChatGroupMember.user_id == user_id
            ).first()
            
            if not member:
                # Người dùng không phải thành viên → từ chối
                return {'success': False, 'error': 'Not a member of this group'}
            
            # Bước 5: Lưu tin nhắn (đã mã hóa từ client)
            message = ChatMessage(
                group_id=group_id,
                sender_id=user_id,
                encrypted_content=encrypted_content  # ← Lưu dạng mã hóa
            )
            db.add(message)
            db.commit()
            db.refresh(message)
            
            # Bước 6: Quản lý số lượng tin nhắn (giữ tối đa 100 tin)
            message_count = db.query(ChatMessage).filter(
                ChatMessage.group_id == group_id
            ).count()
            
            if message_count > 100:
                oldest_messages = db.query(ChatMessage).filter(
                    ChatMessage.group_id == group_id
                ).order_by(ChatMessage.timestamp.asc()).limit(message_count - 100).all()
                
                for old_msg in oldest_messages:
                    db.delete(old_msg)
                db.commit()
            
            # Bước 7: Lấy thông tin người gửi
            user = db.query(User).filter(User.id == user_id).first()
            
            # Bước 8: Tạo message data để broadcast
            message_data = {
                'id': message.id,
                'group_id': message.group_id,
                'sender_id': message.sender_id,
                'sender_name': user.full_name if user else 'Unknown',
                'encrypted_content': message.encrypted_content,  # ← Vẫn là mã hóa
                'timestamp': message.timestamp.isoformat()
            }
            
            # Bước 9: Broadcast đến room (chỉ thành viên mới nhận được)
            room_name = f"group_{group_id}"
            
            # Gửi đến sender (để confirm)
            await sio.emit('new_message', message_data, to=sid)
            
            # Broadcast đến các thành viên khác trong room
            await sio.emit('new_message', message_data, room=room_name, skip_sid=sid)
            
            return {'success': True, 'message': message_data}
            
        finally:
            db.close()
        
    except Exception as e:
        print(f"Send message error: {e}")
        return {'success': False, 'error': str(e)}
```

**Điểm bảo mật quan trọng:**

1. **User ID từ authenticated session**: Không tin tưởng client, lấy từ `connected_users[sid]`
2. **Kiểm tra quyền thành viên**: Query database để xác minh
3. **Room-based broadcasting**: Chỉ gửi đến room tương ứng
4. **Lưu encrypted content**: Server không bao giờ thấy plaintext

### 4.4. Join/Leave Group với kiểm tra

```python
@sio.event
async def join_group(sid, data):
    """
    Tham gia vào một nhóm chat
    
    Bảo mật:
    - Chỉ cần user_id từ authenticated session
    - Không cần kiểm tra quyền ở đây (sẽ kiểm tra khi gửi tin nhắn)
    - Room name dựa trên group_id
    """
    try:
        group_id = data.get('group_id')
        user_id = connected_users.get(sid)
        
        if not user_id or not group_id:
            return {'success': False, 'error': 'Invalid data'}
        
        # Tham gia room (room name = "group_{group_id}")
        room_name = f"group_{group_id}"
        await sio.enter_room(sid, room_name)
        
        print(f"User {user_id} joined group {group_id} (room: {room_name})")
        return {'success': True}
        
    except Exception as e:
        print(f"Join group error: {e}")
        return {'success': False, 'error': str(e)}
```

---

## 5. KIỂM TRA QUYỀN VÀ PHÂN QUYỀN - TRIỂN KHAI CHI TIẾT

### 5.1. Phân quyền dựa trên vai trò (Role-based)

**File: `lms_backend/app/routers/chat.py`**

```python
@router.post("/groups", response_model=ChatGroupResponse)
def create_chat_group(
    group_data: ChatGroupCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)  # ← Đã xác thực
):
    """
    Tạo nhóm chat mới
    
    Kiểm tra quyền:
    1. Chỉ giảng viên mới được tạo nhóm
    2. Chỉ có thể tạo nhóm cho lớp của chính mình
    3. Mỗi lớp chỉ có 1 nhóm chat
    """
    # Bước 1: Kiểm tra vai trò
    if current_user.role.value != "lecturer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lecturers can create chat groups"
        )
    
    # Bước 2: Kiểm tra lớp có tồn tại không
    class_obj = db.query(Class).filter(Class.id == group_data.class_id).first()
    if not class_obj:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Class not found"
        )
    
    # Bước 3: Kiểm tra quyền sở hữu lớp
    if class_obj.lecturer_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only create chat groups for your own classes"
        )
    
    # Bước 4: Kiểm tra nhóm đã tồn tại chưa
    existing_group = db.query(ChatGroup).filter(
        ChatGroup.class_id == group_data.class_id
    ).first()
    
    if existing_group:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Chat group already exists for this class"
        )
    
    # Bước 5: Tạo nhóm và thêm thành viên
    chat_group = ChatGroup(
        name=group_data.name,
        class_id=group_data.class_id,
        created_by=current_user.id
    )
    db.add(chat_group)
    db.commit()
    db.refresh(chat_group)
    
    # Tự động thêm giảng viên làm thành viên
    lecturer_member = ChatGroupMember(
        group_id=chat_group.id,
        user_id=current_user.id
    )
    db.add(lecturer_member)
    
    # Tự động thêm tất cả sinh viên trong lớp
    enrollments = db.query(Enrollment).filter(
        Enrollment.class_id == group_data.class_id
    ).all()
    
    for enrollment in enrollments:
        member = ChatGroupMember(
            group_id=chat_group.id,
            user_id=enrollment.student_id
        )
        db.add(member)
    
    db.commit()
    
    return response
```

### 5.2. Kiểm tra quyền thành viên khi truy cập tin nhắn

```python
@router.get("/groups/{group_id}/messages", response_model=List[ChatMessageResponse])
def get_group_messages(
    group_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Lấy danh sách tin nhắn của nhóm
    
    Bảo mật:
    - Kiểm tra user có phải thành viên không
    - Chỉ trả về encrypted_content (client sẽ giải mã)
    """
    # Bước 1: Kiểm tra quyền thành viên
    member = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == group_id,
        ChatGroupMember.user_id == current_user.id
    ).first()
    
    if not member:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this group"
        )
    
    # Bước 2: Lấy tin nhắn (đã mã hóa)
    messages = db.query(ChatMessage).filter(
        ChatMessage.group_id == group_id
    ).order_by(desc(ChatMessage.timestamp)).limit(100).all()
    
    messages.reverse()
    
    # Bước 3: Trả về (không giải mã ở server)
    response = []
    for msg in messages:
        sender = db.query(User).filter(User.id == msg.sender_id).first()
        response.append(ChatMessageResponse(
            id=msg.id,
            group_id=msg.group_id,
            sender_id=msg.sender_id,
            sender_name=sender.full_name if sender else "Unknown",
            encrypted_content=msg.encrypted_content,  # ← Vẫn mã hóa
            timestamp=msg.timestamp
        ))
    
    return response
```

### 5.3. Quản lý thành viên với kiểm tra quyền

```python
@router.post("/groups/{group_id}/members")
def add_group_members(
    group_id: int,
    request: AddMembersRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Thêm thành viên vào nhóm
    
    Kiểm tra quyền:
    1. Chỉ giảng viên mới được thêm thành viên
    2. Chỉ người tạo nhóm mới được thêm thành viên
    """
    # Bước 1: Kiểm tra vai trò
    if current_user.role.value != "lecturer":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only lecturers can add members"
        )
    
    # Bước 2: Kiểm tra nhóm tồn tại
    group = db.query(ChatGroup).filter(ChatGroup.id == group_id).first()
    if not group:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Group not found"
        )
    
    # Bước 3: Kiểm tra quyền sở hữu
    if group.created_by != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only group creator can add members"
        )
    
    # Bước 4: Thêm thành viên
    added_count = 0
    for user_id in request.user_ids:
        existing = db.query(ChatGroupMember).filter(
            ChatGroupMember.group_id == group_id,
            ChatGroupMember.user_id == user_id
        ).first()
        
        if not existing:
            member = ChatGroupMember(
                group_id=group_id,
                user_id=user_id
            )
            db.add(member)
            added_count += 1
    
    db.commit()
    
    return {"success": True, "added_count": added_count}
```

---

## 6. LƯU TRỮ AN TOÀN TRÊN CLIENT

### 6.1. Flutter Secure Storage

**Cách hoạt động:**

- **iOS**: Sử dụng Keychain Services
- **Android**: Sử dụng EncryptedSharedPreferences với Android Keystore
- **Web**: Sử dụng localStorage (không an toàn bằng, nhưng vẫn tốt hơn SharedPreferences)

**Sử dụng trong code:**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  
  // Lưu token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
  
  // Đọc token
  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  // Xóa token
  Future<void> deleteToken() async {
    await _storage.delete(key: 'access_token');
  }
}
```

**Lợi ích:**
- Token được mã hóa trên thiết bị
- Không thể truy cập bởi ứng dụng khác
- Tự động xóa khi ứng dụng bị gỡ (tùy cấu hình)

---

## 7. LUỒNG XỬ LÝ TIN NHẮN HOÀN CHỈNH

### 7.1. Luồng gửi tin nhắn

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. USER NHẬP TIN NHẮN                                          │
│    Input: "Xin chào mọi người!"                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. CLIENT: MÃ HÓA TIN NHẮN                                     │
│    EncryptionService.encryptMessage(message, groupId)           │
│    - Tạo khóa từ groupId                                        │
│    - Tạo IV ngẫu nhiên                                           │
│    - Mã hóa với AES-256-CBC                                     │
│    - Encode Base64                                              │
│    Output: "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="│
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. CLIENT: GỬI QUA SOCKET.IO                                    │
│    SocketService.sendMessage(groupId, encryptedContent)          │
│    - Kết nối WebSocket (đã xác thực JWT)                         │
│    - Emit 'send_message' event                                   │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. SERVER: XÁC THỰC VÀ KIỂM TRA QUYỀN                          │
│    socket_service.send_message(sid, data)                       │
│    - Lấy user_id từ connected_users[sid] (đã xác thực)          │
│    - Kiểm tra user có phải thành viên không                     │
│    - Validate input data                                        │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SERVER: LƯU VÀO DATABASE                                     │
│    - Tạo ChatMessage object                                     │
│    - Lưu encrypted_content (KHÔNG giải mã)                      │
│    - Commit vào database                                         │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. SERVER: BROADCAST ĐẾN ROOM                                   │
│    - Emit 'new_message' đến room "group_{groupId}"              │
│    - Gửi encrypted_content (vẫn mã hóa)                         │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. CLIENT: NHẬN TIN NHẮN                                       │
│    SocketService.on('new_message')                              │
│    - Nhận message data với encrypted_content                    │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 8. CLIENT: GIẢI MÃ TIN NHẮN                                    │
│    EncryptionService.decryptMessage(encryptedContent, groupId)   │
│    - Tạo lại khóa từ groupId                                    │
│    - Decode Base64 và parse JSON                                 │
│    - Giải mã với AES-256-CBC                                    │
│    Output: "Xin chào mọi người!"                                │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────────┐
│ 9. CLIENT: HIỂN THỊ TIN NHẮN                                   │
│    - Thêm vào danh sách tin nhắn                                │
│    - Hiển thị trên UI                                            │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2. Điểm bảo mật trong luồng

1. **Tin nhắn được mã hóa TRƯỚC KHI gửi**: Server không bao giờ thấy plaintext
2. **JWT xác thực ở mọi bước**: Socket connection và API calls đều yêu cầu JWT
3. **Kiểm tra quyền thành viên**: Chỉ thành viên mới có thể gửi/nhận tin nhắn
4. **Room-based broadcasting**: Tin nhắn chỉ đến đúng nhóm
5. **Lưu trữ mã hóa**: Database chỉ lưu encrypted content

---

## 8. CÁC ĐIỂM CẦN CẢI THIỆN VÀ KHUYẾN NGHỊ

### 8.1. Các điểm cần cải thiện

#### 8.1.1. Key Management

**Vấn đề hiện tại:**
- Khóa mã hóa được tạo từ group ID (deterministic)
- Nếu ai đó biết group ID, họ có thể tạo lại khóa

**Khuyến nghị:**
- Sử dụng key derivation function (PBKDF2, Argon2)
- Lưu trữ key material an toàn hơn
- Cân nhắc sử dụng key rotation

#### 8.1.2. Forward Secrecy

**Vấn đề hiện tại:**
- Nếu khóa bị lộ, tất cả tin nhắn cũ có thể bị giải mã

**Khuyến nghị:**
- Implement Perfect Forward Secrecy (PFS)
- Sử dụng ephemeral keys cho mỗi session
- Rotate keys định kỳ

#### 8.1.3. Message Authentication

**Vấn đề hiện tại:**
- Chưa có cơ chế xác thực tính toàn vẹn tin nhắn (MAC)

**Khuyến nghị:**
- Thêm HMAC (Hash-based Message Authentication Code)
- Đảm bảo tin nhắn không bị sửa đổi trong quá trình truyền

#### 8.1.4. Rate Limiting

**Vấn đề hiện tại:**
- Chưa có giới hạn số lượng tin nhắn gửi

**Khuyến nghị:**
- Implement rate limiting cho Socket.IO events
- Ngăn chặn spam và DoS attacks

#### 8.1.5. Audit Logging

**Vấn đề hiện tại:**
- Chưa có log chi tiết về các hành động bảo mật

**Khuyến nghị:**
- Log tất cả các sự kiện bảo mật (failed auth, unauthorized access)
- Giữ audit trail để phục vụ điều tra

### 8.2. Khuyến nghị bổ sung

1. **TLS/SSL**: Đảm bảo tất cả kết nối đều qua HTTPS/WSS
2. **Token Refresh**: Implement refresh token mechanism
3. **2FA**: Cân nhắc thêm two-factor authentication
4. **Content Moderation**: Thêm cơ chế kiểm duyệt nội dung
5. **End-to-End Encryption**: Nếu cần bảo mật cao hơn, cân nhắc E2EE thực sự

---

## KẾT LUẬN

Báo cáo này đã trình bày chi tiết các cơ chế bảo mật được triển khai trong hệ thống chat, bao gồm:

1. **Xác thực JWT** cho cả REST API và Socket.IO
2. **Mã hóa AES-256-CBC** cho nội dung tin nhắn
3. **Kiểm tra quyền thành viên** ở mọi điểm truy cập
4. **Phân quyền dựa trên vai trò** để kiểm soát quyền truy cập
5. **Lưu trữ token an toàn** trên thiết bị di động
6. **Room-based broadcasting** để đảm bảo tin nhắn chỉ đến đúng người nhận

Mỗi cơ chế đều được giải thích chi tiết với code implementation và luồng xử lý. Hệ thống hiện tại đã có nền tảng bảo mật tốt, nhưng vẫn có thể được cải thiện thêm với các khuyến nghị đã nêu.

---

**Tài liệu này cung cấp hướng dẫn kỹ thuật chi tiết để hiểu và triển khai các cơ chế bảo mật trong hệ thống chat.**

