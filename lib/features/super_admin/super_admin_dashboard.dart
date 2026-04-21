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

class SuperAdminDashboardData {
  final int totalSchools;
  final int activeSchools;
  final int totalStudents;
  final double totalRevenue;
  final List<TierCount> schoolsByTier;
  final List<SchoolRegistration> recentRegistrations;
  final PlatformHealth health;

  const SuperAdminDashboardData({
    required this.totalSchools,
    required this.activeSchools,
    required this.totalStudents,
    required this.totalRevenue,
    required this.schoolsByTier,
    required this.recentRegistrations,
    required this.health,
  });
}

class TierCount {
  final String tier;
  final int count;
  final Color color;
  const TierCount(this.tier, this.count, this.color);
}

class SchoolRegistration {
  final String schoolName;
  final String country;
  final String status;
  final String date;
  final Color statusColor;
  const SchoolRegistration(this.schoolName, this.country, this.status, this.date, this.statusColor);
}

class PlatformHealth {
  final double apiUptime;
  final double dbLoad;
  final int activeUsers;
  final double storageUsed;
  const PlatformHealth(this.apiUptime, this.dbLoad, this.activeUsers, this.storageUsed);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final superAdminDashboardProvider = FutureProvider<SuperAdminDashboardData>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const SuperAdminDashboardData(
      totalSchools: 247,
      activeSchools: 231,
      totalStudents: 184320,
      totalRevenue: 6840000,
      schoolsByTier: [
        TierCount('Starter', 82, AppColors.textSecondary),
        TierCount('Basic', 65, AppColors.primary),
        TierCount('Pro', 58, AppColors.roleTeacher),
        TierCount('Enterprise', 42, AppColors.roleSuperAdmin),
      ],
      recentRegistrations: [
        SchoolRegistration('Greenwood Academy', 'Kenya', 'Active', '21 Apr 2025', AppColors.success),
        SchoolRegistration('St. Mary High School', 'Uganda', 'Pending', '20 Apr 2025', AppColors.warning),
        SchoolRegistration('Sunrise International', 'Tanzania', 'Active', '19 Apr 2025', AppColors.success),
        SchoolRegistration('Atlantic Academy', 'Nigeria', 'Active', '18 Apr 2025', AppColors.success),
        SchoolRegistration('Valley View School', 'Rwanda', 'Suspended', '17 Apr 2025', AppColors.error),
        SchoolRegistration('Blue Ridge College', 'Ghana', 'Pending', '16 Apr 2025', AppColors.warning),
      ],
      health: PlatformHealth(99.7, 34.2, 2847, 68.4),
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class SuperAdminDashboard extends ConsumerWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(superAdminDashboardProvider);
    final fmt = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleSuperAdmin,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(superAdminDashboardProvider),
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
                          title: 'Schools by Subscription Tier',
                          action: 'Manage',
                          onAction: () => context.push('/super-admin/subscriptions'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 220),
                          error: (_, __) => const ShimmerCard(height: 220),
                          data: (d) => _buildTierChart(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Platform Health')
                            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 120),
                          error: (_, __) => const ShimmerCard(height: 120),
                          data: (d) => _buildHealthCard(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Recent School Registrations',
                          action: 'View All',
                          onAction: () => context.push('/super-admin/schools'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildSchoolsList(d),
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
    final name = user?.name ?? 'Super Admin';
    final initials = user?.initials ?? 'SA';
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
              StatusBadge(label: 'Super Admin', color: AppColors.roleSuperAdmin),
            ],
          ),
        ),
        Stack(
          children: [
            AvatarWidget(initials: initials, color: AppColors.roleSuperAdmin, size: 52),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDark, width: 2),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildStats(SuperAdminDashboardData d, NumberFormat fmt) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Total Schools', value: '${d.totalSchools}', icon: Icons.account_balance_rounded, color: AppColors.roleSuperAdmin, index: 0),
        StatCard(label: 'Active Schools', value: '${d.activeSchools}', icon: Icons.verified_rounded, color: AppColors.success, index: 1),
        StatCard(label: 'Total Students', value: fmt.format(d.totalStudents), icon: Icons.people_rounded, color: AppColors.primary, index: 2),
        StatCard(label: 'Revenue (MRR)', value: 'KES ${fmt.format(d.totalRevenue ~/ 1000)}K', icon: Icons.trending_up_rounded, color: AppColors.roleAccountant, index: 3),
      ],
    );
  }

  Widget _buildTierChart(SuperAdminDashboardData d) {
    final maxVal = d.schoolsByTier.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal * 1.3,
            minY: 0,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.surface2,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${d.schoolsByTier[group.x].tier}\n',
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  children: [
                    TextSpan(
                      text: '${rod.toY.toInt()} schools',
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
                    if (i < 0 || i >= d.schoolsByTier.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(d.schoolsByTier[i].tier,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    if (v % 20 != 0 || v == 0) return const SizedBox();
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
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
              drawVerticalLine: false,
            ),
            borderData: FlBorderData(show: false),
            barGroups: d.schoolsByTier.asMap().entries.map((e) {
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: e.value.count.toDouble(),
                  gradient: LinearGradient(
                    colors: [e.value.color.withOpacity(0.8), e.value.color],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 36,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHealthCard(SuperAdminDashboardData d) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _healthMetric('API Uptime', '${d.health.apiUptime}%', AppColors.success, Icons.cloud_done_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _healthMetric('DB Load', '${d.health.dbLoad}%', d.health.dbLoad > 70 ? AppColors.error : AppColors.success, Icons.storage_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _healthMetric('Active Users', '${d.health.activeUsers}', AppColors.primary, Icons.people_alt_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _healthMetric('Storage Used', '${d.health.storageUsed}%', d.health.storageUsed > 80 ? AppColors.warning : AppColors.accent, Icons.save_rounded)),
            ],
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _healthMetric(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSchoolsList(SuperAdminDashboardData d) {
    return Column(
      children: d.recentRegistrations.asMap().entries.map((e) {
        final s = e.value;
        final idx = e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: s.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      s.schoolName.split(' ').map((w) => w[0]).take(2).join(),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: s.statusColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.schoolName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(s.country, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(s.date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ]),
                    ],
                  ),
                ),
                StatusBadge(label: s.status, color: s.statusColor),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}
