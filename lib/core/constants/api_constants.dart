class ApiConstants {
  static const String baseUrl = 'https://smartschoolshub.com/api';
  // For local development:
  // static const String baseUrl = 'http://localhost/smartschools/api';

  // Auth
  static const String login  = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me     = '/auth/me';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Students
  static const String students       = '/students';
  static const String studentDetail  = '/students/{id}';

  // Teachers
  static const String teachers = '/teachers';

  // Attendance
  static const String attendance       = '/attendance';
  static const String markAttendance   = '/attendance/mark';

  // Fees
  static const String feeInvoices  = '/fees/invoices';
  static const String feePayments  = '/fees/payments';
  static const String feeBalance   = '/fees/balance';

  // Academics
  static const String timetable   = '/timetable';
  static const String assignments = '/assignments';
  static const String subjects    = '/subjects';
  static const String classes     = '/classes';

  // Library
  static const String books      = '/library/books';
  static const String borrowings = '/library/borrowings';

  // Announcements / Events
  static const String announcements = '/announcements';
  static const String events        = '/events';

  // Reports
  static const String reportCards = '/report-cards';

  // Schools (super_admin)
  static const String schools = '/schools';
}
