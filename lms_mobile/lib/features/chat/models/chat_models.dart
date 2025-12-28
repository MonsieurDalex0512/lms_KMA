class ChatGroup {
  final int id;
  final String name;
  final int classId;
  final int createdBy;
  final DateTime createdAt;
  final int memberCount;

  ChatGroup({
    required this.id,
    required this.name,
    required this.classId,
    required this.createdBy,
    required this.createdAt,
    this.memberCount = 0,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'],
      name: json['name'],
      classId: json['class_id'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      memberCount: json['member_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'class_id': classId,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'member_count': memberCount,
    };
  }
}

class ChatMessage {
  final int id;
  final int groupId;
  final int senderId;
  final String senderName;
  final String encryptedContent;
  final DateTime timestamp;
  String? decryptedContent;

  ChatMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    required this.encryptedContent,
    required this.timestamp,
    this.decryptedContent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      encryptedContent: json['encrypted_content'],
      timestamp: DateTime.parse(json['timestamp']).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'sender_name': senderName,
      'encrypted_content': encryptedContent,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatGroupMember {
  final int userId;
  final String fullName;
  final String role;
  final DateTime joinedAt;

  ChatGroupMember({
    required this.userId,
    required this.fullName,
    required this.role,
    required this.joinedAt,
  });

  factory ChatGroupMember.fromJson(Map<String, dynamic> json) {
    return ChatGroupMember(
      userId: json['user_id'],
      fullName: json['full_name'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
