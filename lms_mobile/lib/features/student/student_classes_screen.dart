import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'student_provider.dart';
import '../../core/api_client.dart';

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _currentSemester;
  List<dynamic> _semesters = [];
  String? _selectedPastSemester;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      print('Loading data in StudentClassesScreen...');
      final studentProvider = context.read<StudentProvider>();
      
      // Fetch classes
      await studentProvider.fetchClasses();
      print('Classes fetched: ${studentProvider.classes.length}');
      print('Classes data: ${studentProvider.classes}');
      
      if (studentProvider.error != null) {
        print('Error from provider: ${studentProvider.error}');
      }
      
      // Fetch academic summary để lấy danh sách semester
      final summary = await studentProvider.fetchAcademicSummary();
      print('Academic summary: $summary');
      
      if (summary != null && summary['semester_results'] != null) {
        final semesterResults = summary['semester_results'] as List<dynamic>;
        print('Semester results: ${semesterResults.length}');
        if (semesterResults.isNotEmpty) {
          setState(() {
            _semesters = semesterResults;
            // Lấy semester mới nhất làm current semester
            _currentSemester = semesterResults.last['semester_code'];
            // Mặc định chọn semester đầu tiên cho tab "Lớp đã học"
            if (semesterResults.length > 1) {
              _selectedPastSemester = semesterResults[semesterResults.length - 2]['semester_code'];
            } else if (semesterResults.isNotEmpty) {
              _selectedPastSemester = semesterResults[0]['semester_code'];
            }
          });
        }
      }
    } catch (e) {
      print('Error in _loadData: $e');
    }
  }

  List<dynamic> _getCurrentSemesterClasses(List<dynamic> classes) {
    print('_getCurrentSemesterClasses: currentSemester=$_currentSemester, totalClasses=${classes.length}');
    if (_currentSemester == null) {
      print('No current semester set, returning all classes');
      return classes;
    }
    final filtered = classes.where((cls) => cls['semester'] == _currentSemester).toList();
    print('Filtered to ${filtered.length} classes for semester $_currentSemester');
    return filtered;
  }

  List<dynamic> _getPastSemesterClasses(List<dynamic> classes) {
    if (_selectedPastSemester == null) return [];
    return classes.where((cls) => cls['semester'] == _selectedPastSemester).toList();
  }

  Future<void> _showClassDetailDialog(BuildContext context, Map<String, dynamic> cls) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ClassDetailDialog(classInfo: cls, apiClient: _apiClient),
    );
  }

  Widget _buildClassList(List<dynamic> classes) {
    if (classes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Chưa có lớp học nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.blue, size: 32),
            title: Text(
              cls['course_name'] ?? 'Class ${cls['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Phòng: ${cls['room'] ?? 'N/A'}'),
                Text('Giảng viên: ${cls['lecturer_name'] ?? 'N/A'}'),
                if (cls['semester'] != null)
                  Text('Học kỳ: ${cls['semester']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showClassDetailDialog(context, cls),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lớp Sinh Viên'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lớp học kỳ này'),
            Tab(text: 'Lớp đã học'),
          ],
        ),
      ),
      body: studentProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : studentProvider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi: ${studentProvider.error}',
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Lớp học kỳ này
                      Builder(
                        builder: (context) {
                          final currentClasses = _getCurrentSemesterClasses(studentProvider.classes);
                          print('Current semester: $_currentSemester');
                          print('All classes: ${studentProvider.classes.length}');
                          print('Filtered classes: ${currentClasses.length}');
                          return _buildClassList(currentClasses);
                        },
                      ),
                  
                  // Tab 2: Lớp đã học
                  Column(
                    children: [
                      // Dropdown chọn học kỳ
                      if (_semesters.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedPastSemester,
                            isExpanded: true,
                            hint: const Text('Chọn học kỳ'),
                            underline: const SizedBox(),
                            items: _semesters.map((sem) {
                              return DropdownMenuItem<String>(
                                value: sem['semester_code'],
                                child: Text('${sem['semester_name']} (${sem['semester_code']})'),
                              );
                            }).toList(),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPastSemester = value;
                              });
                            },
                          ),
                        ),
                      // Danh sách lớp đã học
                      Expanded(
                        child: _buildClassList(_getPastSemesterClasses(studentProvider.classes)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

// Dialog riêng để hiển thị chi tiết lớp học và danh sách sinh viên
class _ClassDetailDialog extends StatefulWidget {
  final Map<String, dynamic> classInfo;
  final ApiClient apiClient;

  const _ClassDetailDialog({
    required this.classInfo,
    required this.apiClient,
  });

  @override
  State<_ClassDetailDialog> createState() => _ClassDetailDialogState();
}

class _ClassDetailDialogState extends State<_ClassDetailDialog> {
  List<dynamic>? _students;
  bool _isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      print('Fetching students for class ${widget.classInfo['id']}');
      final response = await widget.apiClient.client.get('/students/classes/${widget.classInfo['id']}/students');
      print('Response status: ${response.statusCode}');
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      
      if (mounted) {
        setState(() {
          _students = response.data is List ? response.data : [];
          _isLoadingStudents = false;
        });
        print('Updated state: ${_students?.length} students');
      }
    } catch (e) {
      print('Error fetching class students: $e');
      if (e is DioException) {
        print('DioException details: ${e.response?.statusCode} - ${e.response?.data}');
      }
      if (mounted) {
        setState(() {
          _students = [];
          _isLoadingStudents = false;
        });
      }
    }
  }

  String _formatSchedule(Map<String, dynamic> cls) {
    List<String> parts = [];
    if (cls['day_of_week'] != null) {
      parts.add('Thứ ${cls['day_of_week'] + 1}');
    }
    if (cls['start_period'] != null && cls['end_period'] != null) {
      parts.add('Tiết ${cls['start_period']}-${cls['end_period']}');
    }
    if (cls['start_week'] != null && cls['end_week'] != null) {
      parts.add('Tuần ${cls['start_week']}-${cls['end_week']}');
    }
    return parts.isEmpty ? 'Chưa xếp lịch' : parts.join(' • ');
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cls = widget.classInfo;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls['course_name'] ?? 'Chi tiết lớp học',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Học kỳ: ${cls['semester'] ?? 'N/A'}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thông tin lớp học
                      _buildInfoCard(
                        icon: Icons.person,
                        title: 'Giảng viên',
                        value: cls['lecturer_name'] ?? 'N/A',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.room,
                        title: 'Phòng học',
                        value: cls['room'] ?? 'Online',
                        color: Colors.green,
                      ),
                      if (cls['day_of_week'] != null || cls['start_week'] != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Lịch học',
                          value: _formatSchedule(cls),
                          color: Colors.orange,
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Danh sách sinh viên
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.indigo.shade700, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Danh sách sinh viên (${_students?.length ?? 0})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingStudents)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_students == null || _students!.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Chưa có sinh viên nào trong lớp',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ..._students!.asMap().entries.map((entry) {
                          final index = entry.key;
                          final student = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student['full_name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (student['student_code'] != null)
                                        Text(
                                          'MSSV: ${student['student_code']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
