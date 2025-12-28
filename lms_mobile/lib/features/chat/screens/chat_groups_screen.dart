import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat_provider.dart';
import 'create_chat_group_screen.dart';
import 'chat_screen.dart';
import '../../auth/auth_provider.dart';

class ChatGroupsScreen extends StatefulWidget {
  const ChatGroupsScreen({super.key});

  @override
  State<ChatGroupsScreen> createState() => _ChatGroupsScreenState();
}

class _ChatGroupsScreenState extends State<ChatGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isLecturer = authProvider.role == UserRole.lecturer;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : chatProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lỗi: ${chatProvider.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => chatProvider.loadGroups(),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : chatProvider.groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Chưa có nhóm chat nào'),
                          if (isLecturer) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateChatGroupScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Tạo nhóm chat'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => chatProvider.loadGroups(),
                      child: ListView.builder(
                        itemCount: chatProvider.groups.length,
                        itemBuilder: (context, index) {
                          final group = chatProvider.groups[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: const Icon(Icons.group, color: Colors.white),
                              ),
                              title: Text(
                                group.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${group.memberCount} thành viên'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(group: group),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: isLecturer
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateChatGroupScreen(),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
