import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';
import 'grade_conversion_table_screen.dart';

class GPACalculatorScreen extends StatefulWidget {
  const GPACalculatorScreen({super.key});

  @override
  State<GPACalculatorScreen> createState() => _GPACalculatorScreenState();
}

class _GPACalculatorScreenState extends State<GPACalculatorScreen> {
  final TextEditingController _targetGPAController = TextEditingController();
  final TextEditingController _remainingCreditsController = TextEditingController();
  Map<String, dynamic>? _academicSummary;
  bool _isLoading = true;
  double? _requiredGPA;
  bool _isAchievable = false;
  String? _calculationResult;

  @override
  void initState() {
    super.initState();
    _loadAcademicSummary();
  }

  @override
  void dispose() {
    _targetGPAController.dispose();
    _remainingCreditsController.dispose();
    super.dispose();
  }

  Future<void> _loadAcademicSummary() async {
    final data = await context.read<StudentProvider>().fetchAcademicSummary();
    if (mounted) {
      setState(() {
        _academicSummary = data;
        _isLoading = false;
      });
    }
  }

  void _calculateRequiredGPA() {
    if (_targetGPAController.text.isEmpty || _remainingCreditsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final targetGPA = double.tryParse(_targetGPAController.text);
    final remainingCredits = int.tryParse(_remainingCreditsController.text);

    if (targetGPA == null || remainingCredits == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số hợp lệ')),
      );
      return;
    }

    if (targetGPA < 0 || targetGPA > 4.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPA mong muốn phải từ 0.0 đến 4.0')),
      );
      return;
    }

    if (remainingCredits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tín chỉ còn lại phải lớn hơn 0')),
      );
      return;
    }

    final currentCPA = _academicSummary?['cumulative_cpa'] ?? 0.0;
    final totalRegisteredCredits = _academicSummary?['total_registered_credits'] ?? 0;

    // Công thức: targetGPA = (currentCPA * totalRegisteredCredits + requiredGPA * remainingCredits) / (totalRegisteredCredits + remainingCredits)
    // => requiredGPA = (targetGPA * (totalRegisteredCredits + remainingCredits) - currentCPA * totalRegisteredCredits) / remainingCredits

    final totalCredits = totalRegisteredCredits + remainingCredits;
    final requiredGPA = (targetGPA * totalCredits - currentCPA * totalRegisteredCredits) / remainingCredits;

    setState(() {
      _requiredGPA = requiredGPA;
      _isAchievable = requiredGPA >= 0 && requiredGPA <= 4.0;
      
      if (!_isAchievable) {
        if (requiredGPA > 4.0) {
          _calculationResult = 'Không thể đạt được GPA mong muốn. Cần GPA trung bình ${requiredGPA.toStringAsFixed(2)} (vượt quá 4.0)';
        } else {
          _calculationResult = 'Không thể đạt được GPA mong muốn với số tín chỉ còn lại.';
        }
      } else {
        _calculationResult = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính điểm GPA'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Xem thang điểm',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GradeConversionTableScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _academicSummary == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      const Text('Không tải được dữ liệu'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAcademicSummary,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current CPA Card
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade700, Colors.blue.shade400],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CPA Tích Lũy Hiện Tại',
                                        style: TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        (_academicSummary!['cumulative_cpa'] ?? 0.0).toStringAsFixed(2),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school, color: Colors.white, size: 32),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: Colors.white24),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatItem('Tổng TC', _academicSummary!['total_registered_credits']?.toString() ?? '0', Colors.white),
                                  _buildStatItem('TC Đạt', _academicSummary!['total_completed_credits']?.toString() ?? '0', Colors.white),
                                  _buildStatItem('TC Trượt', _academicSummary!['total_failed_credits']?.toString() ?? '0', Colors.white),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calculate, color: Colors.blue.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Nhập thông tin',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _targetGPAController,
                                decoration: InputDecoration(
                                  labelText: 'GPA mong muốn (0.0 - 4.0)',
                                  hintText: 'Ví dụ: 3.5',
                                  prefixIcon: const Icon(Icons.star),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _remainingCreditsController,
                                decoration: InputDecoration(
                                  labelText: 'Số tín chỉ còn lại',
                                  hintText: 'Ví dụ: 30',
                                  prefixIcon: const Icon(Icons.credit_card),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _calculateRequiredGPA,
                                  icon: const Icon(Icons.calculate),
                                  label: const Text('Tính toán'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Result Section
                      if (_requiredGPA != null) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _isAchievable ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isAchievable ? Icons.check_circle : Icons.error,
                                      color: _isAchievable ? Colors.green.shade700 : Colors.red.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isAchievable ? 'Có thể đạt được' : 'Không thể đạt được',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _isAchievable ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isAchievable) ...[
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300, width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'GPA trung bình cần đạt',
                                          style: TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _requiredGPA!.toStringAsFixed(2),
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _getGradeFromGPA(_requiredGPA!),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.green.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoBox(
                                    'Để đạt GPA ${_targetGPAController.text} với ${_remainingCreditsController.text} tín chỉ còn lại, bạn cần đạt GPA trung bình ${_requiredGPA!.toStringAsFixed(2)} cho các môn học còn lại.',
                                    Colors.blue.shade50,
                                    Colors.blue.shade700,
                                  ),
                                ] else ...[
                                  _buildInfoBox(
                                    _calculationResult ?? 'Không thể đạt được GPA mong muốn.',
                                    Colors.red.shade50,
                                    Colors.red.shade700,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Grade Conversion Table Button
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GradeConversionTableScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.table_chart, color: Colors.purple.shade700, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Bảng quy đổi điểm',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Xem thang điểm 10, 4 và điểm chữ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey.shade400),
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

  Widget _buildStatItem(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoBox(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _getGradeFromGPA(double gpa) {
    if (gpa >= 3.8) return 'A - Giỏi';
    if (gpa >= 3.5) return 'B+ - Khá';
    if (gpa >= 3.0) return 'B - Khá';
    if (gpa >= 2.4) return 'C+ - Trung bình';
    if (gpa >= 2.0) return 'C - Trung bình';
    if (gpa >= 1.5) return 'D+ - Trung bình yếu';
    if (gpa >= 1.0) return 'D - Trung bình yếu';
    return 'F - Kém';
  }
}
