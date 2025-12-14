# PHÂN TÍCH CHI TIẾT KIẾN TRÚC MOBILE APP LMS

## 📋 MỤC LỤC
1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Cấu trúc dự án](#2-cấu-trúc-dự-án)
3. [State Management](#3-state-management)
4. [API Client & HTTP](#4-api-client--http)
5. [Routing & Navigation](#5-routing--navigation)
6. [Luồng hoạt động các chức năng](#6-luồng-hoạt-động-các-chức-năng)
7. [Screens & Widgets](#7-screens--widgets)
8. [Data Storage](#8-data-storage)
9. [Data Flow](#9-data-flow)
10. [Best Practices](#10-best-practices)

---

## 1. TỔNG QUAN HỆ THỐNG

### 1.1. Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────┐
│              Mobile Device (Android/iOS)                │
└────────────────────┬──────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Flutter Application (Mobile App)            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Screens   │  │  Providers   │  │  API Client  │ │
│  │             │  │              │  │              │ │
│  │ - Login     │  │ - AuthProvider│  │ - Dio        │ │
│  │ - Dashboard │  │ - Student     │  │ - Interceptors│ │
│  │ - Timetable │  │   Provider    │  │              │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                    │
│  │   Storage    │  │   Router     │                    │
│  │              │  │              │                    │
│  │SharedPrefs   │  │ GoRouter     │                    │
│  └──────────────┘  └──────────────┘                    │
└────────────────────┬──────────────────────────────────────┘
                     │
                     │ HTTP Requests (Dio)
                     │ Authorization: Bearer <token>
                     ▼
┌─────────────────────────────────────────────────────────┐
│              Backend API (FastAPI)                        │
│              http://10.0.2.2:8000 (Android Emulator)    │
│              http://localhost:8000 (iOS Simulator)       │
└─────────────────────────────────────────────────────────┘
```

### 1.2. Công nghệ sử dụng

**Core Framework:**
- **Flutter**: SDK ^3.9.2 (Cross-platform UI framework)
- **Dart**: Language (Object-oriented, compiled)

**State Management:**
- **provider**: ^6.1.5+1 (State management)

**HTTP Client:**
- **dio**: ^5.9.0 (HTTP requests)

**Routing:**
- **go_router**: ^17.0.0 (Declarative routing)

**Storage:**
- **shared_preferences**: ^2.5.3 (Local key-value storage)

**Authentication:**
- **jwt_decoder**: ^2.0.1 (JWT token decoding)

**UI Libraries:**
- **google_fonts**: ^6.3.3 (Custom fonts)
- **table_calendar**: ^3.2.0 (Calendar widget)
- **fl_chart**: ^1.1.1 (Charts)
- **webview_flutter**: ^4.10.0 (WebView)
- **pdfx**: ^2.0.0 (PDF viewer)

**Utilities:**
- **intl**: ^0.20.2 (Internationalization)

---

## 2. CẤU TRÚC DỰ ÁN

### 2.1. Cấu trúc thư mục

```
lms_mobile/
├── lib/
│   ├── main.dart                    # Entry point
│   │
│   ├── core/                        # Core utilities
│   │   └── api_client.dart          # Dio instance & interceptors
│   │
│   ├── features/                    # Feature modules
│   │   ├── auth/                    # Authentication
│   │   │   ├── auth_provider.dart   # Auth state management
│   │   │   └── login_screen.dart     # Login screen
│   │   │
│   │   ├── student/                 # Student features
│   │   │   ├── student_provider.dart        # Student state
│   │   │   ├── student_dashboard.dart        # Main dashboard
│   │   │   ├── student_home_screen.dart       # Home screen
│   │   │   ├── timetable_screen.dart         # Timetable
│   │   │   ├── student_classes_screen.dart   # Classes list
│   │   │   ├── academic_results_screen.dart  # Academic results
│   │   │   ├── semester_detail_screen.dart    # Semester details
│   │   │   ├── gpa_calculator_screen.dart     # GPA calculator
│   │   │   ├── utilities_screen.dart          # Utilities menu
│   │   │   ├── curriculum_screen.dart          # Curriculum PDFs
│   │   │   ├── notifications_screen.dart      # Notifications
│   │   │   ├── reports_screen.dart             # Reports list
│   │   │   ├── create_report_screen.dart      # Create report
│   │   │   ├── report_detail_screen.dart      # Report details
│   │   │   ├── projects_screen.dart            # Projects
│   │   │   ├── tuition_screen.dart             # Tuition
│   │   │   └── search_screen.dart              # Search
│   │   │
│   │   └── lecturer/                # Lecturer features
│   │       ├── lecturer_provider.dart
│   │       ├── lecturer_dashboard.dart
│   │       └── lecturer_class_detail_screen.dart
│   │
│   └── shared/                      # Shared components
│       └── profile_screen.dart      # Profile screen
│
├── assets/                          # Assets
│   ├── images/
│   │   └── logo.png                 # App logo
│   └── pdfs/                        # PDF files
│       ├── cntt.pdf                 # CNTT curriculum
│       └── dtvt.pdf                 # DTVT curriculum
│
├── pubspec.yaml                     # Dependencies
└── analysis_options.yaml           # Linter config
```

### 2.2. Entry Point: main.dart

**File:** `lms_mobile/lib/main.dart`

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LecturerProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
```

**Chức năng:**
- Khởi tạo MultiProvider với 3 providers (Auth, Lecturer, Student)
- Wrap toàn bộ app với providers để có thể access từ bất kỳ widget nào
- Khởi tạo MyApp với GoRouter

**Provider Setup:**
- **AuthProvider**: Quản lý authentication state
- **LecturerProvider**: Quản lý state cho lecturer
- **StudentProvider**: Quản lý state cho student

---

## 3. STATE MANAGEMENT

### 3.1. Provider Pattern

**Package:** `provider: ^6.1.5+1`

**Cách hoạt động:**
- Providers wrap app ở top level
- Widgets có thể `watch` hoặc `read` providers
- Khi provider state thay đổi, widgets tự động rebuild

### 3.2. AuthProvider

**File:** `lms_mobile/lib/features/auth/auth_provider.dart`

#### 3.2.1. State Variables

```dart
class AuthProvider with ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserRole _role = UserRole.unknown;
  String? _username;
  String? _errorMessage;
}
```

**Enums:**
```dart
enum AuthStatus { unknown, authenticated, unauthenticated }
enum UserRole { student, lecturer, dean, unknown }
```

#### 3.2.2. Initialization

```dart
AuthProvider() {
  _checkAuth();  // Check token khi khởi tạo
}

Future<void> _checkAuth() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');

  if (token != null && !JwtDecoder.isExpired(token)) {
    // Token hợp lệ
    final decodedToken = JwtDecoder.decode(token);
    _username = decodedToken['sub'];
    
    final roleStr = prefs.getString('user_role');
    if (roleStr == 'student') {
      _role = UserRole.student;
    } else if (roleStr == 'lecturer') {
      _role = UserRole.lecturer;
    }
    
    _status = AuthStatus.authenticated;
  } else {
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
}
```

**Chức năng:**
- Kiểm tra token trong SharedPreferences khi app start
- Decode JWT để lấy username
- Set role từ SharedPreferences
- Set status = authenticated nếu token hợp lệ

#### 3.2.3. Login Function

```dart
Future<bool> login(String username, String password) async {
  _errorMessage = null;
  notifyListeners();

  try {
    // 1. POST /auth/login
    final response = await _apiClient.client.post(
      '/auth/login',
      data: {'username': username, 'password': password},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    // 2. Lấy token và role từ response
    final token = response.data['access_token'];
    final roleStr = response.data['role'] as String?;

    // 3. Lưu vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_role', roleStr);

    // 4. Kiểm tra role (không cho phép dean)
    if (roleStr.toLowerCase() == 'dean') {
      await logout();
      _errorMessage = 'Tài khoản Dean không được phép truy cập trên mobile.';
      notifyListeners();
      return false;
    }

    // 5. Set state
    _status = AuthStatus.authenticated;
    _role = userRole;
    _username = username;
    notifyListeners();
    return true;
  } catch (e) {
    // Error handling
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
```

**Luồng xử lý:**
1. POST /auth/login với username/password
2. Nhận token và role từ backend
3. Lưu token và role vào SharedPreferences
4. Kiểm tra role (không cho phép dean)
5. Update state và notify listeners
6. Router tự động redirect dựa trên role

#### 3.2.4. Logout Function

```dart
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('access_token');
  await prefs.remove('user_role');
  _status = AuthStatus.unauthenticated;
  _role = UserRole.unknown;
  _username = null;
  notifyListeners();
}
```

**Chức năng:**
- Xóa token và role khỏi SharedPreferences
- Reset state về unauthenticated
- Notify listeners để UI update

**Lưu trữ:**
- **SharedPreferences**: `access_token`, `user_role`
- **Provider State**: In-memory state (_status, _role, _username)

### 3.3. StudentProvider

**File:** `lms_mobile/lib/features/student/student_provider.dart`

#### 3.3.1. State Variables

```dart
class StudentProvider with ChangeNotifier {
  List<dynamic> _classes = [];
  List<dynamic> _grades = [];
  List<dynamic> _academicResults = [];
  List<dynamic> _timetable = [];
  List<dynamic> _projects = [];
  List<dynamic> _reports = [];
  bool _isLoading = false;
  String? _error;
}
```

#### 3.3.2. Fetch Functions

**Fetch Classes:**
```dart
Future<void> fetchClasses() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiClient.client.get('/students/my-classes');
    if (response.data is List) {
      _classes = response.data;
    } else {
      _classes = [];
    }
  } catch (e) {
    _error = 'Failed to load classes';
    _classes = [];
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Fetch Timetable:**
```dart
Future<void> fetchTimetable() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _apiClient.client.get('/students/my-timetable');
    _timetable = response.data;
  } catch (e) {
    _error = 'Failed to load timetable';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

**Fetch Academic Summary:**
```dart
Future<Map<String, dynamic>?> fetchAcademicSummary() async {
  try {
    final response = await _apiClient.client.get('/students/academic-summary');
    return response.data;
  } catch (e) {
    print('Error fetching academic summary: $e');
    return null;
  }
}
```

**Pattern:**
1. Set `_isLoading = true` và `_error = null`
2. Call `notifyListeners()` để UI hiển thị loading
3. Gọi API
4. Update state với response data
5. Set `_isLoading = false` và `notifyListeners()`

**Lưu trữ:**
- **Provider State**: In-memory state (classes, grades, timetable...)
- **Backend Database**: Persistent storage (PostgreSQL)

---

## 4. API CLIENT & HTTP

### 4.1. ApiClient Class

**File:** `lms_mobile/lib/core/api_client.dart`

#### 4.1.1. Dio Configuration

```dart
class ApiClient {
  static const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // iOS simulator
  
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  );
}
```

**Cấu hình:**
- **baseUrl**: Backend API URL
  - `10.0.2.2:8000`: Android emulator (maps to localhost)
  - `localhost:8000`: iOS simulator
- **Timeouts**: 10 seconds cho connect và receive
- **Headers**: Default headers cho mọi request

#### 4.1.2. Request Interceptor

```dart
ApiClient() {
  _dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 1. Lấy token từ SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');

        // 2. Thêm Authorization header nếu có token
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // 3. Thêm ngrok header
        options.headers['ngrok-skip-browser-warning'] = 'true';

        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ),
  );
}
```

**Chức năng:**
- Tự động thêm `Authorization: Bearer <token>` vào mọi request
- Token được lấy từ SharedPreferences mỗi request
- Xử lý lỗi (có thể thêm auto-logout nếu 401)

**HTTP Request Headers:**
```
GET /students/my-classes HTTP/1.1
Host: 10.0.2.2:8000
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/x-www-form-urlencoded
Accept: application/json
ngrok-skip-browser-warning: true
```

#### 4.1.3. Sử dụng API Client

**Ví dụ: GET request**
```dart
final apiClient = ApiClient();
final response = await apiClient.client.get('/students/my-classes');
final classes = response.data;
```

**Ví dụ: POST request**
```dart
final response = await apiClient.client.post(
  '/auth/login',
  data: {'username': username, 'password': password},
  options: Options(contentType: Headers.formUrlEncodedContentType),
);
```

---

## 5. ROUTING & NAVIGATION

### 5.1. GoRouter Setup

**File:** `lms_mobile/lib/main.dart`

#### 5.1.1. Router Configuration

```dart
final router = GoRouter(
  refreshListenable: authProvider,  // Listen to auth changes
  redirect: (context, state) {
    final loggedIn = authProvider.status == AuthStatus.authenticated;
    final isLoggingIn = state.uri.toString() == '/login';

    // Redirect to login nếu chưa authenticated
    if (!loggedIn) return '/login';
    
    // Redirect to dashboard dựa trên role
    if (loggedIn && (isLoggingIn || state.uri.toString() == '/')) {
      if (authProvider.role == UserRole.lecturer) return '/lecturer';
      if (authProvider.role == UserRole.student) return '/student';
    }
    
    return null;  // No redirect
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/student', builder: (context, state) => const StudentDashboard()),
    GoRoute(path: '/lecturer', builder: (context, state) => const LecturerDashboard()),
    // ... more routes
  ],
);
```

**Chức năng:**
- **refreshListenable**: Listen to AuthProvider changes để auto-redirect
- **redirect**: Logic redirect dựa trên authentication status và role
- **routes**: Định nghĩa các routes

#### 5.1.2. Route Structure

```
/ (root)
├── /login                    # Login screen
├── /student                  # Student dashboard
│   └── (nested navigation via bottom nav)
├── /lecturer                 # Lecturer dashboard
├── /reports                  # Reports list
├── /create-report            # Create report
├── /report-detail            # Report details (with reportId)
├── /notifications            # Notifications
└── /profile                  # Profile
```

#### 5.1.3. Navigation Methods

**Sử dụng GoRouter:**
```dart
// Navigate programmatically
context.go('/student');
context.push('/reports');
context.pop();  // Go back
```

**Sử dụng Navigator (Material):**
```dart
// Navigate to new screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const TimetableScreen()),
);

// Navigate back
Navigator.pop(context);
```

**Passing Data:**
```dart
// Via route extra
GoRoute(
  path: '/report-detail',
  builder: (context, state) {
    final reportId = state.extra as int;
    return ReportDetailScreen(reportId: reportId);
  },
);

// Navigate with extra
context.push('/report-detail', extra: reportId);
```

---

## 6. LUỒNG HOẠT ĐỘNG CÁC CHỨC NĂNG

### 6.1. CHỨC NĂNG: Đăng nhập

#### 6.1.1. Luồng xử lý

```
1. User mở app
   ↓
2. GoRouter check auth status
   ↓
3. Nếu chưa login → Redirect to /login
   ↓
4. User nhập username/password
   ↓
5. Click "Đăng Nhập"
   ↓
6. LoginScreen._submit() được gọi
   ↓
7. authProvider.login(username, password)
   ↓
8. POST /auth/login với form-urlencoded
   ↓
9. Backend verify và trả về { access_token, role }
   ↓
10. Lưu token và role vào SharedPreferences
   ↓
11. Update AuthProvider state
   ↓
12. notifyListeners() → GoRouter detect change
   ↓
13. GoRouter redirect dựa trên role:
    - student → /student
    - lecturer → /lecturer
   ↓
14. Render Dashboard
```

#### 6.1.2. Vị trí code

**File:** `lms_mobile/lib/features/auth/login_screen.dart`

**Component State:**
```dart
final _formKey = GlobalKey<FormState>();
final _usernameController = TextEditingController();
final _passwordController = TextEditingController();
bool _isLoading = false;
```

**Submit Handler:**
```dart
void _submit() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    final success = await context.read<AuthProvider>().login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    // GoRouter sẽ tự động redirect nếu login thành công
  }
}
```

**HTTP Request:**
```
POST /auth/login HTTP/1.1
Host: 10.0.2.2:8000
Content-Type: application/x-www-form-urlencoded

username=john&password=secret123
```

**HTTP Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "role": "student"
}
```

**Lưu trữ:**
- **SharedPreferences.access_token**: JWT token
- **SharedPreferences.user_role**: "student" hoặc "lecturer"
- **AuthProvider state**: In-memory state (_status, _role, _username)

---

### 6.2. CHỨC NĂNG: Xem thời khóa biểu

#### 6.2.1. Luồng xử lý

```
1. User vào "Thời khóa biểu" từ home screen
   ↓
2. Navigator.push() → TimetableScreen
   ↓
3. initState() → _fetchTimetable()
   ↓
4. studentProvider.fetchTimetable()
   ↓
5. GET /students/my-timetable
   ↓
6. Backend trả về danh sách buổi học
   ↓
7. studentProvider._timetable = response.data
   ↓
8. notifyListeners() → TimetableScreen rebuild
   ↓
9. Parse dates và group events by date
   ↓
10. Render TableCalendar với events
   ↓
11. User chọn ngày → Hiển thị danh sách buổi học trong ngày
```

#### 6.2.2. Vị trí code

**File:** `lms_mobile/lib/features/student/timetable_screen.dart`

**Component State:**
```dart
CalendarFormat _calendarFormat = CalendarFormat.month;
DateTime _focusedDay = DateTime.now();
DateTime? _selectedDay;
Map<DateTime, List<dynamic>> _events = {};
```

**Fetch Timetable:**
```dart
Future<void> _fetchTimetable() async {
  final studentProvider = Provider.of<StudentProvider>(context, listen: false);
  await studentProvider.fetchTimetable();
  
  // Parse và group events by date
  final events = <DateTime, List<dynamic>>{};
  for (var item in studentProvider.timetable) {
    if (item['date'] != null) {
      final dateStr = item['date'] as String;
      final date = DateTime.parse(dateStr);
      final normalizedDate = DateTime.utc(date.year, date.month, date.day);
      
      if (events[normalizedDate] == null) {
        events[normalizedDate] = [];
      }
      events[normalizedDate]!.add(item);
    }
  }
  
  setState(() {
    _events = events;
  });
}
```

**Render Calendar:**
```dart
TableCalendar(
  firstDay: DateTime.utc(2020, 1, 1),
  lastDay: DateTime.utc(2030, 12, 31),
  focusedDay: _focusedDay,
  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
  eventLoader: _getEventsForDay,  // Load events cho mỗi ngày
  calendarFormat: _calendarFormat,
  onDaySelected: (selectedDay, focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    // Show day details
  },
)
```

**HTTP Request:**
```
GET /students/my-timetable HTTP/1.1
Host: 10.0.2.2:8000
Authorization: Bearer <token>

Response:
[
  {
    "id": 1,
    "date": "2024-01-15",
    "start_period": 1,
    "end_period": 3,
    "room": "A101",
    "course_name": "Giải tích 1",
    "class_code": "CS10120241",
    "lecturer_name": "Nguyễn Văn A"
  },
  ...
]
```

**Lưu trữ:**
- **StudentProvider._timetable**: In-memory state
- **TimetableScreen._events**: Parsed và grouped by date
- **Backend Database**: Bảng `timetables` trong PostgreSQL

---

### 6.3. CHỨC NĂNG: Xem lớp học

#### 6.3.1. Luồng xử lý

```
1. User vào "Lớp sinh viên" từ home screen
   ↓
2. Navigator.push() → StudentClassesScreen
   ↓
3. initState() → _loadData()
   ↓
4. Parallel requests:
   - studentProvider.fetchClasses()
   - studentProvider.fetchAcademicSummary()
   ↓
5. GET /students/my-classes
   GET /students/academic-summary
   ↓
6. Parse semester results để lấy danh sách semesters
   ↓
7. Set current semester (semester mới nhất)
   ↓
8. Render TabBar với 2 tabs:
   - "Lớp học kỳ này" (current semester)
   - "Lớp đã học" (past semesters)
   ↓
9. Filter classes theo semester
   ↓
10. Render danh sách lớp học
   ↓
11. User click vào lớp → _showClassDetailDialog()
   ↓
12. GET /students/classes/{classId}/students
   ↓
13. Hiển thị dialog với thông tin lớp và danh sách sinh viên
```

#### 6.3.2. Vị trí code

**File:** `lms_mobile/lib/features/student/student_classes_screen.dart`

**Component State:**
```dart
late TabController _tabController;
String? _currentSemester;
List<dynamic> _semesters = [];
String? _selectedPastSemester;
```

**Load Data:**
```dart
Future<void> _loadData() async {
  final studentProvider = context.read<StudentProvider>();
  
  // Fetch classes
  await studentProvider.fetchClasses();
  
  // Fetch academic summary để lấy semesters
  final summary = await studentProvider.fetchAcademicSummary();
  
  if (summary != null && summary['semester_results'] != null) {
    final semesterResults = summary['semester_results'] as List<dynamic>;
    if (semesterResults.isNotEmpty) {
      setState(() {
        _semesters = semesterResults;
        _currentSemester = semesterResults.last['semester_code'];
        // Set default past semester
        if (semesterResults.length > 1) {
          _selectedPastSemester = semesterResults[semesterResults.length - 2]['semester_code'];
        }
      });
    }
  }
}
```

**Filter Classes:**
```dart
List<dynamic> _getCurrentSemesterClasses(List<dynamic> classes) {
  if (_currentSemester == null) {
    return classes;  // Return all nếu chưa có current semester
  }
  return classes.where((cls) => cls['semester'] == _currentSemester).toList();
}

List<dynamic> _getPastSemesterClasses(List<dynamic> classes) {
  if (_selectedPastSemester == null) return [];
  return classes.where((cls) => cls['semester'] == _selectedPastSemester).toList();
}
```

**Show Class Detail:**
```dart
Future<void> _showClassDetailDialog(BuildContext context, Map<String, dynamic> cls) async {
  showDialog(
    context: context,
    builder: (context) => _ClassDetailDialog(
      classInfo: cls,
      apiClient: _apiClient,
    ),
  );
}
```

**Class Detail Dialog:**
```dart
class _ClassDetailDialog extends StatefulWidget {
  final Map<String, dynamic> classInfo;
  final ApiClient apiClient;
  
  @override
  State<_ClassDetailDialog> createState() => _ClassDetailDialogState();
}

class _ClassDetailDialogState extends State<_ClassDetailDialog> {
  List<dynamic>? _students;
  bool _isLoadingStudents = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await widget.apiClient.client.get(
        '/students/classes/${widget.classInfo['id']}/students'
      );
      
      if (mounted) {
        setState(() {
          _students = response.data is List ? response.data : [];
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _students = [];
          _isLoadingStudents = false;
        });
      }
    }
  }
}
```

**HTTP Requests:**
```
GET /students/my-classes HTTP/1.1
Authorization: Bearer <token>

Response:
[
  {
    "id": 1,
    "code": "CS10120241",
    "course": {
      "name": "Giải tích 1",
      "credits": 3
    },
    "lecturer": {
      "user": {
        "full_name": "Nguyễn Văn A"
      }
    },
    "semester": "20241",
    "room": "A101"
  },
  ...
]

GET /students/classes/1/students HTTP/1.1
Authorization: Bearer <token>

Response:
[
  {
    "id": 10,
    "username": "student1",
    "full_name": "Nguyễn Văn B",
    "student_code": "SV001"
  },
  ...
]
```

**Lưu trữ:**
- **StudentProvider._classes**: In-memory state
- **StudentClassesScreen state**: Filtered classes, semesters
- **Backend Database**: Bảng `classes`, `enrollments`, `users`

---

### 6.4. CHỨC NĂNG: Xem kết quả học tập

#### 6.4.1. Luồng xử lý

```
1. User vào "Kết quả học tập" từ home screen
   ↓
2. Navigator.push() → AcademicResultsScreen
   ↓
3. initState() → _loadSummary()
   ↓
4. studentProvider.fetchAcademicSummary()
   ↓
5. GET /students/academic-summary
   ↓
6. Backend trả về:
   - cumulative_cpa
   - total_registered_credits
   - total_completed_credits
   - total_failed_credits
   - semester_results (list of semesters)
   ↓
7. Render:
   - CPA card với thống kê
   - Bar chart (GPA từng học kỳ)
   - List of semesters
   ↓
8. User click vào semester → Navigator.push() → SemesterDetailScreen
   ↓
9. GET /students/my-results/{semesterCode}
   ↓
10. Render chi tiết điểm từng môn trong học kỳ
```

#### 6.4.2. Vị trí code

**File:** `lms_mobile/lib/features/student/academic_results_screen.dart`

**Component State:**
```dart
Map<String, dynamic>? _summary;
bool _isLoading = true;
```

**Load Summary:**
```dart
Future<void> _loadSummary() async {
  final data = await context.read<StudentProvider>().fetchAcademicSummary();
  if (mounted) {
    setState(() {
      _summary = data;
      _isLoading = false;
    });
  }
}
```

**Navigate to Semester Detail:**
```dart
ListTile(
  title: Text(semester['semester_name']),
  subtitle: Text('GPA: ${semester['gpa'].toStringAsFixed(2)}'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SemesterDetailScreen(
          semesterCode: semester['semester_code'],
          semesterName: semester['semester_name'],
        ),
      ),
    );
  },
)
```

**HTTP Requests:**
```
GET /students/academic-summary HTTP/1.1
Authorization: Bearer <token>

Response:
{
  "cumulative_cpa": 3.5,
  "total_registered_credits": 45,
  "total_completed_credits": 40,
  "total_failed_credits": 5,
  "semester_results": [
    {
      "semester_code": "20241",
      "semester_name": "Học kỳ 1 năm học 2024-2025",
      "gpa": 3.2,
      "total_credits": 15,
      "completed_credits": 12,
      "failed_credits": 3
    },
    ...
  ]
}

GET /students/my-results/20241 HTTP/1.1
Authorization: Bearer <token>

Response:
{
  "semester_code": "20241",
  "gpa": 3.2,
  "cpa": 3.2,
  "total_credits": 15,
  "completed_credits": 12,
  "failed_credits": 3,
  "courses": [
    {
      "course_code": "CS101",
      "course_name": "Giải tích 1",
      "credits": 3,
      "score_10": 7.5,
      "score_4": 3.0,
      "letter_grade": "B"
    },
    ...
  ]
}
```

**Lưu trữ:**
- **AcademicResultsScreen._summary**: In-memory state
- **Backend Database**: Bảng `academic_results`, `cumulative_results`

---

### 6.5. CHỨC NĂNG: Tính GPA mong đợi

#### 6.5.1. Luồng xử lý

```
1. User vào "Tiện ích" → "Tính chỉ số GPA"
   ↓
2. Navigator.push() → GPACalculatorScreen
   ↓
3. initState() → _loadStudentInfo()
   ↓
4. Parallel requests:
   - GET /students/me (lấy department_name)
   - GET /students/academic-summary (lấy completed_credits, currentGPA)
   ↓
5. Render:
   - Info card (department, total credits, completed credits, current GPA)
   - "Thang điểm" button
   - Input field (target GPA)
   - "Tính toán" button
   ↓
6. User click "Thang điểm" → Show grade scale dialog
   ↓
7. User nhập target GPA và click "Tính toán"
   ↓
8. Calculate required GPA:
   requiredGPA = (targetGPA * totalCredits - currentGPA * completedCredits) / remainingCredits
   ↓
9. Validate:
   - Nếu requiredGPA > 4.0 → Show error (không thể đạt được)
   - Nếu requiredGPA < 0 → Show success (đã đạt hoặc vượt)
   - Nếu hợp lệ → Show result dialog với required GPA
```

#### 6.5.2. Vị trí code

**File:** `lms_mobile/lib/features/student/gpa_calculator_screen.dart`

**Component State:**
```dart
String? _departmentName;
int _totalCredits = 130;  // Fixed
int _completedCredits = 0;
double _currentGPA = 0.0;
bool _isLoading = true;
final TextEditingController _targetGPAController = TextEditingController();
```

**Load Student Info:**
```dart
Future<void> _loadStudentInfo() async {
  try {
    // Get department name
    final response = await _apiClient.client.get('/students/me');
    if (response.data != null) {
      setState(() {
        _departmentName = response.data['department_name'] ?? 'Khoa/Viện';
      });
    }

    // Get academic summary
    final summaryResponse = await _apiClient.client.get('/students/academic-summary');
    if (summaryResponse.data != null) {
      setState(() {
        _completedCredits = summaryResponse.data['total_completed_credits'] ?? 0;
        _currentGPA = summaryResponse.data['cumulative_cpa'] ?? 0.0;
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
  }
}
```

**Calculate Target GPA:**
```dart
void _calculateTargetGPA() {
  final targetGPA = double.tryParse(_targetGPAController.text);
  if (targetGPA == null || targetGPA < 0 || targetGPA > 4.0) {
    _showErrorDialog('Vui lòng nhập GPA hợp lệ (0.0 - 4.0)');
    return;
  }

  if (_remainingCredits <= 0) {
    _showErrorDialog('Bạn đã hoàn thành đủ số tín chỉ yêu cầu!');
    return;
  }

  // Calculate required GPA
  final requiredGPA = (_totalCredits * targetGPA - _completedCredits * _currentGPA) / _remainingCredits;

  if (requiredGPA > 4.0) {
    _showErrorDialog('Không thể đạt được GPA ${targetGPA.toStringAsFixed(2)}!');
    return;
  }

  if (requiredGPA < 0) {
    _showErrorDialog('Bạn đã đạt hoặc vượt mức GPA mong đợi!');
    return;
  }

  // Show result
  _showResultDialog(requiredGPA, targetGPA);
}
```

**Công thức:**
```
requiredGPA = (targetGPA × totalCredits - currentGPA × completedCredits) / remainingCredits

Ví dụ:
- totalCredits = 130
- completedCredits = 60
- currentGPA = 3.0
- targetGPA = 3.5
- remainingCredits = 70

requiredGPA = (3.5 × 130 - 3.0 × 60) / 70
            = (455 - 180) / 70
            = 275 / 70
            = 3.93
```

**Lưu trữ:**
- **Component State**: In-memory state (department, credits, GPA)
- **Backend Database**: Data được query từ `/students/me` và `/students/academic-summary`

---

## 7. SCREENS & WIDGETS

### 7.1. Student Dashboard

**File:** `lms_mobile/lib/features/student/student_dashboard.dart`

**Chức năng:**
- Bottom navigation với 3 tabs:
  - Trang chủ (StudentHomeScreen)
  - Tìm kiếm (SearchScreen)
  - Cá nhân (ProfileScreen)
- Custom AppBar cho home screen (logo, title, logout)
- IndexedStack để maintain state của các screens

**State:**
```dart
int _currentIndex = 0;
final List<Widget> _screens = [
  const StudentHomeScreen(),
  const SearchScreen(),
  const ProfileScreen(),
];
```

### 7.2. Student Home Screen

**File:** `lms_mobile/lib/features/student/student_home_screen.dart`

**Chức năng:**
- Welcome card với student name
- Grid menu với các chức năng:
  - Thời khóa biểu
  - Kết quả học tập
  - Đồ án
  - Thông báo
  - Lớp sinh viên
  - Học phí
  - Tiện ích
- Pull-to-refresh

**Menu Items:**
```dart
_buildMenuItem(context, "Thời khóa biểu", Icons.calendar_today, Colors.orange, () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableScreen()));
}),
```

### 7.3. Screens Summary

| Screen | File | Chức năng | API Endpoints |
|--------|------|-----------|---------------|
| Login | `auth/login_screen.dart` | Đăng nhập | `POST /auth/login` |
| Student Dashboard | `student/student_dashboard.dart` | Main dashboard | - |
| Student Home | `student/student_home_screen.dart` | Home menu | `GET /students/me` |
| Timetable | `student/timetable_screen.dart` | Thời khóa biểu | `GET /students/my-timetable` |
| Student Classes | `student/student_classes_screen.dart` | Danh sách lớp | `GET /students/my-classes`, `GET /students/classes/{id}/students` |
| Academic Results | `student/academic_results_screen.dart` | Kết quả học tập | `GET /students/academic-summary` |
| Semester Detail | `student/semester_detail_screen.dart` | Chi tiết học kỳ | `GET /students/my-results/{code}` |
| GPA Calculator | `student/gpa_calculator_screen.dart` | Tính GPA | `GET /students/me`, `GET /students/academic-summary` |
| Curriculum | `student/curriculum_screen.dart` | Chương trình học (PDF) | - (Local assets) |
| Utilities | `student/utilities_screen.dart` | Tiện ích menu | - |
| Notifications | `student/notifications_screen.dart` | Thông báo | - (WebView) |
| Reports | `student/reports_screen.dart` | Yêu cầu | `GET /students/my-reports` |
| Tuition | `student/tuition_screen.dart` | Học phí | `GET /students/my-tuitions` |

---

## 8. DATA STORAGE

### 8.1. SharedPreferences

**Package:** `shared_preferences: ^2.5.3`

**Sử dụng:**
```dart
final prefs = await SharedPreferences.getInstance();

// Save
await prefs.setString('access_token', token);
await prefs.setString('user_role', roleStr);

// Read
final token = prefs.getString('access_token');
final role = prefs.getString('user_role');

// Delete
await prefs.remove('access_token');
await prefs.remove('user_role');
```

**Lưu trữ:**
- **access_token**: JWT token
- **user_role**: "student" hoặc "lecturer"

**Platform:**
- **Android**: SharedPreferences (XML file)
- **iOS**: NSUserDefaults
- **Web**: LocalStorage
- **Desktop**: JSON file

### 8.2. Provider State

**In-memory state:**
- **AuthProvider**: _status, _role, _username
- **StudentProvider**: _classes, _grades, _timetable, _academicResults...
- **LecturerProvider**: Lecturer-specific state

**Lifecycle:**
- State được tạo khi provider được khởi tạo
- State bị mất khi app bị kill
- State persist qua navigation nếu provider ở top level

### 8.3. Assets

**Images:**
- `assets/images/logo.png`: App logo

**PDFs:**
- `assets/pdfs/cntt.pdf`: CNTT curriculum
- `assets/pdfs/dtvt.pdf`: DTVT curriculum

**Loading:**
```dart
// Load image
Image.asset('assets/images/logo.png')

// Load PDF
final data = await rootBundle.load('assets/pdfs/cntt.pdf');
final pdfBytes = data.buffer.asUint8List();
```

---

## 9. DATA FLOW

### 9.1. Tổng quan Data Flow

```
User Action (Tap, Input, ...)
    ↓
Event Handler (onTap, onChanged, ...)
    ↓
Provider Method (fetchClasses, login, ...)
    ↓
API Call (apiClient.client.get/post/...)
    ↓
Dio Interceptor (thêm Authorization header)
    ↓
HTTP Request → Backend API
    ↓
Backend xử lý và trả về Response
    ↓
Provider nhận Response
    ↓
Update State (setState, notifyListeners)
    ↓
Widget Rebuild
    ↓
UI Update
```

### 9.2. Ví dụ: Xem thời khóa biểu

```
1. User tap "Thời khóa biểu" trên home screen
   ↓
2. Navigator.push() → TimetableScreen
   ↓
3. initState() → _fetchTimetable()
   ↓
4. Provider.of<StudentProvider>(context, listen: false).fetchTimetable()
   ↓
5. apiClient.client.get('/students/my-timetable')
   ↓
6. Dio interceptor thêm Authorization header
   ↓
7. GET http://10.0.2.2:8000/students/my-timetable
   ↓
8. Backend query database và trả về timetable
   ↓
9. studentProvider._timetable = response.data
   ↓
10. studentProvider.notifyListeners()
   ↓
11. TimetableScreen._fetchTimetable() parse dates
   ↓
12. setState(() { _events = events; })
   ↓
13. Widget rebuild → Render TableCalendar với events
```

### 9.3. State Management Flow

```
Provider State Change
    ↓
notifyListeners()
    ↓
Widgets watching provider rebuild
    ↓
UI Update
```

**Ví dụ:**
```dart
// Provider
class StudentProvider with ChangeNotifier {
  List<dynamic> _classes = [];
  
  Future<void> fetchClasses() async {
    // ... fetch data
    _classes = response.data;
    notifyListeners();  // Notify all listeners
  }
}

// Widget watching provider
class StudentClassesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final classes = context.watch<StudentProvider>().classes;  // Watch
    // Widget rebuilds when classes change
    return ListView(...);
  }
}
```

---

## 10. BEST PRACTICES

### 10.1. Code Organization

1. **Feature-based structure:**
   - Mỗi feature có folder riêng (auth, student, lecturer)
   - Provider và screens trong cùng feature folder

2. **Separation of concerns:**
   - Screens: UI only
   - Providers: State management và business logic
   - API Client: HTTP requests

3. **File naming:**
   - Screens: `*_screen.dart`
   - Providers: `*_provider.dart`
   - Widgets: `*_widget.dart` hoặc inline

### 10.2. State Management

1. **Provider usage:**
   - `context.watch<Provider>()`: Rebuild khi state thay đổi
   - `context.read<Provider>()`: Chỉ đọc, không rebuild
   - `Provider.of<Provider>(context, listen: false)`: Chỉ đọc

2. **State updates:**
   - Luôn gọi `notifyListeners()` sau khi update state
   - Check `mounted` trước khi `setState()` trong async functions

3. **Loading states:**
   ```dart
   bool _isLoading = false;
   
   Future<void> fetchData() async {
     _isLoading = true;
     notifyListeners();
     
     try {
       // Fetch data
     } finally {
       _isLoading = false;
       notifyListeners();
     }
   }
   ```

### 10.3. API Calls

1. **Error handling:**
   ```dart
   try {
     final response = await apiClient.client.get('/endpoint');
     // Handle success
   } catch (e) {
     if (e is DioException) {
       // Handle DioException
       print('Status: ${e.response?.statusCode}');
       print('Data: ${e.response?.data}');
     } else {
       // Handle other errors
       print('Error: $e');
     }
   }
   ```

2. **Loading indicators:**
   ```dart
   if (_isLoading) {
     return const Center(child: CircularProgressIndicator());
   }
   ```

3. **Refresh functionality:**
   ```dart
   RefreshIndicator(
     onRefresh: _fetchData,
     child: ListView(...),
   )
   ```

### 10.4. Navigation

1. **GoRouter vs Navigator:**
   - GoRouter: Declarative routing, deep linking
   - Navigator: Imperative navigation, simple cases

2. **Passing data:**
   ```dart
   // Via constructor
   Navigator.push(
     context,
     MaterialPageRoute(
       builder: (_) => DetailScreen(data: data),
     ),
   );
   
   // Via route extra (GoRouter)
   context.push('/detail', extra: data);
   ```

### 10.5. Performance

1. **Widget optimization:**
   - Sử dụng `const` constructors khi có thể
   - Tránh rebuild không cần thiết với `context.read()` thay vì `context.watch()`

2. **List optimization:**
   - Sử dụng `ListView.builder` cho long lists
   - Implement pagination nếu cần

3. **Image optimization:**
   - Cache images với `CachedNetworkImage`
   - Resize images nếu quá lớn

### 10.6. Security

1. **Token storage:**
   - Lưu token trong SharedPreferences (có thể encrypt cho production)
   - Không log token ra console

2. **API security:**
   - Luôn dùng HTTPS trong production
   - Validate input ở client (UX) và server (Security)

---

## 11. TÓM TẮT

### 11.1. Kiến trúc

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **HTTP**: Dio với interceptors
- **Routing**: GoRouter
- **Storage**: SharedPreferences
- **Authentication**: JWT với jwt_decoder

### 11.2. Data Flow

```
User → Event Handler → Provider → API Client → Backend → Response → State Update → UI Rebuild
```

### 11.3. Key Files

| File | Chức năng |
|------|-----------|
| `main.dart` | Entry point, providers, router |
| `core/api_client.dart` | Dio instance & interceptors |
| `features/auth/auth_provider.dart` | Authentication state |
| `features/student/student_provider.dart` | Student state |
| `features/student/student_dashboard.dart` | Main dashboard |
| `features/student/*_screen.dart` | Student screens |

### 11.4. Storage

- **SharedPreferences**: Token, user role
- **Provider State**: In-memory state (classes, grades, timetable...)
- **Assets**: Images, PDFs
- **Backend Database**: Persistent data (PostgreSQL)

---

**Tài liệu này cung cấp phân tích cực kỳ chi tiết về kiến trúc mobile app LMS. Nếu cần thêm thông tin về bất kỳ phần nào, vui lòng cho biết!**
