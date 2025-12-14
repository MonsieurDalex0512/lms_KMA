import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import 'academic_results_screen.dart';
import 'student_classes_screen.dart';
import 'timetable_screen.dart';
import 'projects_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'tuition_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _studentName = "Sinh viên";
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchStudentName();
  }

  Future<void> _fetchStudentName() async {
    try {
      final response = await _apiClient.client.get('/students/me');
      if (response.data != null && response.data['full_name'] != null) {
        if (mounted) {
          setState(() {
            _studentName = response.data['full_name'];
          });
        }
      }
    } catch (e) {
      print("Error fetching student name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade400]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Xin chào,", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text(_studentName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Chúc bạn một ngày học tập hiệu quả!", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text("Danh mục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuItem(context, "Thời khóa biểu", Icons.calendar_today, Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
                }),
                _buildMenuItem(context, "Kết quả học tập", Icons.school, Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AcademicResultsScreen()));
                }),
                _buildMenuItem(context, "Đồ án", Icons.assignment, Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()));
                }),
                _buildMenuItem(context, "Thông báo", Icons.notifications, Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                }),
                _buildMenuItem(context, "Lớp sinh viên", Icons.people, Colors.teal, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentClassesScreen()));
                }),
                _buildMenuItem(context, "Biểu mẫu online", Icons.description, Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                }),
                _buildMenuItem(context, "Học phí", Icons.monetization_on, Colors.amber, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TuitionScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
