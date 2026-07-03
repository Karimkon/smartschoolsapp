import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _selectedMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

final _attendanceTrendProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, month) async {
  final res = await ApiService().get('/attendance/report', params: {'month': month});
  return (res.data as List?) ?? [];
});

final _classSummaryProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, month) async {
  final res = await ApiService().get('/attendance/class-summary', params: {'month': month});
  return (res.data as List?) ?? [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AttendanceReportsScreen extends ConsumerWidget {
  const AttendanceReportsScreen({super.key});

  Color _pctColor(int pct) =>
      pct >= 90 ? AppColors.success : pct >= 75 ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month      = ref.watch(_selectedMonthProvider);
    final trendAsync = ref.watch(_attendanceTrendProvider(month));
    final classAsync = ref.watch(_classSummaryProvider(month));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Attendance Reports',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.refresh(_attendanceTrendProvider(month));
              ref.refresh(_classSummaryProvider(month));
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: trendAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(4, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: ShimmerCard(height: 120),
            )),
          ),
          error: (e, _) => Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
              const SizedBox(height: 12),
              const Text('Could not load reports', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(_attendanceTrendProvider(month)),
                child: const Text('Retry'),
              ),
            ],
          )),
          data: (trend) {
            // Compute summary stats from trend data
            final avgPct = trend.isEmpty
                ? 0
                : (trend.map((d) => toD((d as Map)['pct'])).reduce((a, b) => a + b) /
                    trend.length).round();
            final totalPresent = trend.fold<int>(0, (s, d) => s + toI((d as Map)['present']));
            final totalAbsent  = trend.fold<int>(0, (s, d) => s + (toD((d as Map)['total']) - toD((d as Map)['present'])).toInt());

            // Last 7 days for chart
            final chartData = trend.length > 7 ? trend.sublist(trend.length - 7) : trend;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                // Month picker
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    const Text('Month:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MonthPicker(
                        value: month,
                        onChanged: (v) => ref.read(_selectedMonthProvider.notifier).state = v,
                      ),
                    ),
                  ]),
                ).animate().fadeIn(),
                const SizedBox(height: 16),

                // Summary cards
                Row(children: [
                  Expanded(child: StatCard(
                    label: 'Avg Attendance', value: '$avgPct%',
                    icon: Icons.trending_up_rounded, color: _pctColor(avgPct), index: 0,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    label: 'Days Recorded', value: '${trend.length}',
                    icon: Icons.date_range_rounded, color: AppColors.primary, index: 1,
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: StatCard(
                    label: 'Total Present', value: '$totalPresent',
                    icon: Icons.check_circle_rounded, color: AppColors.success, index: 2,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatCard(
                    label: 'Total Absent', value: '$totalAbsent',
                    icon: Icons.person_off_rounded, color: AppColors.error, index: 3,
                  )),
                ]),
                const SizedBox(height: 20),

                // Daily trend chart
                if (chartData.isNotEmpty)
                  GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SectionHeader(title: 'Attendance Trend (Last 7 Days)'),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 24,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= chartData.length) return const SizedBox();
                              final date = (chartData[i] as Map)['date']?.toString() ?? '';
                              final day = date.length >= 10 ? date.substring(8, 10) : '';
                              return Text(day, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary));
                            },
                          )),
                          leftTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 34,
                            getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          )),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true, drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.surface3, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: chartData.asMap().entries.map((e) {
                          final pct = toD((e.value as Map)['pct']);
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [BarChartRodData(
                              toY: pct,
                              gradient: LinearGradient(
                                colors: pct >= 90
                                    ? [AppColors.success, const Color(0xFF34D399)]
                                    : pct >= 75
                                        ? [AppColors.warning, const Color(0xFFFBBF24)]
                                        : [AppColors.error, const Color(0xFFF87171)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              width: 28,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            )],
                          );
                        }).toList(),
                      )),
                    ),
                  ])).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Per-class breakdown
                classAsync.when(
                  loading: () => const ShimmerCard(height: 200),
                  error: (_, __) => const SizedBox(),
                  data: (classes) {
                    if (classes.isEmpty) return const SizedBox();
                    return GlassCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: 'Attendance by Class'),
                        const SizedBox(height: 12),
                        ...classes.asMap().entries.map((e) {
                          final c   = e.value as Map;
                          final pct = toI(c['pct']);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(c['class_name']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                                Text('$pct%', style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800, color: _pctColor(pct))),
                              ]),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100,
                                  backgroundColor: AppColors.surface3,
                                  valueColor: AlwaysStoppedAnimation(_pctColor(pct)),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(children: [
                                _StatChip('P: ${c["present"]}', AppColors.success),
                                const SizedBox(width: 6),
                                _StatChip('A: ${c["absent"]}', AppColors.error),
                                if (toI(c['late']) > 0) ...[
                                  const SizedBox(width: 6),
                                  _StatChip('L: ${c["late"]}', AppColors.warning),
                                ],
                              ]),
                            ]),
                          ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn();
                        }),
                      ],
                    )).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
                  },
                ),

                if (trend.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(children: [
                      const Icon(Icons.bar_chart_rounded, color: AppColors.textHint, size: 52),
                      const SizedBox(height: 12),
                      const Text('No attendance data for this month',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ]),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Month Picker ──────────────────────────────────────────────────────────────

class _MonthPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _MonthPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now    = DateTime.now();
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - i);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    });
    final labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: months.contains(value) ? value : months.first,
        dropdownColor: AppColors.surface2,
        isExpanded: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
        items: months.map((m) {
          final parts = m.split('-');
          final label = '${labels[int.parse(parts[1]) - 1]} ${parts[0]}';
          return DropdownMenuItem(value: m, child: Text(label));
        }).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
