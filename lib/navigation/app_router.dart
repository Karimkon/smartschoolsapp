import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/auth_provider.dart';
import '../features/splash/splash_screen.dart';
import '../features/auth/login_screen.dart';
import '../navigation/nav_shell.dart';

// ── Admin ──────────────────────────────────────────────────────────────────────
import '../features/admin/dashboard.dart';
import '../features/admin/students/students_screen.dart';
import '../features/admin/students/student_detail_screen.dart';
import '../features/admin/teachers/teachers_screen.dart';
import '../features/admin/attendance/attendance_screen.dart';
import '../features/admin/fees/fees_screen.dart';
import '../features/admin/more/more_screen.dart';

// People
import '../features/admin/classes/classes_screen.dart';
import '../features/admin/staff/staff_screen.dart';
import '../features/admin/parents/parents_screen.dart';
import '../features/admin/branches/branches_screen.dart';

// Academics
import '../features/admin/timetable/timetable_screen.dart';
import '../features/admin/assignments/assignments_screen.dart';
import '../features/admin/exams/exams_screen.dart';
import '../features/admin/marks/marks_screen.dart';
import '../features/admin/report_cards/report_cards_screen.dart';
import '../features/admin/materials/study_materials_screen.dart';

// Finance & HR
import '../features/admin/expenses/expenses_screen.dart';
import '../features/admin/payroll/payroll_screen.dart';
import '../features/admin/requirements/requirements_screen.dart';
import '../features/admin/leave/leave_screen.dart';  // AdminLeaveScreen

// Attendance
import '../features/admin/biometric/biometric_screen.dart';
import '../features/admin/attendance_reports/attendance_reports_screen.dart';

// Operations
import '../features/admin/library/admin_library_screen.dart';
import '../features/admin/transport/transport_screen.dart';
import '../features/admin/inventory/inventory_screen.dart';
import '../features/admin/id_cards/id_cards_screen.dart';
import '../features/admin/disciplinary/disciplinary_screen.dart';

// Communication & Reception
import '../features/admin/announcements/announcements_screen.dart';
import '../features/admin/events/events_screen.dart';
import '../features/admin/reception/reception_screen.dart';
import '../features/admin/admissions/admissions_screen.dart';

// Settings
import '../features/admin/settings/settings_screen.dart';

// New Features (7-11) + Push Notifications (15)
import '../features/admin/houses/houses_screen.dart';
import '../features/admin/leadership/leadership_screen.dart';
import '../features/shared/messages_screen.dart';
import '../features/admin/push_notifications/push_notifications_screen.dart';

// ── Teacher ────────────────────────────────────────────────────────────────────
import '../features/teacher/teacher_dashboard.dart';
import '../features/teacher/teacher_timetable_screen.dart';
import '../features/teacher/teacher_assignments_screen.dart';
import '../features/teacher/teacher_attendance_screen.dart';
import '../features/teacher/lesson_attendance_screen.dart';
import '../features/teacher/teacher_my_classes_screen.dart';

// ── Student ────────────────────────────────────────────────────────────────────
import '../features/student/student_dashboard.dart';
import '../features/student/student_timetable_screen.dart';
import '../features/student/student_fees_screen.dart';
import '../features/student/student_results_screen.dart';

// ── Parent ─────────────────────────────────────────────────────────────────────
import '../features/parent/parent_dashboard.dart';
import '../features/parent/parent_fees_screen.dart';
import '../features/parent/parent_reports_screen.dart';
import '../features/parent/parent_attendance_screen.dart';
import '../features/parent/parent_announcements_screen.dart';
import '../features/parent/parent_messages_screen.dart';
import '../features/accountant/accountant_dashboard.dart';
import '../features/accountant/accountant_fees_screen.dart';
import '../features/librarian/librarian_dashboard.dart';
import '../features/librarian/books_screen.dart';
import '../features/super_admin/super_admin_dashboard.dart';
import '../features/dos/dos_dashboard.dart';
import '../features/profile/profile_screen.dart';
import '../features/landing/landing_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState  = ref.read(authProvider);
      final isLoggedIn = authState.isLoggedIn;
      final loc          = state.matchedLocation;
      final onSplash     = loc == '/splash';
      final onLanding = loc == '/landing';
      final onLogin   = loc == '/login';

      if (onSplash || onLanding) return null;
      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) return _homeForRole(authState.user!.role);
      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/landing',     builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),

      // ── Admin shell ──────────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'school_admin'),
        routes: [
          GoRoute(path: '/admin',           builder: (_, __) => const AdminDashboard()),
          GoRoute(path: '/admin/more',      builder: (_, __) => const MoreScreen()),
          GoRoute(path: '/admin/profile',   builder: (_, __) => const ProfileScreen()),

          // People
          GoRoute(path: '/admin/students',      builder: (_, __) => const StudentsScreen()),
          GoRoute(path: '/admin/students/:id',  builder: (_, s) => StudentDetailScreen(id: int.parse(s.pathParameters['id']!))),
          GoRoute(path: '/admin/teachers',      builder: (_, __) => const TeachersScreen()),
          GoRoute(path: '/admin/staff',         builder: (_, __) => const StaffScreen()),
          GoRoute(path: '/admin/parents',       builder: (_, __) => const ParentsScreen()),
          GoRoute(path: '/admin/classes',       builder: (_, __) => const ClassesScreen()),
          GoRoute(path: '/admin/branches',      builder: (_, __) => const BranchesScreen()),

          // Academics
          GoRoute(path: '/admin/timetable',     builder: (_, __) => const AdminTimetableScreen()),
          GoRoute(path: '/admin/assignments',   builder: (_, __) => const AdminAssignmentsScreen()),
          GoRoute(path: '/admin/exams',         builder: (_, __) => const ExamsScreen()),
          GoRoute(path: '/admin/marks',         builder: (_, __) => const MarksScreen()),
          GoRoute(path: '/admin/report-cards',  builder: (_, __) => const ReportCardsScreen()),
          GoRoute(path: '/admin/materials',     builder: (_, __) => const StudyMaterialsScreen()),

          // Finance & HR
          GoRoute(path: '/admin/fees',          builder: (_, __) => const AdminFeesScreen()),
          GoRoute(path: '/admin/expenses',      builder: (_, __) => const ExpensesScreen()),
          GoRoute(path: '/admin/payroll',       builder: (_, __) => const AdminPayrollScreen()),
          GoRoute(path: '/admin/requirements',  builder: (_, __) => const RequirementsScreen()),
          GoRoute(path: '/admin/leave',         builder: (_, __) => const AdminLeaveScreen()),

          // Attendance
          GoRoute(path: '/admin/attendance',        builder: (_, __) => const AdminAttendanceScreen()),
          GoRoute(path: '/admin/biometric',         builder: (_, __) => const BiometricScreen()),
          GoRoute(path: '/admin/attendance-reports',builder: (_, __) => const AttendanceReportsScreen()),

          // Operations
          GoRoute(path: '/admin/library',     builder: (_, __) => const AdminLibraryScreen()),
          GoRoute(path: '/admin/transport',   builder: (_, __) => const AdminTransportScreen()),
          GoRoute(path: '/admin/inventory',   builder: (_, __) => const InventoryScreen()),
          GoRoute(path: '/admin/id-cards',    builder: (_, __) => const IDCardsScreen()),
          GoRoute(path: '/admin/disciplinary',builder: (_, __) => const DisciplinaryScreen()),

          // Communication & Reception
          GoRoute(path: '/admin/announcements', builder: (_, __) => const AnnouncementsScreen()),
          GoRoute(path: '/admin/events',        builder: (_, __) => const EventsScreen()),
          GoRoute(path: '/admin/reception',     builder: (_, __) => const AdminReceptionScreen()),
          GoRoute(path: '/admin/admissions',    builder: (_, __) => const AdminAdmissionsScreen()),

          // Settings
          GoRoute(path: '/admin/settings',      builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/admin/sms-settings',  builder: (_, __) => const SettingsScreen()),

          // New Features
          GoRoute(path: '/admin/houses',               builder: (_, __) => const HousesScreen()),
          GoRoute(path: '/admin/leadership',           builder: (_, __) => const LeadershipScreen()),
          GoRoute(path: '/admin/messages',             builder: (_, __) => const MessagesScreen()),
          GoRoute(path: '/admin/employees',            builder: (_, __) => const TeachersScreen()),
          GoRoute(path: '/admin/push-notifications',   builder: (_, __) => const PushNotificationsScreen()),
        ],
      ),

      // ── Teacher shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'teacher'),
        routes: [
          GoRoute(path: '/teacher',                   builder: (_, __) => const TeacherDashboard()),
          GoRoute(path: '/teacher/timetable',         builder: (_, __) => const TeacherTimetableScreen()),
          GoRoute(path: '/teacher/assignments',       builder: (_, __) => const TeacherAssignmentsScreen()),
          GoRoute(path: '/teacher/attendance',        builder: (_, __) => const TeacherAttendanceScreen()),
          GoRoute(path: '/teacher/lesson-attendance', builder: (_, __) => const LessonAttendanceScreen()),
          GoRoute(path: '/teacher/marks',             builder: (_, __) => const MarksScreen()),
          GoRoute(path: '/teacher/my-classes',        builder: (_, __) => const TeacherMyClassesScreen()),
          GoRoute(path: '/teacher/report-cards',      builder: (_, __) => const ReportCardsScreen()),
          GoRoute(path: '/teacher/profile',           builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/teacher/messages',          builder: (_, __) => const MessagesScreen()),
        ],
      ),

      // ── Student shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'student'),
        routes: [
          GoRoute(path: '/student',           builder: (_, __) => const StudentDashboard()),
          GoRoute(path: '/student/timetable', builder: (_, __) => const StudentTimetableScreen()),
          GoRoute(path: '/student/fees',      builder: (_, __) => const StudentFeesScreen()),
          GoRoute(path: '/student/results',   builder: (_, __) => const StudentResultsScreen()),
          GoRoute(path: '/student/profile',   builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Parent shell ─────────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'parent'),
        routes: [
          GoRoute(path: '/parent',               builder: (_, __) => const ParentDashboard()),
          GoRoute(path: '/parent/profile',       builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/parent/fees',          builder: (_, __) => const ParentFeesScreen()),
          GoRoute(path: '/parent/reports',       builder: (_, __) => const ParentReportsScreen()),
          GoRoute(path: '/parent/attendance',    builder: (_, __) => const ParentAttendanceScreen()),
          GoRoute(path: '/parent/announcements', builder: (_, __) => const ParentAnnouncementsScreen()),
          GoRoute(path: '/parent/messages',      builder: (_, __) => const ParentMessagesScreen()),
        ],
      ),

      // ── Accountant shell ─────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'accountant'),
        routes: [
          GoRoute(path: '/accountant',         builder: (_, __) => const AccountantDashboard()),
          GoRoute(path: '/accountant/fees',    builder: (_, __) => const AccountantFeesScreen()),
          GoRoute(path: '/accountant/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Librarian shell ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'librarian'),
        routes: [
          GoRoute(path: '/librarian',         builder: (_, __) => const LibrarianDashboard()),
          GoRoute(path: '/librarian/books',   builder: (_, __) => const BooksScreen()),
          GoRoute(path: '/librarian/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Super Admin shell ────────────────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'super_admin'),
        routes: [
          GoRoute(path: '/super-admin',         builder: (_, __) => const SuperAdminDashboard()),
          GoRoute(path: '/super-admin/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── DOS (Dean of Studies) shell ──────────────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => NavShell(child: child, role: 'dos'),
        routes: [
          GoRoute(path: '/dos',                   builder: (_, __) => const DosDashboard()),
          GoRoute(path: '/dos/profile',           builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/dos/attendance',        builder: (_, __) => const AdminAttendanceScreen()),
          GoRoute(path: '/dos/students',          builder: (_, __) => const StudentsScreen()),
          GoRoute(path: '/dos/report-cards',      builder: (_, __) => const ReportCardsScreen()),
        ],
      ),
    ],
  );
  ref.listen<AuthState>(authProvider, (_, __) => router.refresh());
  return router;
});

String _homeForRole(String role) {
  switch (role) {
    case 'super_admin':  return '/super-admin';
    case 'school_admin': return '/admin';
    case 'teacher':      return '/teacher';
    case 'student':      return '/student';
    case 'parent':       return '/parent';
    case 'accountant':   return '/accountant';
    case 'librarian':    return '/librarian';
    case 'dos':          return '/dos';
    default:             return '/login';
  }
}
