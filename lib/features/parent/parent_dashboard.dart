import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final parentDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/parent/dashboard');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(currentUserProvider);
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
                          loading: () => Column(children: [
                            const ShimmerCard(height: 120),
                            const SizedBox(height: 16),
                            const ShimmerCard(height: 100),
                          ]),
                          error: (e, _) => _buildError(ref, e),
                          data: (d) => _buildContent(context, ref, d),
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
    final name     = user?.name ?? 'Parent';
    final initials = user?.initials ?? 'P';
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            StatusBadge(label: 'Parent', color: AppColors.roleParent),
          ]),
        ),
        AvatarWidget(initials: initials, color: AppColors.roleParent, size: 52),
      ],
    );
  }

  Widget _buildError(WidgetRef ref, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: () => ref.refresh(parentDashboardProvider),
            child: const Text('Retry')),
      ]),
    ),
  );

  Widget _buildContent(BuildContext context, WidgetRef ref, Map<String, dynamic> d) {
    final children   = (d['children']      as List?) ?? [];
    final feeSummary = d['fee_summary']    as Map?   ?? {};
    final announce   = (d['announcements'] as List?) ?? [];

    final billed  = toD(feeSummary['billed'] , 0);
    final paid    = toD(feeSummary['paid']   , 0);
    final balance = toD(feeSummary['balance'], 0);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Children cards ─────────────────────────────────────────────────────
      ...children.asMap().entries.map((entry) {
        final c   = entry.value as Map;
        final i   = entry.key;
        final cId = c['id'] as int? ?? 0;

        final name   = '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.trim();
        final admNo  = c['admission_number']?.toString() ?? '';
        final cls    = c['class_name']?.toString() ?? '';
        final sec    = c['section_name']?.toString() ?? '';
        final type   = c['student_type']?.toString() ?? '';
        final attPct = toI(c['attendance_pct'], 0);
        final feeBal = toD(c['fee_balance'], 0);

        final initials = () {
          final p = name.trim().split(' ').where((x) => x.isNotEmpty).toList();
          return p.length >= 2
              ? '${p[0][0]}${p[1][0]}'.toUpperCase()
              : name.isNotEmpty ? name[0].toUpperCase() : 'S';
        }();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            gradient: LinearGradient(
              colors: [AppColors.roleParent.withOpacity(0.22), AppColors.surface1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Child info row ────────────────────────────────────────────
              Row(children: [
                AvatarWidget(initials: initials, color: AppColors.roleParent, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (cls.isNotEmpty) ...[
                        const Icon(Icons.class_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text([cls, if (sec.isNotEmpty) sec].join(' • '),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.badge_rounded, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(admNo,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      if (type.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: type[0].toUpperCase() + type.substring(1),
                          color: type.toLowerCase() == 'boarding'
                              ? AppColors.accent
                              : AppColors.success,
                        ),
                      ],
                    ]),
                  ]),
                ),
              ]),

              // ── Quick stat chips (clickable) ──────────────────────────────
              const SizedBox(height: 12),
              Row(children: [
                // Attendance chip
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/parent/attendance'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.fact_check_rounded,
                              color: AppColors.success, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$attPct%',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800,
                                    color: AppColors.success)),
                            const Text('Attendance',
                                style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.success, size: 16),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Fee balance chip
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/parent/fees'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: feeBal > 0
                            ? AppColors.warning.withOpacity(0.12)
                            : AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: feeBal > 0
                                ? AppColors.warning.withOpacity(0.25)
                                : AppColors.success.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: feeBal > 0
                                  ? AppColors.warning.withOpacity(0.2)
                                  : AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle),
                          child: Icon(Icons.account_balance_wallet_rounded,
                              color: feeBal > 0 ? AppColors.warning : AppColors.success,
                              size: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_fmtShort(feeBal),
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800,
                                    color: feeBal > 0
                                        ? AppColors.warning
                                        : AppColors.success),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(feeBal > 0 ? 'Balance' : 'Cleared',
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          ]),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: feeBal > 0 ? AppColors.warning : AppColors.success,
                            size: 16),
                      ]),
                    ),
                  ),
                ),
              ]),

              // ── View detail buttons ───────────────────────────────────────
              const SizedBox(height: 10),
              Row(children: [
                _DetailButton(
                  icon: Icons.school_rounded,
                  label: 'Reports',
                  color: AppColors.primary,
                  onTap: () => context.push('/parent/reports'),
                ),
                const SizedBox(width: 8),
                _DetailButton(
                  icon: Icons.campaign_rounded,
                  label: 'News',
                  color: AppColors.roleParent,
                  onTap: () => context.push('/parent/announcements'),
                ),
              ]),
            ]),
          ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0),
        );
      }),

      // ── Fee summary card ──────────────────────────────────────────────────
      SectionHeader(
        title: 'Fee Summary',
        action: 'Pay Now',
        onAction: () => context.push('/parent/fees'),
      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => context.push('/parent/fees'),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Billed',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('UGX ${_fmt(billed)}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Balance Due',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('UGX ${_fmt(balance)}',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: balance > 0 ? AppColors.warning : AppColors.success)),
              ]),
            ]),
            if (billed > 0) ...[
              const SizedBox(height: 14),
              LinearPercentIndicator(
                lineHeight: 10,
                percent: (paid / billed).clamp(0.0, 1.0),
                backgroundColor: AppColors.surface2,
                linearGradient: const LinearGradient(
                    colors: [AppColors.success, AppColors.accent]),
                barRadius: const Radius.circular(5),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Paid: UGX ${_fmt(paid)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                Text('${((paid / billed) * 100).toStringAsFixed(0)}% paid',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ],
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Tap to manage fees  ',
                  style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 10, color: AppColors.textHint),
            ]),
          ]),
        ),
      ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.1, end: 0),

      const SizedBox(height: 24),

      // ── Quick actions ─────────────────────────────────────────────────────
      const Text('Quick Access',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _QuickAction(
            icon: Icons.receipt_long_rounded, label: 'Fees',
            color: AppColors.warning, onTap: () => context.push('/parent/fees'))),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
            icon: Icons.school_rounded, label: 'Reports',
            color: AppColors.primary, onTap: () => context.push('/parent/reports'))),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
            icon: Icons.fact_check_rounded, label: 'Attendance',
            color: AppColors.success, onTap: () => context.push('/parent/attendance'))),
        const SizedBox(width: 10),
        Expanded(child: _QuickAction(
            icon: Icons.campaign_rounded, label: 'News',
            color: AppColors.roleParent, onTap: () => context.push('/parent/announcements'))),
      ]).animate(delay: 300.ms).fadeIn(),

      // ── Announcements ─────────────────────────────────────────────────────
      if (announce.isNotEmpty) ...[
        const SizedBox(height: 24),
        SectionHeader(
          title: 'Recent Announcements',
          action: 'See All',
          onAction: () => context.push('/parent/announcements'),
        ).animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 12),
        ...announce.take(3).toList().asMap().entries.map((e) {
          final a   = e.value as Map;
          final idx = e.key;
          final color = _announceColor(a['type']?.toString());
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.push('/parent/announcements'),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_announceIcon(a['type']?.toString()), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a['title']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(a['message']?.toString() ?? '',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                      const SizedBox(height: 6),
                      Text(_timeAgo(a['created_at']?.toString()),
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint, size: 16),
                ]),
              ),
            ),
          ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
        }),
      ],
    ]);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  String _fmt(double v) {
    if (v >= 1000000)
      return '${(v / 1000000).toStringAsFixed(2)}M';
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  String _fmtShort(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000)    return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  Color _announceColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'exam':    return AppColors.roleTeacher;
      case 'event':   return AppColors.success;
      case 'fee':     return AppColors.warning;
      case 'holiday': return AppColors.accent;
      default:        return AppColors.primary;
    }
  }

  IconData _announceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'exam':    return Icons.assignment_rounded;
      case 'event':   return Icons.event_rounded;
      case 'fee':     return Icons.account_balance_wallet_rounded;
      case 'holiday': return Icons.beach_access_rounded;
      default:        return Icons.campaign_rounded;
    }
  }

  String _timeAgo(String? ts) {
    if (ts == null) return '';
    try {
      final dt   = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}

// ── Detail Button ─────────────────────────────────────────────────────────────

class _DetailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DetailButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Quick Action Button ───────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}
