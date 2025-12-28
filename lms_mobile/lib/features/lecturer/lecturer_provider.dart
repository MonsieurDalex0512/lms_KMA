import 'package:flutter/foundation.dart';
import '../../core/api_client.dart';

class LecturerProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _classes = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchClasses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.get('/lecturers/my-classes');
      _classes = response.data;
    } catch (e) {
      _error = 'Failed to load classes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
