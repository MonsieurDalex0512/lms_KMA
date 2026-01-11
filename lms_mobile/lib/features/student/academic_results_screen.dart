import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class AcademicResultsScreen extends StatefulWidget {
  const AcademicResultsScreen({super.key});

  @override
  State<AcademicResultsScreen> createState() => _AcademicResultsScreenState();
}

class _AcademicResultsScreenState extends State<AcademicResultsScreen> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _selectedSemesterDetail;
  bool _isLoading = true;
  bool _isLoadingDetail = false;
  String? _selectedYear;
  String? _selectedSemesterCode;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final data = await context.read<StudentProvider>().fetchAcademicSummary();
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  List<String> _getAvailableYears() {
    if (_summary == null || _summary!['semester_results'] == null) return [];
    final semesters = _summary!['semester_results'] as List<dynamic>;
    final years = <String>{};
    for (var sem in semesters) {
      final code = sem['semester_code'] as String;
      // Extract year from semester code (e.g., "2024-2025_HK1" -> "2024-2025")
      if (code.contains('_')) {
        years.add(code.split('_')[0]);
      } else if (code.length >= 4) {
        // If format is different, try to extract year
        years.add(code.substring(0, 4));
      }
    }
    return years.toList()..sort((a, b) => b.compareTo(a)); // Sort descending
  }

  List<dynamic> _getSemestersForYear(String? year) {
    if (_summary == null || _summary!['semester_results'] == null || year == null) return [];
    final semesters = _summary!['semester_results'] as List<dynamic>;
    return semesters.where((sem) {
      final code = sem['semester_code'] as String;
      return code.contains(year);
    }).toList();
  }

  Future<void> _loadSemesterDetail(String semesterCode) async {
    setState(() {
      _isLoadingDetail = true;
      _selectedSemesterCode = semesterCode;
    });

    final data = await context.read<StudentProvider>().fetchSemesterDetail(semesterCode);
    if (mounted) {
      setState(() {
        _selectedSemesterDetail = data;
        _isLoadingDetail = false;
      });
    }
  }

  void _onYearChanged(String? year) {
    setState(() {
      _selectedYear = year;
      _selectedSemesterCode = null;
      _selectedSemesterDetail = null;
    });
  }

  void _onSemesterChanged(String? semesterCode) {
    if (semesterCode != null) {
      // Toggle: nếu đã chọn rồi thì đóng, nếu chưa thì mở
      if (_selectedSemesterCode == semesterCode) {
        setState(() {
          _selectedSemesterCode = null;
          _selectedSemesterDetail = null;
        });
      } else {
        _loadSemesterDetail(semesterCode);
      }
    } else {
      setState(() {
        _selectedSemesterCode = null;
        _selectedSemesterDetail = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Kết quả học tập'),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      const Text('Không tải được dữ liệu'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadSummary,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary Card
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    
                    // Chart Section
                    if (_summary != null && 
                        _summary!['semester_results'] != null && 
                        (_summary!['semester_results'] as List).isNotEmpty) ...[
                      _buildChartSection(),
                      const SizedBox(height: 24),
                    ],

                    // Filter Section
                    _buildFilterSection(),
                    const SizedBox(height: 20),
                    
                    // All Semesters List (với toggle detail)
                    _buildAllSemestersSection(),
                  ],
                ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) {
      return const SizedBox.shrink();
    }
    
    final cpa = (_summary?['cumulative_cpa']) ?? 0.0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getCPAGradientColors(cpa),
        ),
        boxShadow: [
          BoxShadow(
            color: _getGPAColor(cpa).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CPA Tích Lũy Toàn Khóa',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ((_summary?['cumulative_cpa']) ?? 0.0).toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white24),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryStat(
                    Icons.credit_card, 
                    'Tổng TC', 
                    (_summary?['total_registered_credits'] ?? 0).toString(), 
                    Colors.white
                  ),
                  _buildSummaryStat(
                    Icons.check_circle, 
                    'TC Đạt', 
                    (_summary?['total_completed_credits'] ?? 0).toString(), 
                    Colors.white
                  ),
                  _buildSummaryStat(
                    Icons.cancel, 
                    'TC Trượt', 
                    (_summary?['total_failed_credits'] ?? 0).toString(), 
                    Colors.white
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryStat(IconData icon, String label, String value, Color textColor) {
    return Column(
      children: [
        Icon(icon, color: textColor.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Lọc theo năm học và học kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Năm học',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedYear,
                            isExpanded: true,
                            hint: Text(
                              'Chọn năm học',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            items: _getAvailableYears().map((year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(year, style: const TextStyle(fontSize: 14)),
                                ),
                              );
                            }).toList(),
                            onChanged: _onYearChanged,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Học kỳ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSemesterCode,
                            isExpanded: true,
                            hint: Text(
                              'Chọn học kỳ',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                            items: _getSemestersForYear(_selectedYear).map((sem) {
                              return DropdownMenuItem<String>(
                                value: sem['semester_code'],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    sem['semester_name'] ?? sem['semester_code'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onSemesterChanged,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
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
    );
  }

  Widget _buildAllSemestersSection() {
    final semesters = (_summary?['semester_results'] as List<dynamic>? ?? []).reversed.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              'Tất cả học kỳ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...semesters.map((sem) {
          final semesterCode = sem['semester_code'] as String;
          final isExpanded = _selectedSemesterCode == semesterCode;
          
          return Column(
            children: [
              _buildSemesterCard(sem),
              // Toggle detail ngay dưới card
              if (isExpanded) ...[
                if (_isLoadingDetail)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(32),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                else if (_selectedSemesterDetail != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: _buildExpandedDetail(_selectedSemesterDetail!),
                  ),
              ],
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExpandedDetail(Map<String, dynamic> detail) {
    final gpa = detail['gpa'] ?? 0.0;
    final courses = detail['courses'] as List<dynamic>? ?? [];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPA Summary với gradient đẹp hơn
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGPAGradientColors(gpa),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getGPAColor(gpa).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GPA',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gpa.toStringAsFixed(2),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Wrap thay vì Row để tránh overflow
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDetailChip(Icons.credit_card, 'Tổng: ${detail['total_credits'] ?? 0} TC', Colors.white),
                      _buildDetailChip(Icons.check_circle, 'Đạt: ${detail['completed_credits'] ?? 0} TC', Colors.white),
                      _buildDetailChip(Icons.cancel, 'Trượt: ${detail['failed_credits'] ?? 0} TC', Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Courses List
            Row(
              children: [
                Icon(Icons.book, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Danh sách môn học',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${courses.length} môn',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Course Cards
            ...courses.map((course) => _buildCourseCard(course)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Biểu đồ GPA theo học kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.only(right: 16),
              child: _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard(Map<String, dynamic> sem) {
    final gpa = sem['gpa'] ?? 0.0;
    final isSelected = _selectedSemesterCode == sem['semester_code'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _onSemesterChanged(sem['semester_code']);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: isSelected ? 10 : 5,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // GPA Badge với gradient đẹp hơn
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getGPAGradientColors(gpa),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _getGPAColor(gpa).withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          gpa.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'GPA',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Semester Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sem['semester_name'] ?? sem['semester_code'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.calendar_today,
                              sem['semester_code'] ?? '',
                              Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.credit_card,
                              '${sem['completed_credits']}/${sem['total_credits']} TC',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow Icon với animation
                  AnimatedRotation(
                    turns: isSelected ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_summary == null || _summary!['semester_results'] == null) {
      return const Center(child: Text('Không có dữ liệu'));
    }
    final results = _summary!['semester_results'] as List<dynamic>;
    if (results.isEmpty) {
      return const Center(child: Text('Không có dữ liệu'));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < results.length; i++) {
        spots.add(FlSpot(i.toDouble(), (results[i]['gpa'] ?? 0.0).toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < results.length) {

                   String code = results[index]['semester_code'].toString(); 
                   if (results.length > 5 && index % 2 != 0) return const SizedBox.shrink();
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(code, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                   );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 12));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (results.length - 1).toDouble(),
        minY: 0,
        maxY: 4.0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true, 
              color: Colors.blue.withOpacity(0.1)
            ),
          ),
        ],
      ),
    );
  }

  Color _getGPAColor(double? gpa) {
    if (gpa == null) return Colors.grey;
    if (gpa >= 3.2) return Colors.green;
    if (gpa >= 2.5) return Colors.blue;
    return Colors.orange;
  }

  List<Color> _getGPAGradientColors(double? gpa) {
    if (gpa == null) {
      return [Colors.grey.shade600, Colors.grey.shade400];
    }
    if (gpa >= 3.5) {
      // Xuất sắc - Gradient xanh lá đẹp
      return [
        const Color(0xFF10B981), // Emerald 500
        const Color(0xFF34D399), // Emerald 400
        const Color(0xFF6EE7B7), // Emerald 300
      ];
    }
    if (gpa >= 3.2) {
      // Giỏi - Gradient xanh dương
      return [
        const Color(0xFF3B82F6), // Blue 500
        const Color(0xFF60A5FA), // Blue 400
        const Color(0xFF93C5FD), // Blue 300
      ];
    }
    if (gpa >= 2.5) {
      // Khá - Gradient xanh nhạt
      return [
        const Color(0xFF06B6D4), // Cyan 500
        const Color(0xFF22D3EE), // Cyan 400
      ];
    }
    if (gpa >= 2.0) {
      // Trung bình - Gradient cam
      return [
        const Color(0xFFF59E0B), // Amber 500
        const Color(0xFFFBBF24), // Amber 400
      ];
    }
    // Yếu - Gradient đỏ
    return [
      const Color(0xFFEF4444), // Red 500
      const Color(0xFFF87171), // Red 400
    ];
  }

  List<Color> _getCPAGradientColors(double? cpa) {
    if (cpa == null) {
      return [
        const Color(0xFF6366F1), // Indigo 500
        const Color(0xFF818CF8), // Indigo 400
        const Color(0xFFA5B4FC), // Indigo 300
      ];
    }
    if (cpa >= 3.5) {
      return [
        const Color(0xFF059669), // Emerald 600
        const Color(0xFF10B981), // Emerald 500
        const Color(0xFF34D399), // Emerald 400
      ];
    }
    if (cpa >= 3.2) {
      return [
        const Color(0xFF2563EB), // Blue 600
        const Color(0xFF3B82F6), // Blue 500
        const Color(0xFF60A5FA), // Blue 400
      ];
    }
    if (cpa >= 2.5) {
      return [
        const Color(0xFF0891B2), // Cyan 600
        const Color(0xFF06B6D4), // Cyan 500
      ];
    }
    if (cpa >= 2.0) {
      return [
        const Color(0xFFD97706), // Amber 600
        const Color(0xFFF59E0B), // Amber 500
      ];
    }
    return [
      const Color(0xFFDC2626), // Red 600
      const Color(0xFFEF4444), // Red 500
    ];
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final score10 = course['score_10'];
    final score4 = course['score_4'];
    final letterGrade = course['letter_grade'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['course_name'] ?? 'Môn học',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCourseInfoChip(
                            Icons.code,
                            course['course_code'] ?? '',
                            Colors.blue,
                          ),
                          _buildCourseInfoChip(
                            Icons.credit_card,
                            '${course['credits'] ?? 0} TC',
                            Colors.green,
                          ),
                          if (letterGrade != null)
                            _buildCourseInfoChip(
                              Icons.grade,
                              'Điểm chữ: $letterGrade',
                              _getScoreColor(score10),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (score10 != null || score4 != null)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getScoreColor(score10),
                          _getScoreColor(score10).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _getScoreColor(score10).withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (score10 != null)
                          Text(
                            score10.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        if (score4 != null)
                          Text(
                            '(${score4.toStringAsFixed(1)})',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double? score) {
    if (score == null) return Colors.grey;
    if (score >= 8.0) return Colors.green;
    if (score >= 6.5) return Colors.blue;
    if (score >= 5.0) return Colors.orange;
    return Colors.red;
  }
}
