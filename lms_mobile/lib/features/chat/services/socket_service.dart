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
    if (_socket != null) {
       if (_isConnected) return;
       _socket!.connect();
       return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    print('Connecting to Socket.IO at: ${ApiClient.baseUrl}');
    
    _socket = IO.io(
      ApiClient.baseUrl,
      IO.OptionBuilder()
          .setPath('/socket.io') 
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _setupSocketListeners();
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

    _socket!.onError((error) {
      print('SocketService: Socket error: $error');
    });

    _socket!.onAny((event, data) {
      print('SocketService: DEBUG - Received event: $event');

    });

    _socket!.on('new_message', (data) {
      print('SocketService: *** RECEIVED new_message ***');
      if (_messageCallback != null) {
        _messageCallback!(data);
      } else {
        print('SocketService: WARNING - Received message but no callback registered');
      }
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose(); 
      _socket = null;
      _isConnected = false;
    }
  }

  Future<void> joinGroup(int groupId) async {
    if (_socket == null || !_isConnected) {
      print('SocketService: ensure connected before joinGroup');
      await connect();
      int retries = 0;
      while (!_isConnected && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        retries++;
      }
    }

    print('SocketService: Joining group: $groupId');
    _socket!.emitWithAck('join_group', {'group_id': groupId}, ack: (data) {
      print('SocketService: join_group ack response: $data');
    });
  }

  Future<void> leaveGroup(int groupId) async {
    if (_socket == null || !_isConnected) return;

    print('SocketService: Leaving group: $groupId');
    _socket!.emit('leave_group', {'group_id': groupId});
  }

  Future<void> sendMessage(int groupId, String encryptedContent) async {
    if (_socket == null || !_isConnected) {
       print('SocketService: ensure connected before sendMessage');
       await connect();
    }

    print('SocketService: Sending message to group $groupId');
    _socket!.emit('send_message', {
      'group_id': groupId,
      'encrypted_content': encryptedContent,
    });
  }

  void onNewMessage(Function(dynamic) callback) {
    print('SocketService: Updated message callback');
    _messageCallback = callback;
  }

  void offNewMessage() {
    print('SocketService: Cleared message callback');
    _messageCallback = null;
  }
}
