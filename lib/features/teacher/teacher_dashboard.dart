import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class TeacherDashboardData {
  final int myClasses;
  final int totalStudents;
  final int pendingAssignments;
  final double avgAttendance;
  final List<ClassAttendance> classAttendances;
  final List<TodayLesson> todayLessons;

  const TeacherDashboardData({
    required this.myClasses,
    required this.totalStudents,
    required this.pendingAssignments,
    required this.avgAttendance,
    required this.classAttendances,
    required this.todayLessons,
  });
}

class ClassAttendance {
  final String className;
  final double percentage;
  const ClassAttendance(this.className, this.percentage);
}

class TodayLesson {
  final String time;
  final String className;
  final String subject;
  final String room;
  const TodayLesson(this.time, this.className, this.subject, this.room);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final teacherDashboardProvider = FutureProvider<TeacherDashboardData>((ref) async {
  try {
    // TODO: replace with real API call
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const TeacherDashboardData(
      myClasses: 5,
      totalStudents: 142,
      pendingAssignments: 8,
      avgAttendance: 87.4,
      classAttendances: [
        ClassAttendance('Form 1A', 92.0),
        ClassAttendance('Form 2B', 85.5),
        ClassAttendance('Form 3A', 88.0),
        ClassAttendance('Form 3C', 79.5),
        ClassAttendance('Form 4B', 93.0),
      ],
      todayLessons: [
        TodayLesson('07:30', 'Form 1A', 'Mathematics', 'Room 101'),
        TodayLesson('09:00', 'Form 3A', 'Mathematics', 'Room 101'),
        TodayLesson('10:30', 'Form 2B', 'Mathematics', 'Room 103'),
        TodayLesson('13:00', 'Form 4B', 'Advanced Math', 'Room 101'),
        TodayLesson('14:30', 'Form 3C', 'Mathematics', 'Lab 2'),
      ],
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
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
                        // ── Header ──────────────────────────────────────────
                        _buildHeader(user).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 24),

                        // ── Stats ────────────────────────────────────────────
                        dashAsync.when(
                          loading: () => _buildStatsShimmer(),
                          error: (_, __) => _buildStatsShimmer(),
                          data: (data) => _buildStats(data),
                        ),
                        const SizedBox(height: 24),

                        // ── Chart ────────────────────────────────────────────
                        SectionHeader(
                          title: 'Attendance by Class',
                          action: 'Full Report',
                          onAction: () => context.push('/teacher/attendance'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 220),
                          error: (_, __) => const ShimmerCard(height: 220),
                          data: (data) => _buildAttendanceChart(data),
                        ),
                        const SizedBox(height: 24),

                        // ── Quick Actions ────────────────────────────────────
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context)
                            .animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),

                        // ── Today's Lessons ──────────────────────────────────
                        SectionHeader(
                          title: "Today's Lessons",
                          action: 'Timetable',
                          onAction: () => context.push('/teacher/timetable'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _buildLessonsShimmer(),
                          error: (_, __) => _buildLessonsShimmer(),
                          data: (data) => _buildLessonsList(data),
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
    final name = user?.name ?? 'Teacher';
    final initials = user?.initials ?? 'T';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
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
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildStatsShimmer() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (_) => const ShimmerCard()),
    );
  }

  Widget _buildStats(TeacherDashboardData data) {
    final stats = [
      _StatItem('My Classes', '${data.myClasses}', Icons.class_rounded, AppColors.roleTeacher, null, 0),
      _StatItem('Students', '${data.totalStudents}', Icons.people_alt_rounded, AppColors.primary, null, 1),
      _StatItem('Assignments', '${data.pendingAssignments}', Icons.assignment_late_rounded, AppColors.warning, 'Pending', 2),
      _StatItem('Avg Attendance', '${data.avgAttendance}%', Icons.bar_chart_rounded, AppColors.success, null, 3),
    ];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: stats.map((s) => StatCard(
        label: s.label,
        value: s.value,
        icon: s.icon,
        color: s.color,
        subtitle: s.subtitle,
        index: s.index,
      )).toList(),
    );
  }

  Widget _buildAttendanceChart(TeacherDashboardData data) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${data.classAttendances[group.x].className}\n',
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(1)}%',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.classAttendances.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data.classAttendances[idx].className.replaceAll('Form ', 'F'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    if (value % 25 != 0) return const SizedBox();
                    return Text('${value.toInt()}%', style: const TextStyle(color: AppColors.textHint, fontSize: 10));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.classAttendances.asMap().entries.map((e) {
              final isHigh = e.value.percentage >= 90;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.percentage,
                  gradient: LinearGradient(
                    colors: isHigh
                        ? [AppColors.success, AppColors.accent]
                        : [AppColors.roleTeacher, AppColors.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Mark\nAttendance', Icons.how_to_reg_rounded, AppColors.success, '/teacher/attendance'),
      _QuickAction('New\nAssignment', Icons.add_task_rounded, AppColors.roleTeacher, '/teacher/assignments/new'),
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
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildLessonsShimmer() {
    return Column(
      children: List.generate(3, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ShimmerCard(height: 72),
      )),
    );
  }

  Widget _buildLessonsList(TeacherDashboardData data) {
    return Column(
      children: data.todayLessons.asMap().entries.map((e) {
        final lesson = e.value;
        final idx = e.key;
        final now = DateTime.now();
        final lessonHour = int.tryParse(lesson.time.split(':')[0]) ?? 0;
        final lessonMin = int.tryParse(lesson.time.split(':')[1]) ?? 0;
        final lessonTime = DateTime(now.year, now.month, now.day, lessonHour, lessonMin);
        final isNow = now.isAfter(lessonTime) && now.isBefore(lessonTime.add(const Duration(minutes: 90)));
        final isPast = now.isAfter(lessonTime.add(const Duration(minutes: 90)));

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.roleTeacher.withOpacity(0.2)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      lesson.time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isNow ? AppColors.roleTeacher : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text('${lesson.className} • ${lesson.room}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final int index;
  const _StatItem(this.label, this.value, this.icon, this.color, this.subtitle, this.index);
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
