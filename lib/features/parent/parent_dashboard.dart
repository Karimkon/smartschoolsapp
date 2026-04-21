import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class ParentDashboardData {
  final ChildInfo child;
  final double attendancePercent;
  final double feeBalance;
  final double feeTotalBilled;
  final int assignmentsDue;
  final int classRank;
  final int classTotal;
  final List<Announcement> announcements;

  const ParentDashboardData({
    required this.child,
    required this.attendancePercent,
    required this.feeBalance,
    required this.feeTotalBilled,
    required this.assignmentsDue,
    required this.classRank,
    required this.classTotal,
    required this.announcements,
  });

  double get feePaidPercent {
    if (feeTotalBilled == 0) return 0;
    return ((feeTotalBilled - feeBalance) / feeTotalBilled).clamp(0.0, 1.0);
  }
}

class ChildInfo {
  final String name;
  final String className;
  final String admissionNo;
  final String? photoUrl;
  const ChildInfo(this.name, this.className, this.admissionNo, this.photoUrl);

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class Announcement {
  final String title;
  final String body;
  final String date;
  final IconData icon;
  final Color color;
  const Announcement(this.title, this.body, this.date, this.icon, this.color);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final parentDashboardProvider = FutureProvider<ParentDashboardData>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const ParentDashboardData(
      child: ChildInfo('Brian Kamau', 'Form 3A', 'ADM/2022/0341', null),
      attendancePercent: 89.5,
      feeBalance: 8500.0,
      feeTotalBilled: 35000.0,
      assignmentsDue: 3,
      classRank: 7,
      classTotal: 42,
      announcements: [
        Announcement(
          'Mid-Term Exams Next Week',
          'Mid-term examinations begin Monday 28th April. Students should report by 7:00 AM.',
          '2 hours ago',
          Icons.event_note_rounded,
          AppColors.roleTeacher,
        ),
        Announcement(
          'School Sports Day',
          'Annual sports day on Friday 2nd May. Parents are welcome to attend.',
          'Yesterday',
          Icons.sports_soccer_rounded,
          AppColors.success,
        ),
        Announcement(
          'Fee Payment Reminder',
          'Term 2 fees deadline is 30th April. Late payment attracts a penalty.',
          '2 days ago',
          Icons.account_balance_wallet_rounded,
          AppColors.warning,
        ),
        Announcement(
          'Parent-Teacher Meeting',
          'Schedule PT meetings on 5th May from 9 AM – 1 PM in the school hall.',
          '3 days ago',
          Icons.people_rounded,
          AppColors.primary,
        ),
      ],
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(parentDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleParent,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(parentDashboardProvider),
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
                          loading: () => const ShimmerCard(height: 120),
                          error: (_, __) => const ShimmerCard(height: 120),
                          data: (d) => _buildChildCard(context, d),
                        ),
                        const SizedBox(height: 20),
                        dashAsync.when(
                          loading: () => _statsShimmer(),
                          error: (_, __) => _statsShimmer(),
                          data: (d) => _buildStats(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Fee Summary',
                          action: 'Pay Now',
                          onAction: () => context.push('/parent/fees'),
                        ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 110),
                          error: (_, __) => const ShimmerCard(height: 110),
                          data: (d) => _buildFeeCard(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Recent Announcements',
                          action: 'See All',
                          onAction: () => context.push('/parent/announcements'),
                        ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildAnnouncements(d),
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
    final name = user?.name ?? 'Parent';
    final initials = user?.initials ?? 'P';
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
              StatusBadge(label: 'Parent', color: AppColors.roleParent),
            ],
          ),
        ),
        AvatarWidget(initials: initials, color: AppColors.roleParent, size: 52),
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
    children: List.generate(3, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 80),
    )),
  );

  Widget _buildChildCard(BuildContext context, ParentDashboardData d) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [AppColors.roleParent.withOpacity(0.25), AppColors.surface1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          AvatarWidget(initials: d.child.initials, color: AppColors.roleParent, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.child.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.class_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(d.child.className, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.badge_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(d.child.admissionNo, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/parent/child-profile'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.roleParent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.roleParent, size: 16),
            ),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildStats(ParentDashboardData d) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Attendance', value: '${d.attendancePercent}%', icon: Icons.how_to_reg_rounded, color: AppColors.success, index: 0),
        StatCard(label: 'Fee Balance', value: 'KES ${d.feeBalance.toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, color: AppColors.roleParent, subtitle: 'Pending', index: 1),
        StatCard(label: 'Assignments Due', value: '${d.assignmentsDue}', icon: Icons.assignment_late_rounded, color: AppColors.warning, index: 2),
        StatCard(label: 'Class Rank', value: '${d.classRank}/${d.classTotal}', icon: Icons.emoji_events_rounded, color: AppColors.primary, index: 3),
      ],
    );
  }

  Widget _buildFeeCard(ParentDashboardData d) {
    final paid = d.feeTotalBilled - d.feeBalance;
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Term 2 Fees', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('KES ${d.feeTotalBilled.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('KES ${d.feeBalance.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.roleParent)),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: d.feePaidPercent,
            backgroundColor: AppColors.surface2,
            linearGradient: const LinearGradient(
              colors: [AppColors.success, AppColors.accent],
            ),
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid: KES ${paid.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
              Text('${(d.feePaidPercent * 100).toStringAsFixed(1)}% paid',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _buildAnnouncements(ParentDashboardData d) {
    return Column(
      children: d.announcements.asMap().entries.map((e) {
        final a = e.value;
        final idx = e.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(a.icon, color: a.color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(a.body, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(a.date, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}
