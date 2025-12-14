import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/lecturer/lecturer_provider.dart';
import 'features/student/student_provider.dart';
import 'features/student/student_dashboard.dart';
import 'features/lecturer/lecturer_dashboard.dart';
import 'features/student/reports_screen.dart';
import 'features/student/create_report_screen.dart';
import 'features/student/report_detail_screen.dart';
import 'features/student/notifications_screen.dart';
import 'shared/profile_screen.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final router = GoRouter(
      refreshListenable: authProvider,
      redirect: (context, state) {
        final loggedIn = authProvider.status == AuthStatus.authenticated;
        final isLoggingIn = state.uri.toString() == '/login';

        if (!loggedIn) return '/login';
        
        if (loggedIn && (isLoggingIn || state.uri.toString() == '/')) {
          if (authProvider.role == UserRole.lecturer) return '/lecturer';
          if (authProvider.role == UserRole.student) return '/student';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/student',
          builder: (context, state) => const StudentDashboard(),
        ),
        GoRoute(
          path: '/lecturer',
          builder: (context, state) => const LecturerDashboard(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/create-report',
          builder: (context, state) => const CreateReportScreen(),
        ),
        GoRoute(
          path: '/report-detail',
          builder: (context, state) {
            final reportId = state.extra as int;
            return ReportDetailScreen(reportId: reportId);
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'LMS Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      routerConfig: router,
    );
  }
}
