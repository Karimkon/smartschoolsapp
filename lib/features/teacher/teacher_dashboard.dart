import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final teacherDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleTeacher,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(teacherDashboardProvider),
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
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context)
                            .animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: "Today's Lessons",
                          action: 'Timetable',
                          onAction: () => context.push('/teacher/timetable'),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildLessons(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Upcoming Assignments',
                          action: 'View All',
                          onAction: () => context.push('/teacher/assignments'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(count: 3),
                          error: (_, __) => _listShimmer(count: 3),
                          data: (d) => _buildAssignments(d),
                        ),
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
    final name     = user?.name ?? 'Teacher';
    final initials = user?.initials ?? 'T';
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
              StatusBadge(label: 'Teacher', color: AppColors.roleTeacher),
            ],
          ),
        ),
        AvatarWidget(initials: initials, color: AppColors.roleTeacher, size: 52),
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
    children: List.generate(count, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 72),
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
          onPressed: () => ref.invalidate(teacherDashboardProvider),
          child: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildStats(Map<String, dynamic> d) {
    final stats       = d['stats'] as Map? ?? {};
    final classes     = stats['classes']     as int? ?? 0;
    final students    = stats['students']    as int? ?? 0;
    final assignments = stats['assignments'] as int? ?? 0;
    final today       = (d['today_lessons'] as List?)?.length ?? 0;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'My Classes', value: '$classes', icon: Icons.class_rounded, color: AppColors.roleTeacher, index: 0),
        StatCard(label: 'Students', value: '$students', icon: Icons.people_alt_rounded, color: AppColors.primary, index: 1),
        StatCard(label: 'Assignments', value: '$assignments', icon: Icons.assignment_rounded, color: AppColors.warning, index: 2),
        StatCard(label: "Today's Lessons", value: '$today', icon: Icons.today_rounded, color: AppColors.success, index: 3),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Mark\nAttendance', Icons.how_to_reg_rounded, AppColors.success, '/teacher/attendance'),
      _QuickAction('New\nAssignment', Icons.add_task_rounded, AppColors.roleTeacher, '/teacher/assignments'),
      _QuickAction('Timetable', Icons.calendar_month_rounded, AppColors.primary, '/teacher/timetable'),
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

  Widget _buildLessons(Map<String, dynamic> d) {
    final lessons = (d['today_lessons'] as List?) ?? [];
    if (lessons.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.event_available_rounded, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No lessons scheduled for today', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 300.ms).fadeIn();
    }

    return Column(
      children: lessons.asMap().entries.map((e) {
        final lesson  = e.value as Map;
        final idx     = e.key;
        final subject = lesson['subject_name']?.toString() ?? 'Unknown';
        final cls     = lesson['class_name']?.toString() ?? '';
        final start   = lesson['start_time']?.toString() ?? '';
        final end     = lesson['end_time']?.toString() ?? '';
        final timeStr = start.isNotEmpty ? _fmtTime(start) : '—';

        final now         = DateTime.now();
        final startParts  = start.split(':');
        bool isNow = false;
        bool isPast = false;
        if (startParts.length >= 2) {
          try {
            final sh = int.parse(startParts[0]);
            final sm = int.parse(startParts[1]);
            final lessonStart = DateTime(now.year, now.month, now.day, sh, sm);
            final endParts = end.split(':');
            final eh = endParts.length >= 2 ? int.tryParse(endParts[0]) ?? sh + 1 : sh + 1;
            final em = endParts.length >= 2 ? int.tryParse(endParts[1]) ?? 0 : 0;
            final lessonEnd = DateTime(now.year, now.month, now.day, eh, em);
            isNow  = now.isAfter(lessonStart) && now.isBefore(lessonEnd);
            isPast = now.isAfter(lessonEnd);
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: isNow ? AppColors.roleTeacher.withOpacity(0.2) : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(timeStr, style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: isNow ? AppColors.roleTeacher : AppColors.textSecondary,
                    )),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      if (cls.isNotEmpty)
                        Text(cls, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (isNow)
                  StatusBadge(label: 'Now', color: AppColors.success)
                else if (isPast)
                  StatusBadge(label: 'Done', color: AppColors.textHint)
                else
                  StatusBadge(label: 'Upcoming', color: AppColors.primary),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 300 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildAssignments(Map<String, dynamic> d) {
    final raw = (d['upcoming_assignments'] as List?) ?? [];
    if (raw.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.assignment_turned_in_rounded, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No upcoming assignments', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 400.ms).fadeIn();
    }

    final colors = [AppColors.roleTeacher, AppColors.accent, AppColors.primary, AppColors.warning, AppColors.success];

    return Column(
      children: raw.take(5).toList().asMap().entries.map((e) {
        final a    = e.value as Map;
        final idx  = e.key;
        final color = colors[idx % colors.length];
        final title   = a['title']?.toString() ?? 'Assignment';
        final subject = a['subject_name']?.toString() ?? a['subject']?.toString() ?? '';
        final due     = a['due_date']?.toString() ?? '';
        final dueStr  = due.isNotEmpty ? _fmtDate(due) : 'No due date';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 4, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      if (subject.isNotEmpty)
                        Text(subject, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                StatusBadge(label: dueStr, color: color),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  String _fmtTime(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) { return t; }
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      final now = DateTime.now();
      final diff = dt.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff == 0) return 'Today';
      if (diff == 1) return 'Tomorrow';
      if (diff < 7)  return 'In $diff days';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return d; }
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
