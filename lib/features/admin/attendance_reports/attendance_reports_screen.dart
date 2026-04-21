import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class AttendanceReportsScreen extends StatefulWidget {
  const AttendanceReportsScreen({super.key});
  @override State<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends State<AttendanceReportsScreen> {
  String _period = 'This Month';
  String _class = 'All Classes';

  final _periods = ['Today', 'This Week', 'This Month', 'This Term'];
  final _classes = ['All Classes', 'Grade 7A', 'Grade 7B', 'Grade 8A', 'Grade 8B', 'Grade 9A'];

  final _weekData = [88.0, 91.0, 94.0, 87.0, 92.0];
  final _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  final _classStats = [
    {'class': 'Grade 7A', 'present': 33, 'absent': 2, 'late': 0, 'pct': 94},
    {'class': 'Grade 7B', 'present': 30, 'absent': 3, 'late': 0, 'pct': 91},
    {'class': 'Grade 8A', 'present': 36, 'absent': 2, 'late': 0, 'pct': 95},
    {'class': 'Grade 8B', 'present': 28, 'absent': 5, 'late': 0, 'pct': 85},
    {'class': 'Grade 9A', 'present': 34, 'absent': 2, 'late': 0, 'pct': 94},
    {'class': 'Grade 9B', 'present': 29, 'absent': 3, 'late': 0, 'pct': 91},
  ];

  Color _pctColor(int pct) => pct >= 90 ? AppColors.success : pct >= 75 ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Attendance Reports', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.download_rounded, color: AppColors.primary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Filters
            Row(children: [
              Expanded(child: _FilterDropdown(_periods, _period, (v) => setState(() => _period = v))),
              const SizedBox(width: 10),
              Expanded(child: _FilterDropdown(_classes, _class, (v) => setState(() => _class = v))),
            ]).animate().fadeIn(),
            const SizedBox(height: 16),

            // Summary stats
            Row(children: [
              Expanded(child: StatCard(label: 'School Avg', value: '92%', icon: Icons.trending_up_rounded, color: AppColors.success, index: 0)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Absent Today', value: '47', icon: Icons.person_off_rounded, color: AppColors.error, index: 1)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(label: 'Perfect Att.', value: '128', icon: Icons.star_rounded, color: AppColors.warning, index: 2)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'At Risk', value: '23', icon: Icons.warning_rounded, color: AppColors.accent, index: 3)),
            ]),
            const SizedBox(height: 20),

            // Weekly attendance chart
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Weekly Attendance Trend'),
              const SizedBox(height: 20),
              SizedBox(height: 180,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                      getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= _daysOfWeek.length) return const SizedBox(); return Text(_daysOfWeek[i], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)); })),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 34,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textHint)))),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppColors.surface3, strokeWidth: 1)),
                  borderData: FlBorderData(show: false),
                  barGroups: _weekData.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: e.value,
                      gradient: e.value >= 90 ? const LinearGradient(colors: [AppColors.success, Color(0xFF34D399)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                          : const LinearGradient(colors: [AppColors.warning, Color(0xFFFBBF24)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      width: 30, borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    )],
                  )).toList(),
                )),
              ),
            ])).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // Per-class breakdown
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionHeader(title: 'Attendance by Class'),
              const SizedBox(height: 12),
              ..._classStats.asMap().entries.map((e) {
                final s = e.value;
                final pct = s['pct'] as int;
                return Padding(padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(s['class'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _pctColor(pct))),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(value: pct / 100, backgroundColor: AppColors.surface3, valueColor: AlwaysStoppedAnimation(_pctColor(pct)), minHeight: 6)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _StatChip('P: ${s["present"]}', AppColors.success),
                      const SizedBox(width: 8),
                      _StatChip('A: ${s["absent"]}', AppColors.error),
                    ]),
                  ]),
                );
              }),
            ])).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final List<String> items; final String value; final ValueChanged<String> onChanged;
  const _FilterDropdown(this.items, this.value, this.onChanged);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value, isExpanded: true, dropdownColor: AppColors.surface1,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 20),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );
}

class _StatChip extends StatelessWidget {
  final String label; final Color color;
  const _StatChip(this.label, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
