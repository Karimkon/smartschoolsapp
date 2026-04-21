import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Model ────────────────────────────────────────────────────────────────

class _StudentDetail {
  final int id;
  final String name, admNo, className, stream, status, dob, gender, guardian,
      guardianPhone, session;
  final int attendance;
  final double totalFee, paidFee;
  final List<_MonthAttendance> monthlyAttendance;
  final List<_SubjectResult> results;

  const _StudentDetail({
    required this.id,
    required this.name,
    required this.admNo,
    required this.className,
    required this.stream,
    required this.status,
    required this.dob,
    required this.gender,
    required this.guardian,
    required this.guardianPhone,
    required this.session,
    required this.attendance,
    required this.totalFee,
    required this.paidFee,
    required this.monthlyAttendance,
    required this.results,
  });

  double get balance => totalFee - paidFee;
  String get initials {
    final p = name.split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : name[0];
  }
}

class _MonthAttendance {
  final String month;
  final int present, absent, late;
  const _MonthAttendance(this.month, this.present, this.absent, this.late);
  int get total => present + absent + late;
  int get pct => total == 0 ? 0 : ((present / total) * 100).round();
}

class _SubjectResult {
  final String subject;
  final int marks;
  final String grade;
  const _SubjectResult(this.subject, this.marks, this.grade);
}

// ── Mock Factory ──────────────────────────────────────────────────────────────

_StudentDetail _mockDetail(int id) {
  final names = {
    1: 'Amara Osei',      2: 'Brian Mwangi',    3: 'Chidi Okonkwo',
    4: 'Diana Kamau',     5: 'Emmanuel Ssali',  6: 'Fatima Hassan',
    7: 'George Weru',     8: 'Halima Juma',
  };
  final classes = {
    1: 'Grade 7A', 2: 'Grade 8B', 3: 'Grade 9A', 4: 'Grade 7B',
    5: 'Grade 10A', 6: 'Grade 8A', 7: 'Grade 11B', 8: 'Grade 9B',
  };
  final name = names[id] ?? 'Student $id';
  final cls  = classes[id] ?? 'Grade 7A';

  return _StudentDetail(
    id: id,
    name: name,
    admNo: 'ADM-2024-${id.toString().padLeft(3, '0')}',
    className: cls,
    stream: 'Science',
    status: (id == 4 || id == 7) ? 'Inactive' : 'Active',
    dob: '${2008 + (id % 3)}-${(id * 2).clamp(1, 12).toString().padLeft(2, '0')}-14',
    gender: (id % 2 == 0) ? 'Male' : 'Female',
    guardian: 'Parent of $name',
    guardianPhone: '+254 7${id}0 ${(id * 111111).toString().substring(0, 6)}',
    session: '2024 / 2025',
    attendance: 70 + (id * 4 % 28),
    totalFee: 45000 + (id * 5000).toDouble(),
    paidFee: 30000 + (id * 3000).toDouble(),
    monthlyAttendance: [
      _MonthAttendance('January', 18, 2, 1),
      _MonthAttendance('February', 16, 3, 2),
      _MonthAttendance('March',    19, 1, 0),
      _MonthAttendance('April',    15, 4, 2),
    ],
    results: [
      _SubjectResult('Mathematics', 72 + id, id < 4 ? 'B+' : 'B'),
      _SubjectResult('English',     68 + id, id < 5 ? 'B'  : 'C+'),
      _SubjectResult('Science',     80 + id, 'A'),
      _SubjectResult('History',     65 + id, 'C+'),
      _SubjectResult('Kiswahili',   75 + id, 'B+'),
    ],
  );
}

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentDetailScreen extends StatefulWidget {
  final int id;
  const StudentDetailScreen({super.key, required this.id});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final _StudentDetail _student;

  @override
  void initState() {
    super.initState();
    _tabs    = TabController(length: 3, vsync: this);
    _student = _mockDetail(widget.id);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static const _avatarColors = [
    AppColors.primary, AppColors.accent, AppColors.roleTeacher,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ];

  Color get _color => _avatarColors[widget.id % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildTabBar()),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(student: _student),
                _AttendanceTab(student: _student),
                _ResultsTab(student: _student),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Back + actions
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Avatar + name block
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              AvatarWidget(initials: _student.initials, color: _color, size: 80)
                  .animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),
              Text(
                _student.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_student.admNo, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  StatusBadge(
                    label: _student.status,
                    color: _student.status == 'Active' ? AppColors.success : AppColors.error,
                  ),
                ],
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                '${_student.className}  •  ${_student.session}',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ).animate(delay: 200.ms).fadeIn(),
            ],
          ),
        ),

        // Info cards row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(child: _MiniStat(label: 'Attendance', value: '${_student.attendance}%', color: _attendanceColor(_student.attendance), icon: Icons.bar_chart_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Balance', value: 'KES ${_student.balance.toStringAsFixed(0)}', color: AppColors.warning, icon: Icons.account_balance_wallet_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Class', value: _student.className, color: AppColors.primary, icon: Icons.class_rounded)),
            ],
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface1,
      child: TabBar(
        controller: _tabs,
        indicatorColor: AppColors.primary,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Attendance'),
          Tab(text: 'Results'),
        ],
      ),
    );
  }

  Color _attendanceColor(int pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }
}

// ── Mini Stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final _StudentDetail student;
  const _OverviewTab({required this.student});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Details
        _InfoSection(
          title: 'Personal Details',
          icon: Icons.person_rounded,
          color: AppColors.primary,
          rows: [
            _InfoRow('Date of Birth', student.dob),
            _InfoRow('Gender',        student.gender),
            _InfoRow('Guardian',      student.guardian),
            _InfoRow('Guardian Phone',student.guardianPhone),
          ],
        ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 12),

        // Academic Details
        _InfoSection(
          title: 'Academic Information',
          icon: Icons.school_rounded,
          color: AppColors.accent,
          rows: [
            _InfoRow('Class',   student.className),
            _InfoRow('Stream',  student.stream),
            _InfoRow('Session', student.session),
            _InfoRow('Admission No', student.admNo),
          ],
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 12),

        // Fee Summary
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.warning, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Fee Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              _FeeStat('Total Billed', 'KES ${student.totalFee.toStringAsFixed(0)}', AppColors.textPrimary),
              const Divider(color: Colors.white12, height: 20),
              _FeeStat('Amount Paid', 'KES ${student.paidFee.toStringAsFixed(0)}', AppColors.success),
              const Divider(color: Colors.white12, height: 20),
              _FeeStat('Balance Due', 'KES ${student.balance.toStringAsFixed(0)}', AppColors.warning),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: student.totalFee > 0 ? student.paidFee / student.totalFee : 0,
                  minHeight: 8,
                  backgroundColor: AppColors.surface3,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${((student.paidFee / student.totalFee) * 100).toStringAsFixed(0)}% paid',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoRow> rows;
  const _InfoSection({required this.title, required this.icon, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 14),
        ...rows.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
              Expanded(flex: 3, child: Text(r.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            ],
          ),
        )),
      ],
    ),
  );
}

class _InfoRow {
  final String label, value;
  const _InfoRow(this.label, this.value);
}

class _FeeStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FeeStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value,  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

// ── Attendance Tab ────────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final _StudentDetail student;
  const _AttendanceTab({required this.student});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall card
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _attColor(student.attendance).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${student.attendance}%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _attColor(student.attendance)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Overall Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(_attLabel(student.attendance), style: TextStyle(fontSize: 12, color: _attColor(student.attendance))),
                ],
              ),
            ],
          ),
        ).animate(delay: 50.ms).fadeIn(),

        const SizedBox(height: 12),

        // Monthly records
        ...student.monthlyAttendance.asMap().entries.map((e) {
          final m = e.value;
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(m.month, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      StatusBadge(label: '${m.pct}%', color: _attColor(m.pct)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: m.pct / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(_attColor(m.pct)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _AttBadge('Present', m.present, AppColors.success),
                      const SizedBox(width: 8),
                      _AttBadge('Absent', m.absent, AppColors.error),
                      const SizedBox(width: 8),
                      _AttBadge('Late', m.late, AppColors.warning),
                    ],
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 100 + i * 70)).fadeIn().slideY(begin: 0.05);
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Color _attColor(int pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  String _attLabel(int pct) {
    if (pct >= 90) return 'Excellent attendance';
    if (pct >= 75) return 'Good attendance';
    if (pct >= 60) return 'Below average';
    return 'Critical — needs attention';
  }
}

class _AttBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AttBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ],
  );
}

// ── Results Tab ───────────────────────────────────────────────────────────────

class _ResultsTab extends StatelessWidget {
  final _StudentDetail student;
  const _ResultsTab({required this.student});

  @override
  Widget build(BuildContext context) {
    final avg = student.results.isEmpty ? 0 : student.results.map((r) => r.marks).reduce((a, b) => a + b) ~/ student.results.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          gradient: AppColors.primaryGradient,
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Average Score', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text('$avg / 100', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(_gradeLabel(avg), style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ).animate(delay: 50.ms).fadeIn(),

        const SizedBox(height: 12),

        ...student.results.asMap().entries.map((e) {
          final r = e.value;
          final i = e.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _gradeColor(r.grade).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(r.grade, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _gradeColor(r.grade))),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: r.marks / 100,
                            minHeight: 5,
                            backgroundColor: AppColors.surface3,
                            valueColor: AlwaysStoppedAnimation<Color>(_gradeColor(r.grade)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${r.marks}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 100 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Color _gradeColor(String grade) {
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.primary;
    if (grade.startsWith('C')) return AppColors.warning;
    return AppColors.error;
  }

  String _gradeLabel(int avg) {
    if (avg >= 80) return 'Distinction';
    if (avg >= 70) return 'Credit';
    if (avg >= 50) return 'Pass';
    return 'Fail';
  }
}
