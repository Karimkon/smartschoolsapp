import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class StudentDashboardData {
  final String currentTerm;
  final String gpa;
  final double feesBalance;
  final double attendancePercent;
  final List<ExamScore> examScores;
  final List<TimetablePeriod> todayTimetable;
  final List<UpcomingAssignment> assignments;

  const StudentDashboardData({
    required this.currentTerm,
    required this.gpa,
    required this.feesBalance,
    required this.attendancePercent,
    required this.examScores,
    required this.todayTimetable,
    required this.assignments,
  });
}

class ExamScore {
  final String subject;
  final double score;
  const ExamScore(this.subject, this.score);
}

class TimetablePeriod {
  final String period;
  final String time;
  final String subject;
  final String teacher;
  const TimetablePeriod(this.period, this.time, this.subject, this.teacher);
}

class UpcomingAssignment {
  final String subject;
  final String title;
  final String dueDate;
  final Color color;
  const UpcomingAssignment(this.subject, this.title, this.dueDate, this.color);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final studentDashboardProvider = FutureProvider<StudentDashboardData>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const StudentDashboardData(
      currentTerm: 'Term 2 / 2025',
      gpa: 'B+ (78%)',
      feesBalance: 12500.00,
      attendancePercent: 91.3,
      examScores: [
        ExamScore('Math', 82),
        ExamScore('English', 76),
        ExamScore('Science', 88),
        ExamScore('History', 71),
        ExamScore('Kiswahili', 79),
      ],
      todayTimetable: [
        TimetablePeriod('Period 1', '07:30 – 08:20', 'Mathematics', 'Mr. Ochieng'),
        TimetablePeriod('Period 2', '08:20 – 09:10', 'English', 'Ms. Wanjiku'),
        TimetablePeriod('Period 3', '09:30 – 10:20', 'Science', 'Mr. Kariuki'),
        TimetablePeriod('Period 4', '10:20 – 11:10', 'History', 'Ms. Auma'),
        TimetablePeriod('Period 5', '13:00 – 13:50', 'Kiswahili', 'Mr. Mwangi'),
      ],
      assignments: [
        UpcomingAssignment('Mathematics', 'Algebra Problem Set 4', 'Due Tomorrow', AppColors.roleTeacher),
        UpcomingAssignment('Science', 'Lab Report: Osmosis', 'Due in 3 days', AppColors.accent),
        UpcomingAssignment('English', 'Essay: Climate Change', 'Due in 5 days', AppColors.primary),
      ],
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
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
                          error: (_, __) => _statsShimmer(),
                          data: (d) => _buildStats(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Exam Performance',
                          action: 'View All',
                          onAction: () => context.push('/student/results'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 220),
                          error: (_, __) => const ShimmerCard(height: 220),
                          data: (d) => _buildExamChart(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: "Today's Timetable",
                          action: 'Full Schedule',
                          onAction: () => context.push('/student/timetable'),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildTimetable(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Upcoming Assignments',
                          action: 'All Tasks',
                          onAction: () => context.push('/student/assignments'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(count: 2),
                          error: (_, __) => _listShimmer(count: 2),
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
    final name = user?.name ?? 'Student';
    final initials = user?.initials ?? 'S';
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
        AvatarWidget(initials: initials, color: AppColors.roleStudent, size: 52),
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

  Widget _listShimmer({int count = 3}) => Column(
    children: List.generate(count, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 68),
    )),
  );

  Widget _buildStats(StudentDashboardData d) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Current Term', value: 'Term 2', icon: Icons.calendar_today_rounded, color: AppColors.roleStudent, index: 0),
        StatCard(label: 'Grade / GPA', value: d.gpa, icon: Icons.school_rounded, color: AppColors.primary, index: 1),
        StatCard(label: 'Fees Balance', value: 'KES ${d.feesBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AppColors.warning, subtitle: 'Pending', index: 2),
        StatCard(label: 'Attendance', value: '${d.attendancePercent}%', icon: Icons.bar_chart_rounded, color: AppColors.success, index: 3),
      ],
    );
  }

  Widget _buildExamChart(StudentDashboardData d) {
    final spots = d.examScores.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.score))
        .toList();

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (d.examScores.length - 1).toDouble(),
            minY: 50,
            maxY: 100,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                  '${d.examScores[s.x.toInt()].subject}\n${s.y.toStringAsFixed(0)}%',
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                )).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= d.examScores.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(d.examScores[i].subject.substring(0, 3),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) {
                    if (v % 25 != 0) return const SizedBox();
                    return Text('${v.toInt()}', style: const TextStyle(color: AppColors.textHint, fontSize: 10));
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
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppColors.roleStudent, AppColors.primary],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.roleStudent,
                    strokeWidth: 2,
                    strokeColor: AppColors.bgDark,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [AppColors.roleStudent.withOpacity(0.2), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimetable(StudentDashboardData d) {
    return Column(
      children: d.todayTimetable.asMap().entries.map((e) {
        final p = e.value;
        final idx = e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.roleStudent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('P${idx + 1}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.roleStudent)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(p.teacher, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Text(p.time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 300 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  Widget _buildAssignments(StudentDashboardData d) {
    return Column(
      children: d.assignments.asMap().entries.map((e) {
        final a = e.value;
        final idx = e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: a.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(a.subject, style: TextStyle(fontSize: 11, color: a.color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                StatusBadge(
                  label: a.dueDate,
                  color: a.dueDate.contains('Tomorrow') ? AppColors.warning : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}
