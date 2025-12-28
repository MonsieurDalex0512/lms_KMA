import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/api_client.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  String _selectedType = 'all';
  bool _isLoading = false;
  List<dynamic> _courses = [];
  List<dynamic> _lecturers = [];
  List<dynamic> _classes = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _courses = [];
        _lecturers = [];
        _classes = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.client.get(
        '/students/search',
        queryParameters: {'q': query, 'type': _selectedType},
      );

      if (mounted) {
        setState(() {
          _courses = response.data['courses'] ?? [];
          _lecturers = response.data['lecturers'] ?? [];
          _classes = response.data['classes'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tìm kiếm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm học phần, giảng viên, lớp học...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Học phần', 'course'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Giảng viên', 'lecturer'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Lớp học', 'class'),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.isEmpty
                    ? _buildEmptyState('Nhập từ khóa để tìm kiếm', Icons.search)
                    : _courses.isEmpty && _lecturers.isEmpty && _classes.isEmpty
                        ? _buildEmptyState('Không tìm thấy kết quả', Icons.search_off)
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              if (_courses.isNotEmpty) ...[
                                _buildSectionHeader('Học phần', _courses.length),
                                ..._courses.map((course) => _buildCourseCard(course)),
                                const SizedBox(height: 16),
                              ],
                              if (_lecturers.isNotEmpty) ...[
                                _buildSectionHeader('Giảng viên', _lecturers.length),
                                ..._lecturers.map((lecturer) => _buildLecturerCard(lecturer)),
                                const SizedBox(height: 16),
                              ],
                              if (_classes.isNotEmpty) ...[
                                _buildSectionHeader('Lớp học', _classes.length),
                                ..._classes.map((cls) => _buildClassCard(cls)),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedType = value);
        if (_searchController.text.isNotEmpty) {
          _performSearch(_searchController.text);
        }
      },
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.book, color: Colors.blue.shade700),
        ),
        title: Text(
          course['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${course['code']} • ${course['credits']} tín chỉ'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
        },
      ),
    );
  }

  Widget _buildLecturerCard(dynamic lecturer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(Icons.person, color: Colors.green.shade700),
        ),
        title: Text(
          lecturer['full_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lecturer['email'] ?? ''),
            if (lecturer['department_name'] != null)
              Text(
                lecturer['department_name'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        isThreeLine: lecturer['department_name'] != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to lecturer detail
        },
      ),
    );
  }

  Widget _buildClassCard(dynamic cls) {
    final dayOfWeek = cls['day_of_week'] != null ? 'Thứ ${cls['day_of_week'] + 1}' : '';
    final time = cls['start_period'] != null && cls['end_period'] != null
        ? 'Tiết ${cls['start_period']}-${cls['end_period']}'
        : '';
    final room = cls['room'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.class_, color: Colors.purple.shade700),
        ),
        title: Text(
          cls['code'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cls['course_name'] ?? ''),
            const SizedBox(height: 4),
            Row(
              children: [
                if (cls['lecturer_name'] != null) ...[
                  Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    cls['lecturer_name'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            if (dayOfWeek.isNotEmpty || time.isNotEmpty || room.isNotEmpty)
              Text(
                '$dayOfWeek $time ${room.isNotEmpty ? '- $room' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cls['enrolled_count']}/${cls['max_students']}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Text('Sinh viên', style: TextStyle(fontSize: 10)),
          ],
        ),
        onTap: () {
          // TODO: Navigate to class detail
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
