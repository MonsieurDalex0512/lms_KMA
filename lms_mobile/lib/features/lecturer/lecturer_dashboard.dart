import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'lecturer_provider.dart';
import 'lecturer_class_detail_screen.dart';
import '../chat/screens/chat_groups_screen.dart';
import '../../shared/profile_screen.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedYear;
  String? _selectedSemester;
  String _filterType = 'all'; // 'all', 'current', 'past'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => context.read<LecturerProvider>().fetchClasses());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getAvailableYears() {
    final classes = context.read<LecturerProvider>().classes;
    final years = <String>{};
    for (var cls in classes) {
      final semester = cls['semester'] as String?;
      if (semester != null) {
        if (semester.contains('_')) {
          years.add(semester.split('_')[0]);
        } else if (semester.length >= 4) {
          years.add(semester.substring(0, 4));
        }
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<String> _getAvailableSemesters() {
    final classes = context.read<LecturerProvider>().classes;
    final semesters = <String>{};
    for (var cls in classes) {
      final semester = cls['semester'] as String?;
      if (semester != null) {
        if (_selectedYear == null || semester.contains(_selectedYear!)) {
          semesters.add(semester);
        }
      }
    }
    return semesters.toList()..sort((a, b) => b.compareTo(a));
  }

  List<dynamic> _getFilteredClasses() {
    final allClasses = context.read<LecturerProvider>().classes;
    
    List<dynamic> filtered = allClasses;
    
    // Filter by type
    if (_filterType == 'current') {
      filtered = filtered.where((cls) => cls['is_current'] == true).toList();
    } else if (_filterType == 'past') {
      filtered = filtered.where((cls) => cls['is_current'] != true).toList();
    }
    
    // Filter by year
    if (_selectedYear != null) {
      filtered = filtered.where((cls) {
        final semester = cls['semester'] as String?;
        return semester != null && semester.contains(_selectedYear!);
      }).toList();
    }
    
    // Filter by semester
    if (_selectedSemester != null) {
      filtered = filtered.where((cls) => cls['semester'] == _selectedSemester).toList();
    }
    
    return filtered;
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
            Tab(text: 'Chat', icon: Icon(Icons.chat)),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                          SizedBox(height: 16),
                          Text(lecturerProvider.error!),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => lecturerProvider.fetchClasses(),
                            icon: Icon(Icons.refresh),
                            label: Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : lecturerProvider.classes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.class_, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Chưa có lớp giảng dạy',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => lecturerProvider.fetchClasses(),
                          child: Column(
                            children: [
                              // Filter Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Filter Type Tabs
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildFilterChip('all', 'Tất cả', Icons.list),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: _buildFilterChip('current', 'Lớp hiện tại', Icons.school),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: _buildFilterChip('past', 'Lớp đã dạy', Icons.history),
                                        ),
                                      ],
                                    ),
                                    // Year and Semester Filters - Only show when not filtering by "current"
                                    if (_filterType != 'current') ...[
                                      SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDropdown(
                                              label: 'Năm học',
                                              value: _selectedYear,
                                              items: _getAvailableYears(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedYear = value;
                                                  _selectedSemester = null;
                                                });
                                              },
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: _buildDropdown(
                                              label: 'Học kỳ',
                                              value: _selectedSemester,
                                              items: _getAvailableSemesters(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _selectedSemester = value;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              
                              // Classes List
                              Expanded(
                                child: _getFilteredClasses().isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                                            SizedBox(height: 16),
                                            Text(
                                              'Không tìm thấy lớp học',
                                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16),
                                        itemCount: _getFilteredClasses().length,
                                        itemBuilder: (context, index) {
                                          final cls = _getFilteredClasses()[index];
                                          return _buildClassCard(cls);
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
          const ChatGroupsScreen(),
          const ProfileScreen(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterType == value;
    return InkWell(
      onTap: () {
        setState(() {
          _filterType = value;
          // Clear filters when switching to "current" or "all"
          if (value == 'current' || value == 'all') {
            _selectedYear = null;
            _selectedSemester = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey.shade700),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text('Chọn $label', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Tất cả', style: TextStyle(fontSize: 14)),
                  ),
                ),
                ...items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(item, style: TextStyle(fontSize: 14)),
                    ),
                  );
                }),
              ],
              onChanged: onChanged,
              padding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls) {
    final isCurrent = cls['is_current'] == true;
    final courseName = cls['course_name'] ?? cls['course']?['name'] ?? 'Môn học';
    final classCode = cls['class_code'] ?? cls['code'] ?? '';
    final enrolledCount = cls['enrolled_count'] ?? 0;
    final maxStudents = cls['max_students'] ?? 0;
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent ? Colors.green.shade300 : Colors.transparent,
          width: isCurrent ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LecturerClassDetailScreen(
                classId: cls['id'],
                courseName: '$classCode - $courseName',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.green.shade50 : Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isCurrent ? Icons.school : Icons.class_,
                      color: isCurrent ? Colors.green.shade700 : Colors.indigo.shade700,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                classCode,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Hiện tại',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          courseName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      Icons.people,
                      '$enrolledCount/$maxStudents SV',
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  if (cls['room'] != null)
                    Expanded(
                      child: _buildInfoChip(
                        Icons.room,
                        cls['room'] ?? 'Online',
                        Colors.orange,
                      ),
                    ),
                ],
              ),
              if (cls['day_of_week'] != null || cls['start_period'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    if (cls['day_of_week'] != null)
                      _buildInfoChip(
                        Icons.calendar_today,
                        'Thứ ${cls['day_of_week'] + 1}',
                        Colors.purple,
                      ),
                    if (cls['start_period'] != null) ...[
                      SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.access_time,
                        'Tiết ${cls['start_period']}-${cls['end_period']}',
                        Colors.teal,
                      ),
                    ],
                  ],
                ),
              ],
              if (cls['semester'] != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: Colors.grey.shade600),
                    SizedBox(width: 4),
                    Text(
                      cls['semester'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
