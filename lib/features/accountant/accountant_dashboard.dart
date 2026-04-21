import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class AccountantDashboardData {
  final double totalBilled;
  final double totalCollected;
  final double pending;
  final int overdueCount;
  final List<MonthlyCollection> monthlyCollections;
  final List<RecentPayment> recentPayments;

  const AccountantDashboardData({
    required this.totalBilled,
    required this.totalCollected,
    required this.pending,
    required this.overdueCount,
    required this.monthlyCollections,
    required this.recentPayments,
  });
}

class MonthlyCollection {
  final String month;
  final double amount;
  const MonthlyCollection(this.month, this.amount);
}

class RecentPayment {
  final String studentName;
  final double amount;
  final String date;
  final String method;
  final Color methodColor;
  const RecentPayment(this.studentName, this.amount, this.date, this.method, this.methodColor);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final accountantDashboardProvider = FutureProvider<AccountantDashboardData>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const AccountantDashboardData(
      totalBilled: 4850000,
      totalCollected: 3620000,
      pending: 1230000,
      overdueCount: 47,
      monthlyCollections: [
        MonthlyCollection('Nov', 580000),
        MonthlyCollection('Dec', 420000),
        MonthlyCollection('Jan', 690000),
        MonthlyCollection('Feb', 750000),
        MonthlyCollection('Mar', 610000),
        MonthlyCollection('Apr', 570000),
      ],
      recentPayments: [
        RecentPayment('Alice Muthoni', 15000, '21 Apr 2025', 'M-Pesa', AppColors.success),
        RecentPayment('John Otieno', 35000, '21 Apr 2025', 'Bank', AppColors.primary),
        RecentPayment('Grace Waweru', 15000, '20 Apr 2025', 'M-Pesa', AppColors.success),
        RecentPayment('David Kibet', 35000, '20 Apr 2025', 'Cash', AppColors.warning),
        RecentPayment('Faith Njoroge', 15000, '19 Apr 2025', 'M-Pesa', AppColors.success),
        RecentPayment('Peter Kamau', 35000, '19 Apr 2025', 'Bank', AppColors.primary),
      ],
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class AccountantDashboard extends ConsumerWidget {
  const AccountantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(accountantDashboardProvider);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleAccountant,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(accountantDashboardProvider),
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
                          data: (d) => _buildStats(d, fmt),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Monthly Collections',
                          action: 'Full Report',
                          onAction: () => context.push('/accountant/reports'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 220),
                          error: (_, __) => const ShimmerCard(height: 220),
                          data: (d) => _buildCollectionsChart(d, fmt),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context)
                            .animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Recent Payments',
                          action: 'View All',
                          onAction: () => context.push('/accountant/payments'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildPaymentsList(d, fmt),
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
    final name = user?.name ?? 'Accountant';
    final initials = user?.initials ?? 'A';
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
              StatusBadge(label: 'Accountant', color: AppColors.roleAccountant),
            ],
          ),
        ),
        AvatarWidget(initials: initials, color: AppColors.roleAccountant, size: 52),
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

  Widget _listShimmer() => Column(
    children: List.generate(4, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 68),
    )),
  );

  Widget _buildStats(AccountantDashboardData d, NumberFormat fmt) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Total Billed', value: 'KES ${fmt.format(d.totalBilled ~/ 1000)}K', icon: Icons.receipt_long_rounded, color: AppColors.roleAccountant, index: 0),
        StatCard(label: 'Collected', value: 'KES ${fmt.format(d.totalCollected ~/ 1000)}K', icon: Icons.check_circle_rounded, color: AppColors.success, index: 1),
        StatCard(label: 'Pending', value: 'KES ${fmt.format(d.pending ~/ 1000)}K', icon: Icons.pending_rounded, color: AppColors.warning, subtitle: 'Unpaid', index: 2),
        StatCard(label: 'Overdue', value: '${d.overdueCount} students', icon: Icons.warning_amber_rounded, color: AppColors.error, subtitle: 'Overdue', index: 3),
      ],
    );
  }

  Widget _buildCollectionsChart(AccountantDashboardData d, NumberFormat fmt) {
    final maxVal = d.monthlyCollections.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.2,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${d.monthlyCollections[group.x].month}\n',
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  children: [
                    TextSpan(
                      text: 'KES ${fmt.format(rod.toY ~/ 1000)}K',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= d.monthlyCollections.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(d.monthlyCollections[i].month,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, _) {
                    if (v == 0) return const SizedBox();
                    if (v % 200000 != 0) return const SizedBox();
                    return Text('${(v / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(color: AppColors.textHint, fontSize: 10));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: 200000,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: d.monthlyCollections.asMap().entries.map((e) {
              final isLatest = e.key == d.monthlyCollections.length - 1;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.amount,
                  gradient: LinearGradient(
                    colors: isLatest
                        ? [AppColors.roleAccountant, AppColors.roleTeacher]
                        : [AppColors.primary.withOpacity(0.8), AppColors.primary],
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
      _QuickAction('New\nInvoice', Icons.note_add_rounded, AppColors.primary, '/accountant/invoices/new'),
      _QuickAction('Collect\nPayment', Icons.payments_rounded, AppColors.roleAccountant, '/accountant/payments/new'),
      _QuickAction('View\nReport', Icons.bar_chart_rounded, AppColors.success, '/accountant/reports'),
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

  Widget _buildPaymentsList(AccountantDashboardData d, NumberFormat fmt) {
    return Column(
      children: d.recentPayments.asMap().entries.map((e) {
        final p = e.value;
        final idx = e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AvatarWidget(
                  initials: _initials(p.studentName),
                  color: p.methodColor,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(p.date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('KES ${fmt.format(p.amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    StatusBadge(label: p.method, color: p.methodColor),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
