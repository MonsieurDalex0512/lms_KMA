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
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả học tập')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _summary == null
              ? const Center(child: Text('Không tải được dữ liệu'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 4,
                      color: Colors.blue.shade700,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CPA Tích Lũy Toàn Khóa', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    Text(
                                      (_summary!['cumulative_cpa'] ?? 0.0).toStringAsFixed(2),
                                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(color: Colors.white24),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildCPAStat('Tổng TC', _summary!['total_registered_credits'].toString()),
                                _buildCPAStat('TC Đạt', _summary!['total_completed_credits'].toString()),
                                _buildCPAStat('TC Trượt', _summary!['total_failed_credits'].toString()),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    if (_summary!['semester_results'] != null && (_summary!['semester_results'] as List).isNotEmpty) ...[
                      Text('Biểu Đồ GPA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        padding: EdgeInsets.only(right: 16, left: 0),
                        child: _buildChart(),
                      ),
                      SizedBox(height: 24),
                    ],

                    Text('GPA Từng Học Kỳ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ...(_summary!['semester_results'] as List<dynamic>? ?? []).reversed.map((sem) {
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(sem['semester_name'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${sem['semester_code']} • ${sem['completed_credits']}/${sem['total_credits']} TC'),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getGPAColor(sem['gpa']),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (sem['gpa'] ?? 0.0).toStringAsFixed(2),
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
    );
  }

  Widget _buildChart() {
    final results = _summary!['semester_results'] as List<dynamic>;

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

  Widget _buildCPAStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Color _getGPAColor(double? gpa) {
    if (gpa == null) return Colors.grey;
    if (gpa >= 3.2) return Colors.green;
    if (gpa >= 2.5) return Colors.blue;
    return Colors.orange;
  }
}
