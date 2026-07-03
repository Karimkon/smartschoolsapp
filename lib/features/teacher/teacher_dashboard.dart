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
  if (res.data is! Map) throw Exception('Unexpected response format');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
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
                        dashAsync.when(
                          loading: () => _buildHeader(user, false),
                          error:   (_, __) => _buildHeader(user, false),
                          data:    (d) => _buildHeader(user,
                            (d['stats'] as Map?)?['is_class_teacher'] == true),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 24),
                        dashAsync.when(
                          loading: () => _statsShimmer(),
                          error:   (e, _) => _buildError(ref, e),
                          data:    (d) => _buildStats(context, d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _buildQuickActions(context, false),
                          error:   (_, __) => _buildQuickActions(context, false),
                          data:    (d) => _buildQuickActions(context,
                            (d['stats'] as Map?)?['is_class_teacher'] == true),
                        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: "Today's Lessons",
                          action: 'Timetable',
                          onAction: () => context.push('/teacher/timetable'),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error:   (_, __) => _listShimmer(),
                          data:    (d) => _buildLessons(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Upcoming Events',
                          action: 'View All',
                          onAction: () => context.push('/teacher/assignments'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(count: 3),
                          error:   (_, __) => _listShimmer(count: 3),
                          data:    (d) => _buildEvents(d),
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

  Widget _buildHeader(user, bool isClassTeacher) {
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
              const SizedBox(height: 6),
              Row(
                children: [
                  StatusBadge(label: 'Teacher', color: AppColors.roleTeacher),
                  if (isClassTeacher) ...[
                    const SizedBox(width: 6),
                    StatusBadge(label: 'Class Teacher', color: AppColors.success),
                  ],
                ],
              ),
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

  Widget _buildError(WidgetRef ref, Object e) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
      const SizedBox(height: 12),
      const Text('Could not load dashboard',
          style: TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => ref.invalidate(teacherDashboardProvider),
        child: const Text('Retry'),
      ),
    ]),
  );

  Widget _buildStats(BuildContext context, Map<String, dynamic> d) {
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
        StatCard(label: 'My Classes',      value: '$classes',     icon: Icons.class_rounded,       color: AppColors.roleTeacher, index: 0,
            onTap: () => context.push('/teacher/my-classes')),
        StatCard(label: 'My Students',     value: '$students',    icon: Icons.people_alt_rounded,  color: AppColors.primary,     index: 1,
            onTap: () => context.push('/teacher/students')),
        StatCard(label: 'Assignments',     value: '$assignments', icon: Icons.assignment_rounded,  color: AppColors.warning,     index: 2,
            onTap: () => context.push('/teacher/assignments')),
        StatCard(label: "Today's Lessons", value: '$today',       icon: Icons.today_rounded,       color: AppColors.success,     index: 3,
            onTap: () => context.push('/teacher/timetable')),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isClassTeacher) {
    final actions = [
      _QuickAction('Daily\nAttendance', Icons.how_to_reg_rounded,  AppColors.success,       '/teacher/attendance'),
      _QuickAction('Lesson\nAttendance',Icons.menu_book_rounded,   AppColors.roleTeacher,   '/teacher/lesson-attendance'),
      _QuickAction('Enter\nMarks',      Icons.edit_note_rounded,   AppColors.roleAccountant,'/teacher/marks'),
      if (isClassTeacher)
        _QuickAction('Report\nCards',   Icons.description_rounded, AppColors.primary,       '/teacher/report-cards')
      else
        _QuickAction('My Classes',      Icons.grid_view_rounded,   AppColors.primary,       '/teacher/my-classes'),
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

        final now = DateTime.now();
        bool isNow = false, isPast = false;
        final startParts = start.split(':');
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
                  StatusBadge(label: 'Soon', color: AppColors.primary),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 300 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  // ── Upcoming Events (replaced Upcoming Assignments) ───────────────────────

  Widget _buildEvents(Map<String, dynamic> d) {
    final raw = (d['upcoming_events'] as List?) ?? [];
    if (raw.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.event_rounded, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No upcoming events', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 400.ms).fadeIn();
    }

    final colors = [AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.warning, AppColors.success];

    return Column(
      children: raw.take(5).toList().asMap().entries.map((e) {
        final ev    = e.value as Map;
        final idx   = e.key;
        final color = colors[idx % colors.length];
        final title = ev['title']?.toString() ?? 'Event';
        final start = ev['start_date']?.toString() ?? '';
        final end   = ev['end_date']?.toString() ?? '';
        final dateStr = start.isNotEmpty ? _fmtEventDate(start, end) : 'Date TBD';

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(dateStr, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  width: 4, height: 36,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
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
      return '$h:$m\n$suffix';
    } catch (_) { return t; }
  }

  String _fmtEventDate(String start, String end) {
    try {
      final s   = DateTime.parse(start);
      final now = DateTime.now();
      final diff = s.difference(DateTime(now.year, now.month, now.day)).inDays;
      String label;
      if (diff == 0)      label = 'Today';
      else if (diff == 1) label = 'Tomorrow';
      else if (diff < 7)  label = 'In $diff days';
      else                label = '${s.day}/${s.month}/${s.year}';
      if (end.isNotEmpty && end != start) {
        try {
          final e = DateTime.parse(end);
          if (e.day != s.day || e.month != s.month) {
            label += ' → ${e.day}/${e.month}';
          }
        } catch (_) {}
      }
      return label;
    } catch (_) { return start; }
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
