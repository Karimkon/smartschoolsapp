import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Teacher {
  final int id;
  final String name, subject, department, phone, email, status;

  const _Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.department,
    required this.phone,
    required this.email,
    required this.status,
  });

  String get initials {
    final p = name.split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : name[0];
  }
}

const _mockTeachers = [
  _Teacher(id: 1, name: 'Mr. Paul Ochieng',   subject: 'Mathematics',  department: 'Sciences',    phone: '+254 712 001001', email: 'p.ochieng@school.ke',   status: 'Active'),
  _Teacher(id: 2, name: 'Ms. Grace Wanjiku',  subject: 'English',      department: 'Languages',   phone: '+254 713 002002', email: 'g.wanjiku@school.ke',   status: 'Active'),
  _Teacher(id: 3, name: 'Mr. James Kariuki',  subject: 'Science',      department: 'Sciences',    phone: '+254 714 003003', email: 'j.kariuki@school.ke',   status: 'Active'),
  _Teacher(id: 4, name: 'Ms. Lucy Auma',      subject: 'History',      department: 'Humanities',  phone: '+254 715 004004', email: 'l.auma@school.ke',      status: 'On Leave'),
  _Teacher(id: 5, name: 'Mr. David Mwangi',   subject: 'Kiswahili',    department: 'Languages',   phone: '+254 716 005005', email: 'd.mwangi@school.ke',    status: 'Active'),
  _Teacher(id: 6, name: 'Ms. Agnes Nakato',   subject: 'Geography',    department: 'Humanities',  phone: '+254 717 006006', email: 'a.nakato@school.ke',    status: 'Active'),
  _Teacher(id: 7, name: 'Mr. Peter Ssali',    subject: 'Art & Design', department: 'Creative Arts',phone: '+254 718 007007',email: 'p.ssali@school.ke',     status: 'Active'),
  _Teacher(id: 8, name: 'Ms. Ruth Otieno',    subject: 'Chemistry',    department: 'Sciences',    phone: '+254 719 008008', email: 'r.otieno@school.ke',    status: 'Inactive'),
];

const _departments = ['All', 'Sciences', 'Languages', 'Humanities', 'Creative Arts'];

// ── Screen ────────────────────────────────────────────────────────────────────

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final _searchCtrl = TextEditingController();
  String _dept = 'All';
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Teacher> get _filtered => _mockTeachers.where((t) {
    final matchDept  = _dept == 'All' || t.department == _dept;
    final matchQuery = _query.isEmpty ||
        t.name.toLowerCase().contains(_query.toLowerCase()) ||
        t.subject.toLowerCase().contains(_query.toLowerCase());
    return matchDept && matchQuery;
  }).toList();

  static const _avatarColors = [
    AppColors.roleTeacher, AppColors.primary, AppColors.accent,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ];

  Color _color(int i) => _avatarColors[i % _avatarColors.length];

  Color _statusColor(String s) {
    switch (s) {
      case 'Active':   return AppColors.success;
      case 'On Leave': return AppColors.warning;
      default:         return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = _filtered;

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
            const Text('Teachers', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.roleTeacher.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_mockTeachers.length}',
                style: const TextStyle(color: AppColors.roleTeacher, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search by name or subject...',
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _departments.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final d = _departments[i];
                        final sel = d == _dept;
                        return GestureDetector(
                          onTap: () => setState(() => _dept = d),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.roleTeacher : AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppColors.roleTeacher : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Text(d, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        );
                      },
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text('${teachers.length} teacher${teachers.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Expanded(
              child: teachers.isEmpty
                  ? const Center(child: Text('No teachers found', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: teachers.length,
                      itemBuilder: (context, i) {
                        final t = teachers[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                AvatarWidget(initials: t.initials, color: _color(i), size: 52),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(t.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                          ),
                                          StatusBadge(label: t.status, color: _statusColor(t.status)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(t.subject, style: TextStyle(fontSize: 12, color: _color(i), fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.domain_rounded, size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(t.department, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.phone_rounded, size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(t.phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    _IconBtn(
                                      icon: Icons.phone_rounded,
                                      color: AppColors.success,
                                      onTap: () {},
                                    ),
                                    const SizedBox(height: 6),
                                    _IconBtn(
                                      icon: Icons.message_rounded,
                                      color: AppColors.primary,
                                      onTap: () {},
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
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );
}
