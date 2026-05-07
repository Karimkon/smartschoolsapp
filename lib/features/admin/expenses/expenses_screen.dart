import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final expensesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/expenses');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
  return 'UGX ${v.toStringAsFixed(0)}';
}

Color _categoryColor(String cat) {
  switch (cat.toLowerCase()) {
    case 'utilities':   return AppColors.primary;
    case 'stationery':  return AppColors.accent;
    case 'maintenance': return AppColors.warning;
    case 'food':        return const Color(0xFFEC4899);
    case 'transport':   return const Color(0xFF7C3AED);
    case 'salaries':    return AppColors.roleTeacher;
    default:            return AppColors.textSecondary;
  }
}

IconData _categoryIcon(String cat) {
  switch (cat.toLowerCase()) {
    case 'utilities':   return Icons.bolt_rounded;
    case 'stationery':  return Icons.edit_rounded;
    case 'maintenance': return Icons.build_rounded;
    case 'food':        return Icons.restaurant_rounded;
    case 'transport':   return Icons.directions_bus_rounded;
    case 'salaries':    return Icons.payments_rounded;
    default:            return Icons.receipt_long_rounded;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});
  @override ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  int? _touchedPieIndex;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => context.pop(),
                ),
                const Expanded(
                  child: Text('Expenses',
                      style: TextStyle(color: AppColors.textPrimary,
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () => ref.invalidate(expensesProvider),
                ),
              ]),
            ),

            Expanded(
              child: async.when(
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: 6,
                  itemBuilder: (_, __) =>
                      const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerCard(height: 80)),
                ),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                    const SizedBox(height: 12),
                    const Text('Could not load expenses',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => ref.invalidate(expensesProvider),
                        child: const Text('Retry')),
                  ]),
                ),
                data: (data) {
                  final expenses    = (data['data'] as List?) ?? [];
                  final summary     = data['summary'] as Map? ?? {};
                  final thisMonth   = (summary['this_month'] as num?)?.toDouble() ?? 0;
                  final total       = (summary['total'] as num?)?.toDouble() ?? 0;
                  final pendingCount = expenses.where((e) =>
                      (e as Map)['status']?.toString().toLowerCase() == 'pending').length;

                  // Build category totals for chart
                  final catMap = <String, double>{};
                  for (final e in expenses) {
                    final m = e as Map;
                    if ((m['status']?.toString().toLowerCase() ?? '') != 'rejected') {
                      final cat = m['category']?.toString() ?? 'Other';
                      final amt = (m['amount'] as num?)?.toDouble() ?? 0;
                      catMap[cat] = (catMap[cat] ?? 0) + amt;
                    }
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () => ref.refresh(expensesProvider.future),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats row
                          Row(children: [
                            _StatCard('This Month', _fmt(thisMonth), AppColors.error, Icons.calendar_today_rounded, 0),
                            const SizedBox(width: 10),
                            _StatCard('All Time', _fmt(total), AppColors.primary, Icons.bar_chart_rounded, 1),
                          ]),
                          const SizedBox(height: 10),
                          Row(children: [
                            _StatCard('Total Records', '${expenses.length}', AppColors.accent, Icons.receipt_long_rounded, 2),
                            const SizedBox(width: 10),
                            _StatCard('Pending', '$pendingCount', AppColors.warning, Icons.hourglass_top_rounded, 3),
                          ]),

                          const SizedBox(height: 20),

                          // Donut chart
                          if (catMap.isNotEmpty)
                            _DonutChart(
                              catMap: catMap,
                              touchedIndex: _touchedPieIndex,
                              onTouch: (i) => setState(() => _touchedPieIndex = i),
                            ),

                          if (catMap.isNotEmpty) const SizedBox(height: 20),

                          const Text('Expense Records',
                              style: TextStyle(color: AppColors.textPrimary,
                                  fontSize: 16, fontWeight: FontWeight.w700))
                              .animate().fadeIn(),
                          const SizedBox(height: 12),

                          if (expenses.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(40),
                                child: Text('No expenses recorded',
                                    style: TextStyle(color: AppColors.textHint)),
                              ),
                            )
                          else
                            ...expenses.asMap().entries.map((entry) {
                              final i = entry.key;
                              final e = entry.value as Map;
                              final status   = e['status']?.toString() ?? 'pending';
                              final category = e['category']?.toString() ?? 'Other';
                              final amount   = (e['amount'] as num?)?.toDouble() ?? 0;
                              final date     = e['date']?.toString() ?? '';
                              final title    = e['title']?.toString() ?? '';
                              final catColor = _categoryColor(category);
                              final statusColor = status.toLowerCase() == 'approved'
                                  ? AppColors.success
                                  : status.toLowerCase() == 'rejected'
                                      ? AppColors.error
                                      : AppColors.warning;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surface1,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 46, height: 46,
                                    decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(_categoryIcon(category), color: catColor, size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(title,
                                        style: const TextStyle(color: AppColors.textPrimary,
                                            fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                                      const SizedBox(width: 4),
                                      Text(date, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: catColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                        child: Text(category,
                                            style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                    ]),
                                  ])),
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text(_fmt(amount),
                                        style: const TextStyle(color: AppColors.textPrimary,
                                            fontSize: 14, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 5),
                                    StatusBadge(label: status[0].toUpperCase() + status.substring(1), color: statusColor),
                                  ]),
                                ]),
                              ).animate(delay: Duration(milliseconds: i * 55)).fadeIn().slideY(begin: 0.12, end: 0);
                            }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final int index;
  const _StatCard(this.label, this.value, this.color, this.icon, this.index);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.w500)),
        ])),
      ]),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.2, end: 0),
  );
}

// ── Donut Chart ───────────────────────────────────────────────────────────────

class _DonutChart extends StatelessWidget {
  final Map<String, double> catMap;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;
  const _DonutChart({required this.catMap, required this.touchedIndex, required this.onTouch});

  @override
  Widget build(BuildContext context) {
    final entries = catMap.entries.toList();
    final total   = entries.fold<double>(0, (s, e) => s + e.value);
    final palette = AppColors.chartPalette;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Expenses by Category',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Row(children: [
          SizedBox(
            height: 150, width: 150,
            child: PieChart(PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (ev, resp) {
                  if (ev is FlTapUpEvent || ev is FlLongPressEnd) {
                    onTouch(null);
                  } else if (resp?.touchedSection != null) {
                    onTouch(resp!.touchedSection!.touchedSectionIndex);
                  }
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              sections: List.generate(entries.length, (i) {
                final isTouched = touchedIndex == i;
                final pct = total > 0 ? entries[i].value / total * 100 : 0.0;
                return PieChartSectionData(
                  color: palette[i % palette.length],
                  value: entries[i].value,
                  title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
                  radius: isTouched ? 36 : 28,
                  titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }),
            )),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(entries.length, (i) {
                final e     = entries[i];
                final color = palette[i % palette.length];
                final pct   = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis)),
                    Text('$pct%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                );
              }),
            ),
          ),
        ]),
      ]),
    ).animate(delay: 200.ms).fadeIn();
  }
}
