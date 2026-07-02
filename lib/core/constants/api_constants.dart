class ApiConstants {
  static const String baseUrl = 'https://smartschoolshub.com/api';

  // Authentication
  static const String login          = '/auth/login';
  static const String logout         = '/auth/logout';
  static const String me             = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Students
  static const String students      = '/students';
  static const String studentDetail = '/students/{id}';

  // Employees (Teachers + Staff)
  static const String employees = '/teachers';
  static const String teachers  = '/teachers';
  static const String staff     = '/staff';

  // Attendance
  static const String attendance     = '/attendance';
  static const String markAttendance = '/attendance/mark';

  // Fees
  static const String feeInvoices = '/fees/invoices';
  static const String feePayments = '/fees/payments';
  static const String feeBalance  = '/fees/balance';

  // Academics
  static const String timetable   = '/timetable';
  static const String assignments = '/assignments';
  static const String subjects    = '/subjects';
  static const String classes     = '/classes';
  static const String reportCards = '/report-cards';
  static const String exams       = '/exams';
  static const String materials   = '/materials';

  // Marks
  static const String marksSetup = '/marks/setup';
  static const String marksEntry = '/marks/entry';
  static const String marksSave  = '/marks/save';

  // Teacher-specific
  static const String teacherAssignments = '/teacher/assignments';

  // Library
  static const String books      = '/library/books';
  static const String borrowings = '/library/borrowings';

  // Announcements / Events
  static const String announcements = '/announcements';
  static const String events        = '/events';

  // Houses (Feature 8)
  static const String houses        = '/houses';
  static const String houseStudents = '/houses/{id}';

  // Student Leadership (Feature 9)
  static const String leadership          = '/student-leadership';
  static const String leadershipPositions = '/student-leadership/positions';

  // Messages (Feature 10)
  static const String messages       = '/messages';
  static const String messageThread  = '/messages/{id}';
  static const String messagesUnread = '/messages/unread';
  static const String messagesUsers  = '/messages/users';

  // Parent-specific
  static const String parentMessages = '/parent/messages';
  static const String parentStaff    = '/parent/staff';

  // Schools (super_admin)
  static const String schools = '/schools';

  // Settings
  static const String settings = '/settings';

  // Push Notifications (Feature 15)
  static const String deviceToken       = '/device-token';
  static const String pushNotifications = '/push-notifications';
}
