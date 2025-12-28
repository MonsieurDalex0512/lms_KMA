import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'models/chat_models.dart';
import 'services/chat_api_service.dart';
import 'services/socket_service.dart';
import 'services/encryption_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatApiService _apiService = ChatApiService();
  final SocketService _socketService = SocketService();
  final EncryptionService _encryptionService = EncryptionService();

  List<ChatGroup> _groups = [];
  Map<int, List<ChatMessage>> _groupMessages = {};
  Map<int, List<ChatGroupMember>> _groupMembers = {};
  bool _isLoading = false;
  String? _error;
  int? _currentGroupId; 

  List<ChatGroup> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _socketService.isConnected;
  IO.Socket? get socket => _socketService.socket; 

  List<ChatMessage> getGroupMessages(int groupId) {
    return _groupMessages[groupId] ?? [];
  }

  List<ChatGroupMember> getGroupMembers(int groupId) {
    return _groupMembers[groupId] ?? [];
  }

  Future<void> initialize() async {
    try {
      print('ChatProvider: Initializing...');
      
      _socketService.onConnectCallback = () {
        print('ChatProvider: Socket connected/reconnected');
        if (_currentGroupId != null) {
          print('ChatProvider: Auto-rejoining group $_currentGroupId');
          joinGroup(_currentGroupId!);
        }
      };
      
      await _socketService.connect();
      print('ChatProvider: Registering new_message listener');
      _socketService.onNewMessage(_handleNewMessage);
      await loadGroups();
      print('ChatProvider: Initialization complete');
    } catch (e) {
      print('ChatProvider: Initialization error: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void dispose() {
    _socketService.offNewMessage();
    _socketService.disconnect();
    super.dispose();
  }

  Future<void> loadGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _groups = await _apiService.getChatGroups();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGroup(String name, int classId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGroup = await _apiService.createChatGroup(name, classId);
      _groups.add(newGroup);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupMessages(int groupId) async {
    try {
      final messages = await _apiService.getGroupMessages(groupId);
      
      for (var message in messages) {
        try {
          message.decryptedContent = await _encryptionService.decryptMessage(
            message.encryptedContent,
            groupId,
          );
        } catch (e) {
          message.decryptedContent = '[Không thể giải mã]';
        }
      }
      
      _groupMessages[groupId] = messages;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGroupMembers(int groupId) async {
    try {
      final members = await _apiService.getGroupMembers(groupId);
      _groupMembers[groupId] = members;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> joinGroup(int groupId) async {
    try {
      print('ChatProvider: Joining group $groupId');
      _currentGroupId = groupId;
      
      if (!_socketService.isConnected) {
        print('ChatProvider: Socket not connected, connecting...');
        await _socketService.connect();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      await _socketService.joinGroup(groupId);
      await Future.delayed(const Duration(milliseconds: 200));
      
      await loadGroupMessages(groupId);
      await loadGroupMembers(groupId);
      
      print('ChatProvider: Joined group $groupId successfully');
    } catch (e) {
      print('ChatProvider: Error joining group: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      if (_currentGroupId == groupId) {
        _currentGroupId = null;
      }
      await _socketService.leaveGroup(groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendMessage(int groupId, String content) async {
    try {
      print('ChatProvider: Encrypting message for group $groupId');
      final encryptedContent = await _encryptionService.encryptMessage(
        content,
        groupId,
      );
      
      print('ChatProvider: Sending encrypted message via Socket.IO');
      await _socketService.sendMessage(groupId, encryptedContent);
      print('ChatProvider: Message sent successfully');
    } catch (e) {
      print('ChatProvider: Error sending message: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void _handleNewMessage(dynamic data) async {
    try {
      print('ChatProvider: Received new message: $data');
      final message = ChatMessage.fromJson(data);
      
      print('ChatProvider: Decrypting message for group ${message.groupId}');
      message.decryptedContent = await _encryptionService.decryptMessage(
        message.encryptedContent,
        message.groupId,
      );
      
      if (_groupMessages[message.groupId] == null) {
        _groupMessages[message.groupId] = [];
      }
      
      _groupMessages[message.groupId]!.add(message);
      print('ChatProvider: Message added to group ${message.groupId}, total messages: ${_groupMessages[message.groupId]!.length}');
      notifyListeners();
    } catch (e) {
      print('ChatProvider: Error handling new message: $e');
    }
  }

  Future<void> addMembers(int groupId, List<int> userIds) async {
    try {
      await _apiService.addGroupMembers(groupId, userIds);
      await loadGroupMembers(groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeMember(int groupId, int userId) async {
    try {
      await _apiService.removeGroupMember(groupId, userId);
      await loadGroupMembers(groupId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
