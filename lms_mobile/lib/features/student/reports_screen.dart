import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'student_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<StudentProvider>().fetchMyReports());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu của tôi'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-report');
          provider.fetchMyReports();
        },
        icon: Icon(Icons.add),
        label: Text('Tạo yêu cầu'),
        backgroundColor: Colors.indigo,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchMyReports(),
              child: provider.reports.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, size: 80, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text('Chưa có yêu cầu nào', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                              SizedBox(height: 8),
                              Text('Nhấn nút bên dưới để tạo yêu cầu mới', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.reports.length,
                  itemBuilder: (context, index) {
                    final report = provider.reports[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getStatusIcon(report['status']),
                        title: Text(report['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(_getReportTypeName(report['report_type']), style: TextStyle(fontSize: 12)),
                            SizedBox(height: 2),
                            Text(_formatDate(report['created_at']), style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: _getStatusBadge(report['status']),
                        onTap: () {
                          context.push('/report-detail', extra: report['id']);
                        },
                      ),
                    );
                  },
                ),
            ),
    );
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case 'pending':
        icon = Icons.hourglass_empty;
        color = Colors.amber;
        break;
      case 'processing':
        icon = Icons.update;
        color = Colors.blue;
        break;
      case 'resolved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _getStatusBadge(String status) {
    String text;
    Color color;
    
    switch (status) {
      case 'pending':
        text = 'Chờ xử lý';
        color = Colors.amber;
        break;
      case 'processing':
        text = 'Đang xử lý';
        color = Colors.blue;
        break;
      case 'resolved':
        text = 'Đã giải quyết';
        color = Colors.green;
        break;
      case 'rejected':
        text = 'Từ chối';
        color = Colors.red;
        break;
      default:
        text = status;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
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
