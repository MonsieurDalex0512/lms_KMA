# HƯỚNG DẪN CHUYÊN SÂU VỀ BẢO MẬT CHAT - PHẦN 4: SOCKET.IO VÀ GIAO TIẾP REAL-TIME

## MỤC LỤC

1. [Socket.IO là gì?](#1-socketio-là-gì)
2. [Tại sao dùng Socket.IO cho chat?](#2-tại-sao-dùng-socketio-cho-chat)
3. [Xác thực Socket.IO với JWT](#3-xác-thực-socketio-với-jwt)
4. [Cách client kết nối Socket.IO](#4-cách-client-kết-nối-socketio)
5. [Cách server xử lý Socket.IO events](#5-cách-server-xử-lý-socketio-events)
6. [Room-based Broadcasting](#6-room-based-broadcasting)
7. [Ví dụ thực tế từng bước](#7-ví-dụ-thực-tế-từng-bước)

---

## 1. SOCKET.IO LÀ GÌ?

### 1.1. HTTP vs WebSocket

**HTTP (REST API):**
```
Client                    Server
  │                         │
  ├─► GET /messages ────────►│
  │                         │
  │◄─── Response ──────────┤
  │                         │
  │ (Connection closed)     │
```

**Đặc điểm:**
- Request → Response → Đóng kết nối
- Client phải gửi request mới để lấy dữ liệu mới
- Không phù hợp cho real-time chat

**WebSocket (Socket.IO):**
```
Client                    Server
  │                         │
  ├─► Connect ─────────────►│
  │                         │
  │◄─── Connected ─────────┤
  │                         │
  │ (Connection stays open) │
  │                         │
  │◄─── New message ────────┤ (Server push)
  │                         │
  │◄─── New message ────────┤ (Server push)
```

**Đặc điểm:**
- Kết nối mở liên tục
- Server có thể **push** dữ liệu đến client
- Phù hợp cho real-time chat!

### 1.2. Socket.IO là gì?

**Socket.IO** là thư viện cho phép:
- Kết nối WebSocket giữa client và server
- Tự động fallback về HTTP long-polling nếu WebSocket không hỗ trợ
- Hỗ trợ rooms (phòng) để broadcast đến nhóm người dùng
- Hỗ trợ events (sự kiện) để gửi/nhận dữ liệu

**Ví dụ:**
```javascript
// Client gửi event
socket.emit('send_message', { content: 'Hello' });

// Server nhận event
socket.on('send_message', (data) => {
  console.log(data.content);  // 'Hello'
});

// Server gửi event
socket.emit('new_message', { content: 'Hi there' });

// Client nhận event
socket.on('new_message', (data) => {
  console.log(data.content);  // 'Hi there'
});
```

---

## 2. TẠI SAO DÙNG SOCKET.IO CHO CHAT?

### 2.1. Real-time Communication

**Với HTTP:**
```
User A gửi tin nhắn:
  → Server lưu vào database
  → Server trả về: "OK"

User B muốn xem tin nhắn mới:
  → Phải gửi request: GET /messages
  → Server trả về danh sách tin nhắn
  → User B thấy tin nhắn

Vấn đề: User B phải "refresh" mới thấy tin nhắn mới!
```

**Với Socket.IO:**
```
User A gửi tin nhắn:
  → Server lưu vào database
  → Server broadcast đến tất cả client trong room
  → User B tự động nhận được (KHÔNG cần refresh!)
```

### 2.2. Hiệu quả hơn

**HTTP:**
- Mỗi request tạo connection mới
- Tốn overhead (headers, handshake)
- Chậm hơn

**Socket.IO:**
- Một connection duy nhất
- Ít overhead
- Nhanh hơn

---

## 3. XÁC THỰC SOCKET.IO VỚI JWT

### 3.1. Vấn đề: Ai được kết nối?

**Không có xác thực:**
```
Bất kỳ ai cũng có thể:
  → Kết nối Socket.IO
  → Gửi tin nhắn
  → Nhận tin nhắn
  → ❌ KHÔNG AN TOÀN!
```

**Có xác thực JWT:**
```
Chỉ user đã đăng nhập mới có thể:
  → Kết nối Socket.IO (với JWT token)
  → Server xác minh token
  → Chỉ cho phép kết nối nếu token hợp lệ
  → ✅ AN TOÀN!
```

### 3.2. Luồng xác thực

```
┌──────────┐                    ┌──────────┐
│  Client  │                    │  Server  │
└────┬─────┘                    └────┬─────┘
     │                               │
     │ 1. socket.connect()           │
     │    auth: {token: "jwt..."}    │
     ├──────────────────────────────►│
     │                               │
     │                               │ 2. connect(sid, auth)
     │                               │    - Extract token
     │                               │    - jwt.decode(token)
     │                               │    - Verify signature
     │                               │    - Check expiration
     │                               │
     │                               │ 3. Token valid?
     │                               │    YES → Store: connected_users[sid] = user_id
     │                               │    NO  → Reject connection
     │                               │
     │ 4. Connection accepted        │
     │◄──────────────────────────────┤
     │                               │
     │ (Now can send/receive events) │
```

---

## 4. CÁCH CLIENT KẾT NỐI SOCKET.IO

### 4.1. File: `lms_mobile/lib/features/chat/services/socket_service.dart`

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';

class SocketService {
  IO.Socket? _socket;  // Socket connection
  bool _isConnected = false;  // Trạng thái kết nối
  Function(dynamic)? _messageCallback;  // Callback khi nhận message
  
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    // Kiểm tra nếu đã kết nối
    if (_socket != null && _isConnected) {
      return;  // Đã kết nối rồi, không cần kết nối lại
    }

    // BƯỚC 1: Lấy JWT token từ Secure Storage
    // Token được lưu khi user đăng nhập
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    // token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." hoặc null

    if (token == null) {
      // Không có token → Không thể kết nối
      throw Exception('No access token found');
    }

    print('Connecting to Socket.IO at: ${ApiClient.baseUrl}');
    
    // BƯỚC 2: Tạo socket với authentication
    _socket = IO.io(
      ApiClient.baseUrl,  // URL server (ví dụ: "http://localhost:8000")
      IO.OptionBuilder()
          .setPath('/socket.io')  // Path của Socket.IO
          .setTransports(['websocket', 'polling'])  // Ưu tiên WebSocket, fallback polling
          .enableAutoConnect()  // Tự động kết nối
          // BƯỚC 3: Gửi token trong auth object
          // Server sẽ nhận được trong hàm connect(sid, auth)
          .setAuth({'token': token})
          // BƯỚC 4: Thêm token vào headers (backup)
          // Một số server có thể check header thay vì auth
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    // BƯỚC 5: Setup event listeners
    // Đăng ký các hàm xử lý khi có sự kiện
    _setupSocketListeners();
    
    // BƯỚC 6: Kết nối
    _socket!.connect();
  }
  
  void _setupSocketListeners() {
    if (_socket == null) return;

    // Event: Kết nối thành công
    _socket!.onConnect((_) {
      print('SocketService: Socket connected successfully');
      _isConnected = true;
      
      // Gọi callback nếu có
      if (onConnectCallback != null) {
        onConnectCallback!();
      }
    });

    // Event: Mất kết nối
    _socket!.onDisconnect((_) {
      print('SocketService: Socket disconnected');
      _isConnected = false;
    });

    // Event: Lỗi kết nối
    _socket!.onConnectError((error) {
      print('SocketService: Socket connection error: $error');
      _isConnected = false;
    });

    // Event: Nhận tin nhắn mới
    _socket!.on('new_message', (data) {
      print('SocketService: *** RECEIVED new_message ***');
      // Gọi callback để ChatProvider xử lý
      if (_messageCallback != null) {
        _messageCallback!(data);
      }
    });
  }
}
```

### 4.2. Giải thích từng bước

**Bước 1: Lấy token**
```dart
final token = prefs.getString('access_token');
// Token được lưu khi đăng nhập
// Nếu null → Không thể kết nối
```

**Bước 2: Tạo socket**
```dart
_socket = IO.io(
  ApiClient.baseUrl,  // "http://localhost:8000"
  IO.OptionBuilder()
    .setAuth({'token': token})  // ← Gửi token trong auth
    .build()
);
```

**Bước 3: Setup listeners**
```dart
_socket!.onConnect((_) {
  // Khi kết nối thành công
  _isConnected = true;
});
```

**Bước 4: Kết nối**
```dart
_socket!.connect();
// Gửi request kết nối đến server
// Server sẽ gọi connect(sid, auth) với token
```

---

## 5. CÁCH SERVER XỬ LÝ SOCKET.IO EVENTS

### 5.1. File: `lms_backend/app/services/socket_service.py`

```python
import socketio
from app.auth.security import decode_access_token
from typing import Dict

# Tạo Socket.IO server
sio = socketio.AsyncServer(
    async_mode='asgi',  # Dùng với ASGI (FastAPI)
    cors_allowed_origins='*',  # Cho phép CORS
    logger=True,  # Log để debug
    engineio_logger=True
)

# Dictionary lưu mapping: socket_id → user_id
# Khi user kết nối, lưu: connected_users[sid] = user_id
# Khi cần biết user nào, lấy: user_id = connected_users[sid]
connected_users: Dict[str, int] = {}

@sio.event
async def connect(sid, environ, auth):
    """
    Xử lý khi client kết nối Socket.IO
    
    Hàm này được gọi TỰ ĐỘNG khi:
    - Client gọi socket.connect()
    - Client gửi auth: {token: "jwt..."}
    
    Args:
        sid: Socket ID (unique identifier cho mỗi connection)
        environ: Environment variables (không dùng)
        auth: Authentication data từ client
              auth = {'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'}
    
    Returns:
        bool: True nếu xác thực thành công, False nếu thất bại
        - True → Cho phép kết nối
        - False → Từ chối kết nối
    """
    try:
        # BƯỚC 1: Kiểm tra auth data
        # Client phải gửi token trong auth object
        if not auth or 'token' not in auth:
            print(f"Connection rejected: No token provided (sid: {sid})")
            return False  # Từ chối kết nối
        
        # BƯỚC 2: Lấy token từ auth
        token = auth['token']
        # token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
        
        # BƯỚC 3: Giải mã và xác minh token
        # decode_access_token() sẽ:
        # - Giải mã token
        # - Kiểm tra signature
        # - Kiểm tra expiration
        # - Trả về payload nếu hợp lệ, None nếu không hợp lệ
        payload = decode_access_token(token)
        
        if not payload:
            # Token không hợp lệ (đã hết hạn, signature sai, ...)
            print(f"Connection rejected: Invalid token (sid: {sid})")
            return False  # Từ chối kết nối
        
        # BƯỚC 4: Lấy user_id từ payload
        # payload = {"sub": "nguyenvana", "user_id": 5, "exp": ...}
        user_id = payload.get('user_id')
        
        if not user_id:
            # Token không có user_id
            print(f"Connection rejected: No user_id in token (sid: {sid})")
            return False  # Từ chối kết nối
        
        # BƯỚC 5: Lưu mapping socket_id → user_id
        # Để sau này biết socket này thuộc về user nào
        connected_users[sid] = int(user_id)
        # Ví dụ: connected_users["abc123"] = 5
        # → Socket "abc123" thuộc về user_id = 5
        
        print(f"User {user_id} connected with sid {sid}")
        return True  # Cho phép kết nối
        
    except Exception as e:
        # Nếu có lỗi bất kỳ → Từ chối kết nối
        print(f"Connection error: {e}")
        return False
```

### 5.2. Xử lý sự kiện gửi tin nhắn

```python
@sio.event
async def send_message(sid, data):
    """
    Xử lý sự kiện gửi tin nhắn
    
    Hàm này được gọi khi:
    - Client gọi: socket.emit('send_message', {group_id: 5, encrypted_content: "..."})
    
    Args:
        sid: Socket ID (từ connect event)
        data: Dictionary chứa group_id và encrypted_content
              data = {'group_id': 5, 'encrypted_content': 'eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0='}
    
    Returns:
        dict: {'success': True/False, 'message': {...} hoặc 'error': '...'}
    """
    try:
        # BƯỚC 1: Extract data từ request
        group_id = data.get('group_id')  # ID nhóm chat
        encrypted_content = data.get('encrypted_content')  # Nội dung đã mã hóa
        
        # BƯỚC 2: Lấy user_id từ connected_users
        # KHÔNG tin tưởng client! Lấy từ authenticated session
        # Nếu client gửi user_id giả, vẫn lấy từ connected_users[sid]
        user_id = connected_users.get(sid)
        # user_id = 5 (từ connect event)
        
        # BƯỚC 3: Validate input
        if not user_id or not group_id or not encrypted_content:
            return {'success': False, 'error': 'Invalid data'}
        
        # BƯỚC 4: Mở database session
        from app.database import SessionLocal
        db = SessionLocal()
        
        try:
            # BƯỚC 5: KIỂM TRA QUYỀN THÀNH VIÊN
            # Chỉ thành viên mới được gửi tin nhắn!
            member = db.query(ChatGroupMember).filter(
                ChatGroupMember.group_id == group_id,
                ChatGroupMember.user_id == user_id
            ).first()
            
            if not member:
                # User không phải thành viên → Từ chối
                return {'success': False, 'error': 'Not a member of this group'}
            
            # BƯỚC 6: Lưu tin nhắn (đã mã hóa từ client)
            # Server KHÔNG giải mã! Chỉ lưu encrypted_content
            message = ChatMessage(
                group_id=group_id,
                sender_id=user_id,  # Từ connected_users[sid], không tin client
                encrypted_content=encrypted_content  # Vẫn mã hóa
            )
            db.add(message)
            db.commit()
            db.refresh(message)
            
            # BƯỚC 7: Lấy thông tin người gửi
            user = db.query(User).filter(User.id == user_id).first()
            
            # BƯỚC 8: Tạo message data để broadcast
            message_data = {
                'id': message.id,
                'group_id': message.group_id,
                'sender_id': message.sender_id,
                'sender_name': user.full_name if user else 'Unknown',
                'encrypted_content': message.encrypted_content,  # Vẫn mã hóa!
                'timestamp': message.timestamp.isoformat()
            }
            
            # BƯỚC 9: Broadcast đến room
            room_name = f"group_{group_id}"  # "group_5"
            
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

### 5.3. Join/Leave Group

```python
@sio.event
async def join_group(sid, data):
    """
    Tham gia vào một nhóm chat (room)
    
    Client gọi: socket.emit('join_group', {group_id: 5})
    """
    try:
        group_id = data.get('group_id')
        user_id = connected_users.get(sid)  # Lấy từ authenticated session
        
        if not user_id or not group_id:
            return {'success': False, 'error': 'Invalid data'}
        
        # Tham gia room
        # Room name = "group_{group_id}" (ví dụ: "group_5")
        room_name = f"group_{group_id}"
        await sio.enter_room(sid, room_name)
        
        print(f"User {user_id} joined group {group_id} (room: {room_name})")
        return {'success': True}
        
    except Exception as e:
        print(f"Join group error: {e}")
        return {'success': False, 'error': str(e)}

@sio.event
async def leave_group(sid, data):
    """
    Rời khỏi nhóm chat (room)
    """
    try:
        group_id = data.get('group_id')
        user_id = connected_users.get(sid)
        
        if not user_id or not group_id:
            return {'success': False, 'error': 'Invalid data'}
        
        room_name = f"group_{group_id}"
        await sio.leave_room(sid, room_name)
        
        print(f"User {user_id} left group {group_id}")
        return {'success': True}
        
    except Exception as e:
        print(f"Leave group error: {e}")
        return {'success': False, 'error': str(e)}
```

---

## 6. ROOM-BASED BROADCASTING

### 6.1. Room là gì?

**Room** là một nhóm socket connections. Khi emit đến room, tất cả socket trong room đều nhận được.

**Ví dụ:**
```
Room "group_5":
  - Socket A (User 1)
  - Socket B (User 2)
  - Socket C (User 3)

Emit đến room "group_5":
  → Socket A, B, C đều nhận được

Emit đến room "group_6":
  → Socket A, B, C KHÔNG nhận được (không trong room)
```

### 6.2. Cách hoạt động

**Bước 1: User join room**
```python
# User 1, 2, 3 join group 5
await sio.enter_room("socket_A", "group_5")
await sio.enter_room("socket_B", "group_5")
await sio.enter_room("socket_C", "group_5")
```

**Bước 2: User gửi tin nhắn**
```python
# User 1 gửi tin nhắn
await sio.emit('new_message', message_data, room="group_5")
```

**Bước 3: Tất cả user trong room nhận được**
```
Socket A (User 1): Nhận được (sender)
Socket B (User 2): Nhận được
Socket C (User 3): Nhận được
```

### 6.3. Lợi ích

**Chỉ gửi đến đúng người:**
- Tin nhắn group 5 → Chỉ gửi đến room "group_5"
- Tin nhắn group 6 → Chỉ gửi đến room "group_6"
- Không bị rò rỉ!

**Hiệu quả:**
- Không cần gửi đến từng socket
- Chỉ cần emit đến room
- Socket.IO tự động gửi đến tất cả socket trong room

---

## 7. VÍ DỤ THỰC TẾ TỪNG BƯỚC

### 7.1. Kịch bản: User A gửi tin nhắn, User B và C nhận được

**Bước 1: User A, B, C đăng nhập và kết nối Socket.IO**

```dart
// User A (Client)
final socketService = SocketService();
await socketService.connect();
// → Server: connect(sid="socket_A", auth={token: "jwt_A"})
// → Server: connected_users["socket_A"] = 10 (user_id của A)

// User B (Client)
await socketService.connect();
// → Server: connected_users["socket_B"] = 11

// User C (Client)
await socketService.connect();
// → Server: connected_users["socket_C"] = 12
```

**Bước 2: User A, B, C join group 5**

```dart
// User A
socket.emit('join_group', {'group_id': 5});
// → Server: sio.enter_room("socket_A", "group_5")

// User B
socket.emit('join_group', {'group_id': 5});
// → Server: sio.enter_room("socket_B", "group_5")

// User C
socket.emit('join_group', {'group_id': 5});
// → Server: sio.enter_room("socket_C", "group_5")
```

**Bước 3: User A gửi tin nhắn**

```dart
// User A (Client)
// 1. Mã hóa tin nhắn
final encrypted = await encryptionService.encryptMessage("Xin chào!", 5);
// encrypted = "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="

// 2. Gửi qua Socket.IO
socket.emit('send_message', {
  'group_id': 5,
  'encrypted_content': encrypted
});
```

**Bước 4: Server xử lý**

```python
# Server nhận event
@sio.event
async def send_message(sid, data):
    # sid = "socket_A"
    # data = {'group_id': 5, 'encrypted_content': 'eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0='}
    
    # 1. Lấy user_id từ connected_users
    user_id = connected_users["socket_A"]  # = 10 (User A)
    
    # 2. Kiểm tra quyền thành viên
    member = db.query(ChatGroupMember).filter(
        ChatGroupMember.group_id == 5,
        ChatGroupMember.user_id == 10
    ).first()
    # → OK, User A là thành viên
    
    # 3. Lưu vào database
    message = ChatMessage(
        group_id=5,
        sender_id=10,
        encrypted_content="eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0="
    )
    db.add(message)
    db.commit()
    
    # 4. Broadcast đến room "group_5"
    await sio.emit('new_message', {
        'id': 123,
        'group_id': 5,
        'sender_id': 10,
        'sender_name': 'Nguyễn Văn A',
        'encrypted_content': "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0=",
        'timestamp': '2024-01-15T10:30:00'
    }, room="group_5")
    # → Gửi đến socket_A, socket_B, socket_C
```

**Bước 5: User A, B, C nhận tin nhắn**

```dart
// User A, B, C (Client)
socket.on('new_message', (data) {
  // data = {
  //   'id': 123,
  //   'group_id': 5,
  //   'sender_id': 10,
  //   'sender_name': 'Nguyễn Văn A',
  //   'encrypted_content': "eyJpdiI6IkdpMXNQQT09IiwiZGF0YSI6InhLOWoyTG1OLi4uIn0=",
  //   'timestamp': '2024-01-15T10:30:00'
  // }
  
  // Giải mã
  final decrypted = await encryptionService.decryptMessage(
    data['encrypted_content'],
    data['group_id']
  );
  // decrypted = "Xin chào!"
  
  // Hiển thị trên UI
  displayMessage(decrypted);
});
```

### 7.2. Điểm bảo mật quan trọng

**1. User ID từ authenticated session:**
```python
# KHÔNG tin client!
user_id = connected_users[sid]  # ✅ Đúng
# user_id = data.get('user_id')  # ❌ SAI! Client có thể giả mạo
```

**2. Kiểm tra quyền thành viên:**
```python
# Chỉ thành viên mới được gửi tin nhắn
member = db.query(ChatGroupMember).filter(...).first()
if not member:
    return {'success': False, 'error': 'Not a member'}
```

**3. Room-based broadcasting:**
```python
# Chỉ gửi đến room tương ứng
await sio.emit('new_message', data, room=f"group_{group_id}")
# → Chỉ user trong room mới nhận được
```

**4. Server không giải mã:**
```python
# Server chỉ lưu và broadcast encrypted_content
# Server KHÔNG giải mã!
```

---

## TÓM TẮT PHẦN 4

Trong phần này, bạn đã học được:

1. ✅ **Socket.IO là gì** - WebSocket library cho real-time communication
2. ✅ **Tại sao dùng Socket.IO** - Push data từ server đến client
3. ✅ **Xác thực Socket.IO** - Sử dụng JWT token trong auth
4. ✅ **Cách client kết nối** - Gửi token trong auth object
5. ✅ **Cách server xử lý** - Xác minh token, lưu mapping sid→user_id
6. ✅ **Room-based broadcasting** - Gửi đến đúng nhóm người dùng

**Điểm quan trọng:**
- ✅ User ID từ authenticated session (không tin client)
- ✅ Kiểm tra quyền thành viên trước khi gửi
- ✅ Room-based để chỉ gửi đến đúng người

**Tiếp theo:** Phần 5 sẽ tổng hợp tất cả - luồng hoạt động hoàn chỉnh từ đầu đến cuối!

---

**📌 Lưu ý:** Socket.IO rất quan trọng! Phải:
- ✅ Xác thực mọi kết nối
- ✅ Kiểm tra quyền trước mọi hành động
- ✅ Dùng room để broadcast đúng người

