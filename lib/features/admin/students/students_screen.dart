import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Student {
  final int id;
  final String name;
  final String admNo;
  final String className;
  final String status;
  final int attendance;
  final String gender;

  const _Student({
    required this.id,
    required this.name,
    required this.admNo,
    required this.className,
    required this.status,
    required this.attendance,
    required this.gender,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name[0];
  }
}

const _mockStudents = [
  _Student(id: 1, name: 'Amara Osei',      admNo: 'ADM-2024-001', className: 'Grade 7A', status: 'Active',   attendance: 94, gender: 'Female'),
  _Student(id: 2, name: 'Brian Mwangi',    admNo: 'ADM-2024-002', className: 'Grade 8B', status: 'Active',   attendance: 87, gender: 'Male'),
  _Student(id: 3, name: 'Chidi Okonkwo',   admNo: 'ADM-2023-015', className: 'Grade 9A', status: 'Active',   attendance: 91, gender: 'Male'),
  _Student(id: 4, name: 'Diana Kamau',     admNo: 'ADM-2024-008', className: 'Grade 7B', status: 'Inactive', attendance: 45, gender: 'Female'),
  _Student(id: 5, name: 'Emmanuel Ssali',  admNo: 'ADM-2023-022', className: 'Grade 10A',status: 'Active',   attendance: 96, gender: 'Male'),
  _Student(id: 6, name: 'Fatima Hassan',   admNo: 'ADM-2024-011', className: 'Grade 8A', status: 'Active',   attendance: 89, gender: 'Female'),
  _Student(id: 7, name: 'George Weru',     admNo: 'ADM-2022-034', className: 'Grade 11B',status: 'Inactive', attendance: 62, gender: 'Male'),
  _Student(id: 8, name: 'Halima Juma',     admNo: 'ADM-2024-019', className: 'Grade 9B', status: 'Active',   attendance: 98, gender: 'Female'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Student> get _filtered {
    return _mockStudents.where((s) {
      final matchesFilter = _filter == 'All' || s.status == _filter;
      final matchesQuery = _query.isEmpty ||
          s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.admNo.toLowerCase().contains(_query.toLowerCase()) ||
          s.className.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Color _avatarColor(int index) {
    const colors = [
      AppColors.primary, AppColors.accent, AppColors.roleTeacher,
      AppColors.warning, AppColors.roleAccountant, AppColors.success,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final students = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Students', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_mockStudents.length}',
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Search + Filters
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search by name, admission no...',
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Active', 'Inactive'].map((f) {
                      final selected = _filter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AppColors.primary : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                color: selected ? Colors.white : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),
            ),

            // Count row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${students.length} student${students.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
                ],
              ),
            ),

            // List
            Expanded(
              child: students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, color: AppColors.textHint, size: 52),
                          const SizedBox(height: 12),
                          const Text('No students found', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: students.length,
                      itemBuilder: (context, i) {
                        final s = students[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            onTap: () => context.push('/admin/students/${s.id}'),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                AvatarWidget(
                                  initials: s.initials,
                                  color: _avatarColor(i),
                                  size: 48,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.badge_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.admNo,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(
                                            s.className,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    StatusBadge(
                                      label: s.status,
                                      color: s.status == 'Active' ? AppColors.success : AppColors.error,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _attendanceColor(s.attendance).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${s.attendance}% att.',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _attendanceColor(s.attendance),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _attendanceColor(int pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }
}
