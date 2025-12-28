import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class LecturerClassDetailScreen extends StatefulWidget {
  final int classId;
  final String courseName;

  const LecturerClassDetailScreen({
    super.key,
    required this.classId,
    required this.courseName,
  });

  @override
  State<LecturerClassDetailScreen> createState() =>
      _LecturerClassDetailScreenState();
}

class _LecturerClassDetailScreenState extends State<LecturerClassDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _students = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await _apiClient.client.get(
        '/lecturers/classes/${widget.classId}/students',
      );
      setState(() {
        _students = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load students';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateGrade(
    int enrollmentId,
    String gradeType,
    double score,
  ) async {
    try {
      await _apiClient.client.post(
        '/lecturers/grades',
        data: {
          'enrollment_id': enrollmentId,
          'grade_type': gradeType,
          'score': score,
          'weight': gradeType == 'midterm' ? 0.3 : 0.7,
        },
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật điểm thành công')));
      _fetchStudents();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lỗi cập nhật điểm')));
    }
  }

  void _showGradeDialog(dynamic student) {
    final midtermController = TextEditingController(
      text: student['midterm_grade']?.toString() ?? '',
    );
    final finalController = TextEditingController(
      text: student['final_grade']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập điểm: ${student['student_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: midtermController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Điểm Giữa kỳ (0-10)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: finalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Điểm Cuối kỳ (0-10)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              bool hasUpdate = false;
              final midterm = double.tryParse(midtermController.text);
              if (midterm != null && midterm >= 0 && midterm <= 10) {
                _updateGrade(student['enrollment_id'], 'midterm', midterm);
                hasUpdate = true;
              }

              final final_ = double.tryParse(finalController.text);
              if (final_ != null && final_ >= 0 && final_ <= 10) {
                _updateGrade(student['enrollment_id'], 'final', final_);
                hasUpdate = true;
              }

              if (hasUpdate) {
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                final midterm = student['midterm_grade'];
                final final_ = student['final_grade'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(student['student_name']?[0] ?? 'S'),
                    ),
                    title: Text(student['student_name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MSSV: ${student['student_id']}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'GK: ${midterm?.toString() ?? '-'}',
                              style: TextStyle(
                                color: midterm != null
                                    ? Colors.blue
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'CK: ${final_?.toString() ?? '-'}',
                              style: TextStyle(
                                color: final_ != null
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showGradeDialog(student),
                  ),
                );
              },
            ),
    );
  }
}
