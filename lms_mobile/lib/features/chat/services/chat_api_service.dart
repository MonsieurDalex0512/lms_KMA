import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../models/chat_models.dart';

class ChatApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ChatGroup> createChatGroup(String name, int classId) async {
    try {
      final response = await _apiClient.client.post(
        '/chat/groups',
        data: {
          'name': name,
          'class_id': classId,
        },
        options: Options(
          contentType: 'application/json',
        ),
      );
      return ChatGroup.fromJson(response.data);
    } catch (e) {
      print('Error creating chat group: $e');
      rethrow;
    }
  }

  Future<List<ChatGroup>> getChatGroups() async {
    try {
      final response = await _apiClient.client.get('/chat/groups');
      final List<dynamic> data = response.data;
      return data.map((json) => ChatGroup.fromJson(json)).toList();
    } catch (e) {
      print('Error getting chat groups: $e');
      rethrow;
    }
  }

  Future<List<ChatMessage>> getGroupMessages(int groupId) async {
    try {
      final response = await _apiClient.client.get('/chat/groups/$groupId/messages');
      final List<dynamic> data = response.data;
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('Error getting messages: $e');
      rethrow;
    }
  }

  Future<List<ChatGroupMember>> getGroupMembers(int groupId) async {
    try {
      final response = await _apiClient.client.get('/chat/groups/$groupId/members');
      final List<dynamic> data = response.data;
      return data.map((json) => ChatGroupMember.fromJson(json)).toList();
    } catch (e) {
      print('Error getting members: $e');
      rethrow;
    }
  }

  Future<void> addGroupMembers(int groupId, List<int> userIds) async {
    try {
      await _apiClient.client.post(
        '/chat/groups/$groupId/members',
        data: {'user_ids': userIds},
      );
    } catch (e) {
      print('Error adding members: $e');
      rethrow;
    }
  }

  Future<void> removeGroupMember(int groupId, int userId) async {
    try {
      await _apiClient.client.delete('/chat/groups/$groupId/members/$userId');
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }
}
