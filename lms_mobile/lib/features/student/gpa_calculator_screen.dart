import 'package:flutter/material.dart';
import '../../core/api_client.dart';

class GPACalculatorScreen extends StatefulWidget {
  const GPACalculatorScreen({super.key});

  @override
  State<GPACalculatorScreen> createState() => _GPACalculatorScreenState();
}

class _GPACalculatorScreenState extends State<GPACalculatorScreen> {
  final ApiClient _apiClient = ApiClient();
  String? _departmentName;
  int _totalCredits = 130;
  int _completedCredits = 0;
  double _currentGPA = 0.0;
  bool _isLoading = true;

  final TextEditingController _targetGPAController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    _targetGPAController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfo() async {
    try {
      final response = await _apiClient.client.get('/students/me');
      if (response.data != null) {
        setState(() {
          _departmentName = response.data['department_name'] ?? 'Khoa/Viện';
        });
      }

      // Load academic summary để lấy thông tin tín chỉ
      final summaryResponse = await _apiClient.client.get('/students/academic-summary');
      if (summaryResponse.data != null) {
        setState(() {
          _completedCredits = summaryResponse.data['total_completed_credits'] ?? 0;
          _currentGPA = summaryResponse.data['cumulative_cpa'] ?? 0.0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading student info: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  int get _remainingCredits => _totalCredits - _completedCredits;

  void _showGradeScaleDialog() {
    showDialog(
      context: context,
      builder: (context) => _GradeScaleDialog(),
    );
  }

  void _calculateTargetGPA() {
    final targetGPA = double.tryParse(_targetGPAController.text);
    if (targetGPA == null || targetGPA < 0 || targetGPA > 4.0) {
      _showErrorDialog('Vui lòng nhập GPA hợp lệ (0.0 - 4.0)');
      return;
    }

    if (_remainingCredits <= 0) {
      _showErrorDialog('Bạn đã hoàn thành đủ số tín chỉ yêu cầu!');
      return;
    }

    // Tính GPA cần đạt: (targetGPA * totalCredits - currentGPA * completedCredits) / remainingCredits
    final requiredGPA = (_totalCredits * targetGPA - _completedCredits * _currentGPA) / _remainingCredits;

    if (requiredGPA > 4.0) {
      _showErrorDialog(
        'Không thể đạt được GPA ${targetGPA.toStringAsFixed(2)}!\n'
        'Với ${_remainingCredits} tín chỉ còn lại, bạn cần đạt GPA tối đa 4.0, '
        'nhưng vẫn chỉ đạt được GPA tối đa ${((_completedCredits * _currentGPA + _remainingCredits * 4.0) / _totalCredits).toStringAsFixed(2)}.',
      );
      return;
    }

    if (requiredGPA < 0) {
      _showErrorDialog('Bạn đã đạt hoặc vượt mức GPA mong đợi!');
      return;
    }

    _showResultDialog(targetGPA, requiredGPA);
  }

  void _showResultDialog(double targetGPA, double requiredGPA) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('Kết quả tính toán')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('GPA hiện tại:', _currentGPA.toStringAsFixed(2)),
            _buildResultRow('Tín chỉ đã hoàn thành:', '$_completedCredits / $_totalCredits'),
            _buildResultRow('Tín chỉ còn lại:', '$_remainingCredits'),
            const Divider(height: 24),
            _buildResultRow('GPA mong đợi:', targetGPA.toStringAsFixed(2), isHighlight: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getGPAColor(requiredGPA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getGPAColor(requiredGPA), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: _getGPAColor(requiredGPA)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPA trung bình cần đạt:',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          requiredGPA.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getGPAColor(requiredGPA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlight ? 16 : 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isHighlight ? Colors.blue.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('Thông báo')),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Color _getGPAColor(double gpa) {
    if (gpa >= 3.2) return Colors.green;
    if (gpa >= 2.5) return Colors.blue;
    if (gpa >= 2.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính chỉ số GPA'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card với thông tin Khoa/Viện và tổng tín chỉ
                  Card(
                    elevation: 4,
                    color: Colors.blue.shade700,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _departmentName ?? 'Khoa/Viện',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tổng số tín chỉ: $_totalCredits',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Đã hoàn thành', '$_completedCredits TC', Colors.green),
                              _buildStatCard('Còn lại', '$_remainingCredits TC', Colors.orange),
                              _buildStatCard('GPA hiện tại', _currentGPA.toStringAsFixed(2), Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nút Thang điểm
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showGradeScaleDialog,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Thang điểm'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200, width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phần tính GPA mong đợi
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate, color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Tính GPA mong đợi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _targetGPAController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Nhập GPA mong đợi (0.0 - 4.0)',
                              hintText: 'Ví dụ: 3.5',
                              prefixIcon: const Icon(Icons.star),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculateTargetGPA,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Tính toán',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Dialog hiển thị bảng quy đổi điểm
class _GradeScaleDialog extends StatelessWidget {
  final List<Map<String, dynamic>> _gradeScale = [
    {'range': '9.0 - 10.0', 'scale4': '4', 'letter': 'A+', 'classification': 'Xuất sắc', 'color': Colors.green},
    {'range': '8.5 - 8.9', 'scale4': '3.8', 'letter': 'A', 'classification': 'Giỏi', 'color': Colors.green},
    {'range': '7.8 - 8.4', 'scale4': '3.5', 'letter': 'B+', 'classification': 'Khá', 'color': Colors.blue},
    {'range': '7.0 - 7.7', 'scale4': '3', 'letter': 'B', 'classification': 'Khá', 'color': Colors.blue},
    {'range': '6.3 - 6.9', 'scale4': '2.4', 'letter': 'C+', 'classification': 'Trung bình', 'color': Colors.orange},
    {'range': '5.5 - 6.2', 'scale4': '2', 'letter': 'C', 'classification': 'Trung bình', 'color': Colors.orange},
    {'range': '4.8 - 5.4', 'scale4': '1.5', 'letter': 'D+', 'classification': 'Trung bình yếu', 'color': Colors.red},
    {'range': '4.0 - 4.7', 'scale4': '1', 'letter': 'D', 'classification': 'Trung bình yếu', 'color': Colors.red},
    {'range': '0.0 - 3.9', 'scale4': '0', 'letter': 'F', 'classification': 'Kém', 'color': Colors.red},
  ];

  _GradeScaleDialog({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: Colors.blue.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Bảng quy đổi điểm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Table
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!, width: 1),
                    children: [
                      // Header row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: [
                          _buildHeaderCell('THANG 10'),
                          _buildHeaderCell('THANG 4'),
                          _buildHeaderCell('ĐIỂM CHỮ'),
                          _buildHeaderCell('XẾP LOẠI'),
                        ],
                      ),
                      // Data rows
                      ..._gradeScale.map((grade) {
                        final color = grade['color'] as Color;
                        return TableRow(
                          decoration: BoxDecoration(color: color.withOpacity(0.1)),
                          children: [
                            _buildDataCell(grade['range'], color),
                            _buildDataCell(grade['scale4']),
                            _buildDataCell(grade['letter'], color),
                            _buildDataCell(grade['classification']),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            // Footer button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check),
                  label: const Text('Đóng'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: color ?? Colors.black87,
          fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
