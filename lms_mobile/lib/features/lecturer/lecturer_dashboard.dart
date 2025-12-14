import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'lecturer_provider.dart';
import 'lecturer_class_detail_screen.dart';
import '../../shared/profile_screen.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<LecturerProvider>().fetchClasses());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lecturerProvider = context.watch<LecturerProvider>();
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giảng Viên Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lớp Giảng Dạy', icon: Icon(Icons.class_)),
            Tab(text: 'Cá Nhân', icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          lecturerProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lecturerProvider.error != null
                  ? Center(child: Text(lecturerProvider.error!))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lecturerProvider.classes.length,
                      itemBuilder: (context, index) {
                        final cls = lecturerProvider.classes[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Icon(Icons.class_, color: Colors.white),
                            ),
                            title: Text(
                              cls['code'] ?? 'Lớp ${cls['id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (cls['course'] != null)
                                  Text(
                                    cls['course']['name'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  cls['day_of_week'] != null 
                                    ? 'Thứ ${cls['day_of_week'] + 1} - Tiết ${cls['start_period']}-${cls['end_period']}${cls['room'] != null ? ' - ${cls['room']}' : ''}'
                                    : 'Chưa xếp lịch',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LecturerClassDetailScreen(
                                    classId: cls['id'],
                                    courseName: '${cls['code'] ?? 'Lớp ${cls['id']}'} - ${cls['course']?['name'] ?? 'Chi tiết lớp'}',
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          const ProfileScreen(),
        ],
      ),
    );
  }
}
