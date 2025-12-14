import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class StudentProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _classes = [];
  List<dynamic> _grades = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get classes => _classes;
  List<dynamic> get grades => _grades;
  List<dynamic> _academicResults = [];
  List<dynamic> get academicResults => _academicResults;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/students/my-classes');
      _classes = response.data;
    } catch (e) {
      _error = 'Failed to load classes';
      print('Error fetching classes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrades() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/students/my-grades');
      _grades = response.data;
    } catch (e) {
      _error = 'Failed to load grades';
      print('Error fetching grades: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAcademicResults() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/students/my-results');
      _academicResults = response.data;
    } catch (e) {
      _error = 'Failed to load academic results';
      print('Error fetching academic results: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchSemesterDetail(String semesterCode) async {
    try {
      final response = await _apiClient.client.get('/students/my-results/$semesterCode');
      return response.data;
    } catch (e) {
      print('Error fetching semester detail: $e');
      return null;
    }
  }

  List<dynamic> _timetable = [];
  List<dynamic> get timetable => _timetable;

  Future<void> fetchTimetable() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/students/my-timetable');
      _timetable = response.data;
    } catch (e) {
      _error = 'Failed to load timetable';
      print('Error fetching timetable: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchAcademicSummary() async {
    try {
      final response = await _apiClient.client.get('/students/academic-summary');
      return response.data;
    } catch (e) {
      print('Error fetching academic summary: $e');
      return null;
    }
  }

  List<dynamic> _projects = [];
  List<dynamic> get projects => _projects;

  Future<void> fetchProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/students/my-projects');
      _projects = response.data;
    } catch (e) {
      _error = 'Failed to load projects';
      print('Error fetching projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<dynamic> _reports = [];
  List<dynamic> get reports => _reports;

  Future<void> fetchMyReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/reports/my-reports');
      _reports = response.data;
    } catch (e) {
      _error = 'Failed to load reports';
      print('Error fetching reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createReport(String title, String description, String type) async {
    final response = await _apiClient.client.post(
      '/reports',
      data: {
        'title': title,
        'description': description,
        'report_type': type,
      },
      options: Options(contentType: Headers.jsonContentType),
    );
    return response.data;
  }

  Future<Map<String, dynamic>?> fetchReportDetail(int reportId) async {
    try {
      final response = await _apiClient.client.get('/reports/$reportId');
      return response.data;
    } catch (e) {
      print('Error fetching report detail: $e');
      return null;
    }
  }
}
