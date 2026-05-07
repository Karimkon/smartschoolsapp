import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final studentDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, id) async {
  final res = await ApiService().get('/students/$id');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const StudentDetailScreen({super.key, required this.id});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static const _colors = [
    AppColors.primary, AppColors.accent, AppColors.roleTeacher,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ];
  Color get _color => _colors[widget.id % _colors.length];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: async.when(
            loading: () => Column(children: [
              _backRow(context),
              const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            ]),
            error: (e, _) => Column(children: [
              _backRow(context),
              Expanded(child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                  const SizedBox(height: 12),
                  const Text('Could not load student', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(studentDetailProvider(widget.id)),
                    child: const Text('Retry'),
                  ),
                ]),
              )),
            ]),
            data: (data) {
              final s = data['student'] as Map<String, dynamic>;
              return NestedScrollView(
                headerSliverBuilder: (_, __) => [
                  SliverToBoxAdapter(child: _buildHeader(context, s, data)),
                  SliverToBoxAdapter(child: _buildTabBar()),
                ],
                body: TabBarView(
                  controller: _tabs,
                  children: [
                    _OverviewTab(student: s, data: data),
                    _AttendanceTab(data: data),
                    _ResultsTab(data: data),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _backRow(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
    child: Row(children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
    ]),
  );

  Widget _buildHeader(BuildContext context, Map<String, dynamic> s, Map<String, dynamic> data) {
    final name    = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    final admNo   = s['admission_number']?.toString() ?? '';
    final status  = s['status']?.toString() ?? 'active';
    final cls     = s['class_name']?.toString() ?? '';
    final section = s['section_name']?.toString() ?? '';
    final isActive = status.toLowerCase() == 'active';
    final initials = () {
      final p = name.trim().split(' ').where((x) => x.isNotEmpty).toList();
      return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name.isNotEmpty ? name[0].toUpperCase() : 'S';
    }();
    final photoUrl = s['photo_url']?.toString();

    final fee    = data['fee'] as Map? ?? {};
    final att    = data['attendance'] as Map? ?? {};
    final billed = (fee['billed'] as num?)?.toDouble() ?? 0;
    final paid   = (fee['paid']   as num?)?.toDouble() ?? 0;
    final balance = billed - paid;
    final attPct  = (att['pct'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
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
                onPressed: () => context.push('/admin/students/${widget.id}/edit'),
                tooltip: 'Edit student',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                onPressed: () => ref.refresh(studentDetailProvider(widget.id)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              AvatarWidget(imageUrl: photoUrl, initials: initials, color: _color, size: 80)
                  .animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 14),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary))
                  .animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(admNo, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  StatusBadge(label: isActive ? 'Active' : 'Inactive',
                      color: isActive ? AppColors.success : AppColors.error),
                ],
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 8),
              Text(
                [if (cls.isNotEmpty) cls, if (section.isNotEmpty) section].join('  •  '),
                style: const TextStyle(fontSize: 12, color: AppColors.textHint),
              ).animate(delay: 200.ms).fadeIn(),
            ],
          ),
        ),
        // Mini stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              Expanded(child: _MiniStat(label: 'Attendance', value: '$attPct%', color: _attColor(attPct), icon: Icons.bar_chart_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Balance', value: 'UGX ${_fmt(balance)}', color: AppColors.warning, icon: Icons.account_balance_wallet_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _MiniStat(label: 'Class', value: cls.isNotEmpty ? cls : '-', color: AppColors.primary, icon: Icons.class_rounded)),
            ],
          ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTabBar() => Container(
    color: AppColors.surface1,
    child: TabBar(
      controller: _tabs,
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      tabs: const [Tab(text: 'Overview'), Tab(text: 'Attendance'), Tab(text: 'Results')],
    ),
  );

  Color _attColor(int pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
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
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Map<String, dynamic> student, data;
  const _OverviewTab({required this.student, required this.data});

  String _v(String key) => student[key]?.toString().isNotEmpty == true ? student[key].toString() : '—';

  @override
  Widget build(BuildContext context) {
    final fee    = data['fee'] as Map? ?? {};
    final billed = (fee['billed'] as num?)?.toDouble() ?? 0;
    final paid   = (fee['paid']   as num?)?.toDouble() ?? 0;
    final balance = billed - paid;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoSection(
          title: 'Personal Details',
          icon: Icons.person_rounded,
          color: AppColors.primary,
          rows: [
            _InfoRow('Date of Birth', _v('date_of_birth')),
            _InfoRow('Gender',        _v('gender')),
            _InfoRow('Blood Group',   _v('blood_group')),
            _InfoRow('Religion',      _v('religion')),
            _InfoRow('Address',       _v('address')),
          ],
        ).animate(delay: 50.ms).fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Guardian Details',
          icon: Icons.family_restroom_rounded,
          color: AppColors.roleParent,
          rows: [
            _InfoRow('Guardian Name',     _v('guardian_name')),
            _InfoRow('Relation',          _v('guardian_relation')),
            _InfoRow('Guardian Phone',    _v('guardian_phone')),
            _InfoRow('Guardian Email',    _v('guardian_email')),
          ],
        ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),
        _InfoSection(
          title: 'Academic Information',
          icon: Icons.school_rounded,
          color: AppColors.accent,
          rows: [
            _InfoRow('Class',          _v('class_name')),
            _InfoRow('Section',        _v('section_name')),
            _InfoRow('Type',           _v('student_type')),
            _InfoRow('Admission No',   _v('admission_number')),
            _InfoRow('Admission Date', _v('admission_date')),
            _InfoRow('Roll No',        _v('roll_number')),
          ],
        ).animate(delay: 110.ms).fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.warning, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Fee Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
              const SizedBox(height: 16),
              _FeeStat('Total Billed',  'UGX ${_fmt(billed)}',  AppColors.textPrimary),
              const Divider(color: Colors.white12, height: 20),
              _FeeStat('Amount Paid',   'UGX ${_fmt(paid)}',    AppColors.success),
              const Divider(color: Colors.white12, height: 20),
              _FeeStat('Balance Due',   'UGX ${_fmt(balance)}', AppColors.warning),
              const SizedBox(height: 12),
              if (billed > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (paid / billed).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.surface3,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
                const SizedBox(height: 6),
                Text('${((paid / billed) * 100).toStringAsFixed(0)}% paid',
                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ],
          ),
        ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.05),
        const SizedBox(height: 80),
      ],
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Attendance Tab ────────────────────────────────────────────────────────────

class _AttendanceTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AttendanceTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final att     = data['attendance'] as Map? ?? {};
    final monthly = (data['monthly_attendance'] as List?) ?? [];
    final pct     = (att['pct'] as num?)?.toInt() ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: _attColor(pct).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$pct%',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _attColor(pct)))),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Overall Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(_attLabel(pct), style: TextStyle(fontSize: 12, color: _attColor(pct))),
              ]),
            ],
          ),
        ).animate(delay: 50.ms).fadeIn(),
        const SizedBox(height: 12),
        if (monthly.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No attendance records', style: TextStyle(color: AppColors.textHint))))
        else
          ...monthly.asMap().entries.map((e) {
            final m = e.value as Map;
            final i = e.key;
            final present = (m['present'] as num?)?.toInt() ?? 0;
            final absent  = (m['absent']  as num?)?.toInt() ?? 0;
            final late    = (m['late']    as num?)?.toInt() ?? 0;
            final total   = present + absent + late;
            final mpct    = total > 0 ? ((present / total) * 100).round() : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(m['month']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    StatusBadge(label: '$mpct%', color: _attColor(mpct)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: mpct / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.surface3,
                      valueColor: AlwaysStoppedAnimation<Color>(_attColor(mpct)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _AttBadge('Present', present, AppColors.success),
                    const SizedBox(width: 8),
                    _AttBadge('Absent', absent, AppColors.error),
                    const SizedBox(width: 8),
                    _AttBadge('Late', late, AppColors.warning),
                  ]),
                ]),
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
  final Map<String, dynamic> data;
  const _ResultsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    // Results come from report_cards joined with subjects (future API endpoint)
    // For now show placeholder pointing to full report section
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          gradient: AppColors.primaryGradient,
          child: Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 36),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Academic Results', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Full report cards are managed in the web admin portal. Tap Report Cards in the More section to view.',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ]),
              ),
            ],
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

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
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 14),
        ...rows.where((r) => r.value != '—').map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Expanded(flex: 2, child: Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(flex: 3, child: Text(r.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
          ]),
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
