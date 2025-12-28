import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StudentProvider>().fetchClasses());
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Lớp Sinh Viên')),
      body: studentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => studentProvider.fetchClasses(),
              child: studentProvider.classes.isEmpty
                  ? const Center(child: Text('Chưa đăng ký lớp học nào'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: studentProvider.classes.length,
                      itemBuilder: (context, index) {
                        final cls = studentProvider.classes[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.book, color: Colors.blue),
                            title: Text(cls['course_name'] ?? 'Class ${cls['id']}'),
                            subtitle: Text(
                                'Phòng: ${cls['room'] ?? 'N/A'} - Giảng viên: ${cls['lecturer_name'] ?? 'N/A'}'),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(cls['course_name'] ?? 'Chi tiết lớp học'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Giảng viên: ${cls['lecturer_name'] ?? 'N/A'}'),
                                      const SizedBox(height: 8),
                                      Text('Phòng học: ${cls['room'] ?? 'Online'}'),
                                      const SizedBox(height: 8),
                                      Text('Thứ: ${cls['day_of_week'] != null ? 'Thứ ${cls['day_of_week'] + 1}' : 'Chưa xếp'}'),
                                      Text('Tuần học: ${cls['start_week'] ?? '?'} - ${cls['end_week'] ?? '?'}'),
                                      Text('Tiết học: ${cls['start_period'] ?? '?'} - ${cls['end_period'] ?? '?'}'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
