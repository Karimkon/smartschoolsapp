import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Data provider ─────────────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data);
});

// ── Dashboard ─────────────────────────────────────────────────────────────────
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final async = ref.watch(adminDashboardProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: async.when(
            loading: () => _buildSkeleton(),
            error: (_, __) => _buildError(ref),
            data: (data) => _buildContent(context, user?.name ?? 'Admin', data, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String name, Map data, WidgetRef ref) {
    final stats     = data['stats'] as Map;
    final activity  = (data['recent_activity'] as List).cast<Map>();
    final events    = (data['upcoming_events'] as List).cast<Map>();
    final enrollment= (data['enrollment'] as List).cast<Map>();
    final feeData   = (data['fee_breakdown'] as List).cast<Map>();
    final attendance= (data['attendance_today'] as num).toInt();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      onRefresh: () => ref.refresh(adminDashboardProvider.future),
      child: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good ${_greeting()},', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        Text(name.split(' ').first,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/admin/profile'),
                    child: AvatarWidget(initials: name.isNotEmpty ? name[0] : 'A', color: AppColors.roleAdmin, size: 46),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
          ),

          // ── Stats Grid ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                StatCard(label: 'Students',  value: '${stats['students']}',       icon: Icons.people_rounded,                  color: AppColors.primary,     index: 0),
                StatCard(label: 'Teachers',  value: '${stats['teachers']}',       icon: Icons.person_pin_rounded,              color: AppColors.roleTeacher, index: 1),
                StatCard(label: 'Collected', value: '${stats['collected_fmt']}',  icon: Icons.account_balance_wallet_rounded,  color: AppColors.success,     index: 2),
                StatCard(label: 'Pending',   value: '${stats['pending_fmt']}',    icon: Icons.pending_actions_rounded,         color: AppColors.warning,     index: 3),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 140,
              ),
            ),
          ),

          // ── Attendance + Fee Breakdown ───────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  // Attendance ring
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Today's Attendance", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 100,
                                child: PieChart(PieChartData(
                                  sections: [
                                    PieChartSectionData(value: attendance.toDouble(), color: AppColors.success, radius: 18, showTitle: false),
                                    PieChartSectionData(value: (100 - attendance).toDouble(), color: AppColors.surface3, radius: 18, showTitle: false),
                                  ],
                                  centerSpaceRadius: 32,
                                  sectionsSpace: 3,
                                )),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('$attendance%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  const Text('Present', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1, end: 0),
                  ),

                  const SizedBox(width: 12),

                  // Fee donut
                  Expanded(
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fee Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: PieChart(PieChartData(
                              sections: feeData.map((d) => PieChartSectionData(
                                value: (d['value'] as num).toDouble(),
                                color: Color(d['color'] as int),
                                radius: 20, showTitle: false,
                              )).toList(),
                              centerSpaceRadius: 28,
                              sectionsSpace: 3,
                            )),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 4,
                            children: feeData.map((d) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(d['color'] as int), shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Text('${d['name']}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            )).toList(),
                          ),
                        ],
                      ),
                    ).animate(delay: 350.ms).fadeIn().slideX(begin: 0.1, end: 0),
                  ),
                ],
              ),
            ),
          ),

          // ── Enrolment Chart ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Enrolment by Class'),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (enrollment.map((e) => (e['count'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.3),
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true, reservedSize: 24,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= enrollment.length) return const SizedBox();
                              return Text(enrollment[i]['name'] as String, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
                            },
                          )),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(color: AppColors.surface3, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: enrollment.asMap().entries.map((e) => BarChartGroupData(
                          x: e.key,
                          barRods: [BarChartRodData(
                            toY: (e.value['count'] as num).toDouble(),
                            gradient: AppColors.primaryGradient,
                            width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          )],
                        )).toList(),
                      )),
                    ),
                  ],
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickAction(icon: Icons.person_add_rounded,        label: 'Add Student',  color: AppColors.primary,       onTap: () => context.go('/admin/students')),
                      _QuickAction(icon: Icons.fact_check_rounded,        label: 'Attendance',   color: AppColors.success,       onTap: () => context.go('/admin/attendance')),
                      _QuickAction(icon: Icons.account_balance_wallet_rounded, label: 'Fees',   color: AppColors.warning,       onTap: () => context.go('/admin/fees')),
                      _QuickAction(icon: Icons.people_rounded,            label: 'Teachers',     color: AppColors.roleTeacher,   onTap: () => context.go('/admin/teachers')),
                    ],
                  ),
                ],
              ).animate(delay: 450.ms).fadeIn(),
            ),
          ),

          // ── Recent Activity ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Recent Activity'),
                    const SizedBox(height: 12),
                    ...activity.asMap().entries.map((e) => _ActivityTile(
                      text: e.value['text'] as String,
                      time: e.value['time'] as String,
                      index: e.key,
                    )),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ),
          ),

          // ── Upcoming Events ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            sliver: SliverToBoxAdapter(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Upcoming Events'),
                    const SizedBox(height: 12),
                    ...events.map((ev) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(ev['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                          Text(ev['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    )),
                  ],
                ),
              ).animate(delay: 550.ms).fadeIn(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const ShimmerCard(height: 60), const SizedBox(height: 16),
      Row(children: [const Expanded(child: ShimmerCard(height: 90)), const SizedBox(width: 12), const Expanded(child: ShimmerCard(height: 90))]),
      const SizedBox(height: 12),
      Row(children: [const Expanded(child: ShimmerCard(height: 90)), const SizedBox(width: 12), const Expanded(child: ShimmerCard(height: 90))]),
      const SizedBox(height: 16), const ShimmerCard(height: 160), const SizedBox(height: 16), const ShimmerCard(height: 200),
    ],
  );

  Widget _buildError(WidgetRef ref) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
      const SizedBox(height: 12),
      const Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: () => ref.refresh(adminDashboardProvider), child: const Text('Retry')),
    ]),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  final String text, time; final int index;
  const _ActivityTile({required this.text, required this.time, required this.index});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.chartPalette[index % AppColors.chartPalette.length]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ],
    ),
  );
}
