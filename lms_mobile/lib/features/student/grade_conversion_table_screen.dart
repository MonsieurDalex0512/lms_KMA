import 'package:flutter/material.dart';

class GradeConversionTableScreen extends StatelessWidget {
  const GradeConversionTableScreen({super.key});

  // Bảng quy đổi điểm theo ảnh
  static const List<Map<String, dynamic>> gradeTable = [
    {
      'range': '9.0 - 10.0',
      'scale4': '4.0',
      'letter': 'A+',
      'classification': 'Xuất sắc',
      'color': Colors.green,
    },
    {
      'range': '8.5 - 8.9',
      'scale4': '3.8',
      'letter': 'A',
      'classification': 'Giỏi',
      'color': Colors.green,
    },
    {
      'range': '7.8 - 8.4',
      'scale4': '3.5',
      'letter': 'B+',
      'classification': 'Khá',
      'color': Colors.blue,
    },
    {
      'range': '7.0 - 7.7',
      'scale4': '3.0',
      'letter': 'B',
      'classification': 'Khá',
      'color': Colors.blue,
    },
    {
      'range': '6.3 - 6.9',
      'scale4': '2.4',
      'letter': 'C+',
      'classification': 'Trung bình',
      'color': Colors.orange,
    },
    {
      'range': '5.5 - 6.2',
      'scale4': '2.0',
      'letter': 'C',
      'classification': 'Trung bình',
      'color': Colors.orange,
    },
    {
      'range': '4.8 - 5.4',
      'scale4': '1.5',
      'letter': 'D+',
      'classification': 'Trung bình yếu',
      'color': Colors.deepOrange,
    },
    {
      'range': '4.0 - 4.7',
      'scale4': '1.0',
      'letter': 'D',
      'classification': 'Trung bình yếu',
      'color': Colors.deepOrange,
    },
    {
      'range': '0.0 - 3.9',
      'scale4': '0.0',
      'letter': 'F',
      'classification': 'Kém',
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng quy đổi điểm'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade700, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.table_chart, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Table
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'THANG 10',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(width: 1, height: 20, color: Colors.grey.shade600),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'THANG 4',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(width: 1, height: 20, color: Colors.grey.shade600),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'ĐIỂM CHỮ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(width: 1, height: 20, color: Colors.grey.shade600),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'XẾP LOẠI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Table Rows
                    ...gradeTable.map((row) => _buildTableRow(row)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 1,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'GPA được tính bằng công thức: GPA = Σ(điểm_thang_4 × số_tín_chỉ) / Σ(số_tín_chỉ)',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
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

  Widget _buildTableRow(Map<String, dynamic> row) {
    final color = row['color'] as Color;
    
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                row['range'],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                row['scale4'],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                row['letter'],
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              child: Text(
                row['classification'],
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
