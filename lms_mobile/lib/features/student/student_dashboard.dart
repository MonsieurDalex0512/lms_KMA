import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import '../../shared/profile_screen.dart';
import 'student_home_screen.dart';
import 'search_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentHomeScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _currentIndex == 0
          ? _buildCustomAppBar(context, authProvider)
          : AppBar(
              title: Text(_getTitle()),
              elevation: 0,
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Tìm kiếm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Trang chủ';
      case 1:
        return 'Tìm kiếm';
      case 2:
        return 'Cá nhân';
      default:
        return 'Dashboard';
    }
  }

  PreferredSizeWidget _buildCustomAppBar(BuildContext context, AuthProvider authProvider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F0E3), // Light beige background
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main title with red color and yellow shadow
                      Stack(
                        children: [
                          // Yellow shadow
                          Positioned(
                            left: 1,
                            top: 1,
                            child: Text(
                              'HỌC VIỆN KỸ THUẬT MẬT MÃ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow.shade700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Red text
                          Text(
                            'HỌC VIỆN KỸ THUẬT MẬT MÃ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE7000F), // Red
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Subtitle with golden-orange color and yellow shadow
                      Stack(
                        children: [
                          // Yellow shadow
                          Positioned(
                            left: 1,
                            top: 1,
                            child: Text(
                              'ACADEMY OF CRYPTOGRAPHY TECHNIQUES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow.shade700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          // Golden-orange text
                          Text(
                            'ACADEMY OF CRYPTOGRAPHY TECHNIQUES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD49527), // Golden-orange
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFFE7000F)),
                  onPressed: () => authProvider.logout(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
