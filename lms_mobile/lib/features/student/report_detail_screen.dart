import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final data = await context.read<StudentProvider>().fetchReportDetail(widget.reportId);
    if (mounted) {
      setState(() {
        _report = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết yêu cầu'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Không tải được dữ liệu'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatusCard(),
                    SizedBox(height: 16),
                    _buildInfoCard(),
                    SizedBox(height: 16),
                    _buildDescriptionCard(),
                    if (_report!['dean_response'] != null) ...[
                      SizedBox(height: 16),
                      _buildResponseCard(),
                    ],
                  ],
                ),
    );
  }

  Widget _buildStatusCard() {
    Color color = Colors.grey;
    String statusText = '';
    IconData icon = Icons.help;

    switch (_report!['status']) {
      case 'pending':
        color = Colors.amber;
        statusText = 'Chờ xử lý';
        icon = Icons.hourglass_empty;
        break;
      case 'processing':
        color = Colors.blue;
        statusText = 'Đang xử lý';
        icon = Icons.update;
        break;
      case 'resolved':
        color = Colors.green;
        statusText = 'Đã giải quyết';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        statusText = 'Từ chối';
        icon = Icons.cancel;
        break;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trạng thái', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  Text(statusText, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(height: 24),
            _buildInfoRow('Tiêu đề', _report!['title']),
            SizedBox(height: 12),
            _buildInfoRow('Loại', _getReportTypeName(_report!['report_type'])),
            SizedBox(height: 12),
            _buildInfoRow('Ngày tạo', _formatDate(_report!['created_at'])),
            if (_report!['resolved_at'] != null) ...[
              SizedBox(height: 12),
              _buildInfoRow('Ngày xử lý', _formatDate(_report!['resolved_at'])),
            ],
            if (_report!['resolved_by_name'] != null) ...[
              SizedBox(height: 12),
              _buildInfoRow('Người xử lý', _report!['resolved_by_name']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mô tả chi tiết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(height: 24),
            Text(_report!['description'], style: TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.reply, color: Colors.blue),
                SizedBox(width: 8),
                Text('Phản hồi từ Ban giám hiệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
            Divider(height: 24),
            Text(_report!['dean_response'], style: TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  String _getReportTypeName(String type) {
    switch (type) {
      case 'academic':
        return '📚 Học tập';
      case 'administrative':
        return '📋 Hành chính';
      case 'technical':
        return '💻 Kỹ thuật';
      default:
        return '📌 Khác';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
