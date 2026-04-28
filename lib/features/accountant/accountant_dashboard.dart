import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final accountantDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class AccountantDashboard extends ConsumerWidget {
  const AccountantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(accountantDashboardProvider);

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
                          error: (e, _) => _buildError(ref, e),
                          data: (d) => _buildStats(d),
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
                          data: (d) => _buildCollectionsChart(d),
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
                          onAction: () => context.push('/accountant/fees'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildPaymentsList(d),
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
    final name     = user?.name ?? 'Accountant';
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

  Widget _buildError(WidgetRef ref, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(accountantDashboardProvider),
          child: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildStats(Map<String, dynamic> d) {
    final stats   = d['stats'] as Map? ?? {};
    final billed  = stats['billed']?.toString() ?? '0 UGX';
    final paid    = stats['paid']?.toString()   ?? '0 UGX';
    final pending = stats['pending']?.toString() ?? '0 UGX';
    final overdue = (stats['overdue'] as int?) ?? 0;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Total Billed', value: billed, icon: Icons.receipt_long_rounded, color: AppColors.roleAccountant, index: 0),
        StatCard(label: 'Collected', value: paid, icon: Icons.check_circle_rounded, color: AppColors.success, index: 1),
        StatCard(label: 'Pending', value: pending, icon: Icons.pending_rounded, color: AppColors.warning, subtitle: 'Unpaid', index: 2),
        StatCard(label: 'Overdue', value: '$overdue students', icon: Icons.warning_amber_rounded, color: AppColors.error, subtitle: overdue > 0 ? 'Overdue' : null, index: 3),
      ],
    );
  }

  Widget _buildCollectionsChart(Map<String, dynamic> d) {
    final monthly = (d['monthly'] as List?) ?? [];
    if (monthly.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No collection data available', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final amounts = monthly.map((m) => ((m as Map)['amount'] as num?)?.toDouble() ?? 0.0).toList();
    final maxVal  = amounts.isEmpty ? 1.0 : amounts.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal > 0 ? maxVal * 1.25 : 100.0;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMax,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItem: (group, _, rod, __) {
                  final m = monthly[group.x] as Map;
                  return BarTooltipItem(
                    '${m['month']}\n',
                    const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    children: [
                      TextSpan(
                        text: 'UGX ${_fmtK(rod.toY)}',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= monthly.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text((monthly[i] as Map)['month']?.toString() ?? '',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (v, _) {
                    if (v == 0 || (chartMax > 10000 && v % (chartMax / 4).round() != 0)) return const SizedBox();
                    return Text(_fmtK(v), style: const TextStyle(color: AppColors.textHint, fontSize: 9));
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              horizontalInterval: chartMax / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: monthly.asMap().entries.map((e) {
              final isLatest = e.key == monthly.length - 1;
              final amt = ((e.value as Map)['amount'] as num?)?.toDouble() ?? 0;
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: amt,
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
      _QuickAction('Invoices', Icons.receipt_long_rounded, AppColors.primary, '/accountant/fees'),
      _QuickAction('Payments', Icons.payments_rounded, AppColors.roleAccountant, '/accountant/fees'),
      _QuickAction('Reports', Icons.bar_chart_rounded, AppColors.success, '/accountant/reports'),
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

  Widget _buildPaymentsList(Map<String, dynamic> d) {
    final payments = (d['recent_payments'] as List?) ?? [];
    if (payments.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.payments_outlined, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No payments recorded yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 400.ms).fadeIn();
    }

    final methodColors = {
      'cash': AppColors.success,
      'bank': AppColors.primary,
      'momo': AppColors.accent,
      'mobile_money': AppColors.accent,
    };

    return Column(
      children: payments.take(6).toList().asMap().entries.map((e) {
        final p          = e.value as Map;
        final idx        = e.key;
        final name       = p['student_name']?.toString() ?? 'Unknown';
        final amount     = (p['amount'] as num?)?.toDouble() ?? 0;
        final method     = (p['payment_method'] ?? p['method'])?.toString() ?? 'Cash';
        final date       = p['payment_date']?.toString() ?? p['created_at']?.toString() ?? '';
        final color      = methodColors[method.toLowerCase()] ?? AppColors.textSecondary;
        final initials   = _initials(name);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                AvatarWidget(initials: initials, color: color, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(_fmtDate(date), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('UGX ${_fmtNum(amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    StatusBadge(label: method, color: color),
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
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _fmtK(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtNum(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _fmtDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
