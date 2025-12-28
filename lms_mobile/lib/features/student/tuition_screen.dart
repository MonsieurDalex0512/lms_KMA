import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../auth/auth_provider.dart';

class TuitionScreen extends StatefulWidget {
  const TuitionScreen({super.key});

  @override
  State<TuitionScreen> createState() => _TuitionScreenState();
}

class _TuitionScreenState extends State<TuitionScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _tuitions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTuitions();
  }

  Future<void> _fetchTuitions() async {
    try {
      final response = await _apiClient.client.get('/students/me/tuitions');
      setState(() {
        _tuitions = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Lỗi tải thông tin học phí: $e")),
        );
      }
    }
  }

  String _formatCurrency(int amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return format.format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PARTIAL':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
  
  String _getStatusText(String status) {
     switch (status) {
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'PARTIAL':
        return 'Đóng một phần';
      default:
        return 'Chưa hoàn thành';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu học phí', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tuitions.isEmpty
              ? const Center(child: Text("Không có thông tin học phí"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tuitions.length,
                  itemBuilder: (context, index) {
                    final item = _tuitions[index];
                    final total = item['total_amount'] as int;
                    final paid = item['paid_amount'] as int;
                    final remaining = total - paid;
                    final status = item['status'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                       padding: const EdgeInsets.all(8),
                                       decoration: BoxDecoration(
                                          color: Colors.amber[100],
                                          borderRadius: BorderRadius.circular(8)
                                       ),
                                       child: Icon(Icons.school, color: Colors.amber[800]),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Học kỳ ${item['semester']}",
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getStatusColor(status)),
                                  ),
                                  child: Text(
                                    _getStatusText(status),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildDetailRow("Tổng học phí:", _formatCurrency(total), isBold: true),
                                const SizedBox(height: 12),
                                _buildDetailRow("Đã đóng:", _formatCurrency(paid), color: Colors.green),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                _buildDetailRow("Còn nợ:", _formatCurrency(remaining), color: Colors.red, isBold: true, isLarge: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            color: Colors.grey[700],
            fontWeight: isLarge ? FontWeight.bold : FontWeight.normal
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
