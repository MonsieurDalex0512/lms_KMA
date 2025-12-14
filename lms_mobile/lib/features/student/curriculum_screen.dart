import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:flutter/services.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _tabs = [
    {
      'title': 'Công nghệ thông tin',
      'icon': Icons.computer,
      'pdfPath': 'assets/pdfs/cntt.pdf',
    },
    {
      'title': 'An toàn thông tin',
      'icon': Icons.security,
      'pdfPath': null, // Tạm thời chưa có
    },
    {
      'title': 'Điện tử viễn thông',
      'icon': Icons.memory,
      'pdfPath': 'assets/pdfs/dtvt.pdf',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chương trình học'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[800],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
              tabs: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = index == _selectedIndex;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[800],
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tab['title'] as String,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          final pdfPath = tab['pdfPath'] as String?;
          
          if (pdfPath == null) {
            // Tab chưa có PDF
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có tài liệu',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tài liệu sẽ được cập nhật sau',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Hiển thị PDF
          return _buildPDFViewer(pdfPath);
        }).toList(),
      ),
    );
  }

  Widget _buildPDFViewer(String pdfPath) {
    return FutureBuilder<Uint8List>(
      future: _loadPDFAsset(pdfPath),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không tìm thấy tài liệu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Vui lòng đảm bảo file PDF đã được thêm vào thư mục assets/pdfs/\n\nLỗi: ${snapshot.error ?? "File không tồn tại"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return PdfView(
          controller: PdfController(
            document: PdfDocument.openData(snapshot.data!),
          ),
        );
      },
    );
  }

  Future<Uint8List> _loadPDFAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List();
  }
}
