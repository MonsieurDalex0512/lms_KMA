import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';
import '../chat/screens/chat_groups_screen.dart';
import '../chat/chat_provider.dart';
import 'academic_results_screen.dart';
import 'student_classes_screen.dart';
import 'timetable_screen.dart';
import 'projects_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'tuition_screen.dart';
import 'other_features_screen.dart';

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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F5DC), // Beige/cream background
            Colors.grey.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với Logo và Tên trường
            _buildSchoolHeader(),
            const SizedBox(height: 16),
            
            // Welcome Section với gradient đẹp
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade700,
                    Colors.indigo.shade600,
                    Colors.purple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.waving_hand,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Xin chào,",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _studentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.amber.shade300,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Chúc bạn một ngày học tập hiệu quả!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Danh mục Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade600,
                          Colors.purple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Danh mục",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Grid Menu Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildMenuItem(
                    context,
                    "Thời khóa biểu",
                    Icons.calendar_today_rounded,
                    Colors.orange,
                    [Colors.orange.shade400, Colors.orange.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimetableScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Kết quả học tập",
                    Icons.school_rounded,
                    Colors.blue,
                    [Colors.blue.shade400, Colors.blue.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AcademicResultsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Đồ án",
                    Icons.assignment_rounded,
                    Colors.purple,
                    [Colors.purple.shade400, Colors.purple.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProjectsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Thông báo",
                    Icons.notifications_rounded,
                    Colors.red,
                    [Colors.red.shade400, Colors.red.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Lớp sinh viên",
                    Icons.people_rounded,
                    Colors.teal,
                    [Colors.teal.shade400, Colors.teal.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentClassesScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Biểu mẫu online",
                    Icons.description_rounded,
                    Colors.green,
                    [Colors.green.shade400, Colors.green.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Học phí",
                    Icons.monetization_on_rounded,
                    Colors.amber,
                    [Colors.amber.shade400, Colors.amber.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TuitionScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Chat",
                    Icons.chat_bubble_rounded,
                    Colors.indigo,
                    [Colors.indigo.shade400, Colors.indigo.shade600],
                    () {
                      final chatProvider = context.read<ChatProvider>();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: chatProvider,
                            child: const ChatGroupsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    "Chức năng khác",
                    Icons.more_horiz_rounded,
                    Colors.grey,
                    [Colors.grey.shade400, Colors.grey.shade600],
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OtherFeaturesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F5DC), // Beige/cream
            Colors.white,
            const Color(0xFFF5F5DC).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo Section
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _buildLogo(),
          ),
          const SizedBox(width: 16),
          // Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'HỌC VIỆN KỸ THUẬT MẬT MÃ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    letterSpacing: 0.8,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        offset: const Offset(1.5, 1.5),
                        blurRadius: 3,
                        color: Colors.amber.shade600.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Academy of Cryptography Techniques',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade800,
                    letterSpacing: 0.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    // Load logo image from assets
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        width: 90,
        height: 90,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Try alternative file names
          return Image.asset(
            'assets/images/Logo.png',
            width: 90,
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to custom logo if image not found
              return _buildCustomLogo();
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomLogo() {
    return Container(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer red ring
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.shade700,
                width: 5,
              ),
            ),
          ),
          // Yellow ring
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.amber.shade600,
                width: 4,
              ),
            ),
          ),
          // Inner white circle
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Key icon (top)
                Positioned(
                  top: 18,
                  child: Icon(
                    Icons.vpn_key,
                    color: Colors.grey.shade800,
                    size: 22,
                  ),
                ),
                // Book icon (bottom)
                Positioned(
                  bottom: 18,
                  child: Icon(
                    Icons.menu_book,
                    color: Colors.grey.shade800,
                    size: 20,
                  ),
                ),
                // Stars on sides
                Positioned(
                  left: 10,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                    size: 14,
                  ),
                ),
                Positioned(
                  right: 10,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber.shade600,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
