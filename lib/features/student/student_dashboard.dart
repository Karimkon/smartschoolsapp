import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final studentDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(studentDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleStudent,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(studentDashboardProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(user).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 24),
                        dashAsync.when(
                          loading: () => _statsShimmer(),
                          error: (e, _) => _buildError(ref, e),
                          data: (d) => _buildStats(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: "Today's Timetable",
                          action: 'Full Schedule',
                          onAction: () => context.push('/student/timetable'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildTimetable(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Quick Access',
                          action: 'View All',
                          onAction: () => context.push('/student/results'),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    final name     = user?.name ?? 'Student';
    final initials = user?.initials ?? 'S';
    final avatar   = user?.avatar;
    final photoUrl = avatar != null && avatar.isNotEmpty
        ? (avatar.startsWith('http') ? avatar : 'https://smartschoolshub.com/storage/$avatar')
        : null;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              StatusBadge(label: 'Student', color: AppColors.roleStudent),
            ],
          ),
        ),
        AvatarWidget(imageUrl: photoUrl, initials: initials, color: AppColors.roleStudent, size: 52),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _statsShimmer() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.4,
    physics: const NeverScrollableScrollPhysics(),
    children: List.generate(4, (_) => const ShimmerCard()),
  );

  Widget _listShimmer({int count = 4}) => Column(
    children: List.generate(count, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 68),
    )),
  );

  Widget _buildError(WidgetRef ref, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(studentDashboardProvider),
          child: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildStats(Map<String, dynamic> d) {
    final student    = d['student'] as Map? ?? {};
    final feeBalance = toD(d['fee_balance'], 0);
    final className  = student['class_name']?.toString() ?? '—';
    final admNo      = student['admission_number']?.toString() ?? '—';
    final timetable  = (d['timetable'] as List?) ?? [];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Class', value: className, icon: Icons.class_rounded, color: AppColors.roleStudent, index: 0),
        StatCard(label: 'Admission No', value: admNo, icon: Icons.badge_rounded, color: AppColors.primary, index: 1),
        StatCard(
          label: 'Fees Balance',
          value: feeBalance > 0 ? 'UGX ${_fmt(feeBalance)}' : 'Cleared',
          icon: Icons.account_balance_wallet_rounded,
          color: feeBalance > 0 ? AppColors.warning : AppColors.success,
          subtitle: feeBalance > 0 ? 'Due' : null,
          index: 2,
        ),
        StatCard(
          label: "Today's Lessons",
          value: '${timetable.length}',
          icon: Icons.schedule_rounded,
          color: AppColors.accent,
          index: 3,
        ),
      ],
    );
  }

  Widget _buildTimetable(Map<String, dynamic> d) {
    final timetable = (d['timetable'] as List?) ?? [];
    if (timetable.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.event_available_rounded, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No lessons scheduled for today', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 200.ms).fadeIn();
    }

    return Column(
      children: timetable.asMap().entries.map((e) {
        final slot    = e.value as Map;
        final idx     = e.key;
        final subject = slot['subject_name']?.toString() ?? 'Unknown Subject';
        final teacher = slot['teacher_name']?.toString() ?? '';
        final start   = slot['start_time']?.toString() ?? '';
        final end     = slot['end_time']?.toString() ?? '';
        final timeStr = start.isNotEmpty ? '${_fmtTime(start)}${end.isNotEmpty ? ' – ${_fmtTime(end)}' : ''}' : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.roleStudent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${idx + 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.roleStudent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      if (teacher.isNotEmpty)
                        Text(teacher, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 200 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Results', Icons.bar_chart_rounded, AppColors.primary, '/student/results'),
      _QuickAction('Fees', Icons.account_balance_wallet_rounded, AppColors.warning, '/student/fees'),
      _QuickAction('Timetable', Icons.calendar_month_rounded, AppColors.roleStudent, '/student/timetable'),
    ];
    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
          child: GlassCard(
            onTap: () => context.push(a.route),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(a.icon, color: a.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(a.label, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtTime(String t) {
    // Format "HH:MM:SS" or "HH:MM" to "H:MM AM/PM"
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) {
      return t;
    }
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
