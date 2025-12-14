import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

enum UserRole { student, lecturer, dean, unknown }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  AuthStatus _status = AuthStatus.unknown;
  UserRole _role = UserRole.unknown;
  String? _username;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserRole get role => _role;
  String? get username => _username;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decodedToken = JwtDecoder.decode(token);
      _username = decodedToken['sub'];

      final roleStr = prefs.getString('user_role');
      if (roleStr != null) {
        if (roleStr == 'student') {
          _role = UserRole.student;
        } else if (roleStr == 'lecturer')
          _role = UserRole.lecturer;
        else if (roleStr == 'dean') {
          _status = AuthStatus.unauthenticated;
          await logout();
          notifyListeners();
          return;
        }
      }

      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.client.post(
        '/auth/login',
        data: {'username': username, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final token = response.data['access_token'];
      final roleStr = response.data['role'] as String?;

      if (roleStr == null) {
        await logout();
        _errorMessage =
            'Không xác định được quyền hạn người dùng (Missing role).';
        notifyListeners();
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setString('user_role', roleStr);

      if (roleStr.toLowerCase() == 'dean') {
        await logout();
        _errorMessage = 'Tài khoản Dean không được phép truy cập trên mobile.';
        notifyListeners();
        return false;
      }

      UserRole userRole;
      if (roleStr.toLowerCase() == 'student') {
        userRole = UserRole.student;
      } else if (roleStr.toLowerCase() == 'lecturer') {
        userRole = UserRole.lecturer;
      } else {
        await logout();
        _errorMessage = 'Vai trò người dùng không hợp lệ.';
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      _role = userRole;
      _username = username;
      notifyListeners();
      return true;
    } catch (e) {
      await logout();
      if (e is DioException && e.response?.statusCode == 401) {
        _errorMessage = 'Sai tên đăng nhập hoặc mật khẩu';
      } else {
        _errorMessage = 'Lỗi xác thực: $e';
      }
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_role');
    _status = AuthStatus.unauthenticated;
    _role = UserRole.unknown;
    _username = null;
    notifyListeners();
  }
}
