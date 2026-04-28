import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../app/theme/app_colors.dart';

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
  const _NavItem(this.label, this.icon, this.activeIcon, this.path);
}

class NavShell extends StatelessWidget {
  final Widget child;
  final String role;

  const NavShell({super.key, required this.child, required this.role});

  static const _adminItems = [
    _NavItem('Home',       Icons.dashboard_outlined,              Icons.dashboard_rounded,             '/admin'),
    _NavItem('Students',   Icons.people_outline,                  Icons.people_rounded,                '/admin/students'),
    _NavItem('Attendance', Icons.fact_check_outlined,             Icons.fact_check_rounded,            '/admin/attendance'),
    _NavItem('Finance',    Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded,'/admin/fees'),
    _NavItem('More',       Icons.apps_outlined,                   Icons.apps_rounded,                  '/admin/more'),
  ];

  static const _teacherItems = [
    _NavItem('Home',       Icons.dashboard_outlined,   Icons.dashboard_rounded,     '/teacher'),
    _NavItem('Timetable',  Icons.calendar_today_outlined, Icons.calendar_today_rounded, '/teacher/timetable'),
    _NavItem('Attendance', Icons.fact_check_outlined,   Icons.fact_check_rounded,    '/teacher/attendance'),
    _NavItem('Tasks',      Icons.assignment_outlined,   Icons.assignment_rounded,    '/teacher/assignments'),
    _NavItem('Profile',    Icons.person_outline,        Icons.person_rounded,        '/teacher/profile'),
  ];

  static const _studentItems = [
    _NavItem('Home',      Icons.home_outlined,            Icons.home_rounded,             '/student'),
    _NavItem('Timetable', Icons.calendar_today_outlined,  Icons.calendar_today_rounded,   '/student/timetable'),
    _NavItem('Fees',      Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, '/student/fees'),
    _NavItem('Results',   Icons.school_outlined,          Icons.school_rounded,           '/student/results'),
    _NavItem('Profile',   Icons.person_outline,           Icons.person_rounded,           '/student/profile'),
  ];

  static const _parentItems = [
    _NavItem('Home',       Icons.home_outlined,                   Icons.home_rounded,                    '/parent'),
    _NavItem('Fees',       Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded,  '/parent/fees'),
    _NavItem('Reports',    Icons.school_outlined,                 Icons.school_rounded,                  '/parent/reports'),
    _NavItem('Attendance', Icons.fact_check_outlined,             Icons.fact_check_rounded,              '/parent/attendance'),
    _NavItem('Profile',    Icons.person_outline,                  Icons.person_rounded,                  '/parent/profile'),
  ];

  static const _accountantItems = [
    _NavItem('Home',    Icons.dashboard_outlined,  Icons.dashboard_rounded,  '/accountant'),
    _NavItem('Invoices',Icons.receipt_outlined,    Icons.receipt_rounded,    '/accountant/fees'),
    _NavItem('Profile', Icons.person_outline,      Icons.person_rounded,     '/accountant/profile'),
  ];

  static const _librarianItems = [
    _NavItem('Home',    Icons.dashboard_outlined, Icons.dashboard_rounded, '/librarian'),
    _NavItem('Books',   Icons.menu_book_outlined, Icons.menu_book_rounded,  '/librarian/books'),
    _NavItem('Profile', Icons.person_outline,     Icons.person_rounded,    '/librarian/profile'),
  ];

  static const _superAdminItems = [
    _NavItem('Schools', Icons.business_outlined, Icons.business_rounded, '/super-admin'),
    _NavItem('Profile', Icons.person_outline,    Icons.person_rounded,   '/super-admin/profile'),
  ];

  List<_NavItem> get _items {
    switch (role) {
      case 'teacher':     return _teacherItems;
      case 'student':     return _studentItems;
      case 'parent':      return _parentItems;
      case 'accountant':  return _accountantItems;
      case 'librarian':   return _librarianItems;
      case 'super_admin': return _superAdminItems;
      default:            return _adminItems;
    }
  }

  Color get _roleColor {
    switch (role) {
      case 'teacher':     return AppColors.roleTeacher;
      case 'student':     return AppColors.roleStudent;
      case 'parent':      return AppColors.roleParent;
      case 'accountant':  return AppColors.roleAccountant;
      case 'librarian':   return AppColors.roleLibrarian;
      case 'super_admin': return AppColors.roleSuperAdmin;
      default:            return AppColors.roleAdmin;
    }
  }

  int _currentIndex(String location) {
    final items = _items;
    for (int i = items.length - 1; i >= 0; i--) {
      if (location.startsWith(items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index    = _currentIndex(location);
    final items    = _items;
    final color    = _roleColor;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface1,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(items.length, (i) {
                final selected = i == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(items[i].path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? color.withOpacity(0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            selected ? items[i].activeIcon : items[i].icon,
                            color: selected ? color : AppColors.textHint,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? color : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
