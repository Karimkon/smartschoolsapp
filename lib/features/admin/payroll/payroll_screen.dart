import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final payrollProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/payroll$query');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmt(double v) {
  if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
  return 'UGX ${v.toStringAsFixed(0)}';
}

const _palette = [
  AppColors.roleTeacher, AppColors.primary, AppColors.accent,
  AppColors.roleParent, AppColors.roleAccountant, AppColors.warning,
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminPayrollScreen extends ConsumerStatefulWidget {
  const AdminPayrollScreen({super.key});
  @override ConsumerState<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends ConsumerState<AdminPayrollScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String get _query =>
      '?month=${_month.month.toString().padLeft(2, '0')}&year=${_month.year}';

  String get _monthLabel {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  void _prevMonth() => setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() => setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(payrollProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Payroll',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(payrollProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Month selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary), onPressed: _prevMonth),
                Expanded(child: Text(_monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                IconButton(icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary), onPressed: _nextMonth),
              ]),
            ).animate().fadeIn(),
          ),

          // Summary
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final s = data['summary'] as Map? ?? {};
              final totalNet   = toD(s['total_net'], 0);
              final totalPaid  = toD(s['total_paid'], 0);
              final totalPend  = toD(s['total_pending'], 0);
              final paidCount  = toI(s['paid_count'], 0);
              final totalCount = toI(s['total_count'], 0);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  Expanded(child: _SummaryTile('Total Payroll', _fmt(totalNet), AppColors.primary, 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryTile('Paid', _fmt(totalPaid), AppColors.success, 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryTile('Pending', _fmt(totalPend), AppColors.warning, 2)),
                ]),
              );
            },
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: 6,
                itemBuilder: (_, __) =>
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 84)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load payroll', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(payrollProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (data) {
                final records = (data['data'] as List?) ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.payments_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No payroll records for this month',
                          style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () => ref.refresh(payrollProvider(_query).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r         = records[i] as Map;
                      final name      = r['staff_name']?.toString() ?? '';
                      final basic     = toD(r['basic_salary'], 0);
                      final allowances= toD(r['allowances'], 0);
                      final deductions= toD(r['deductions'], 0);
                      final net       = toDN(r['net_salary']) ?? (basic + allowances - deductions);
                      final isPaid    = r['status']?.toString().toLowerCase() == 'paid';
                      final color     = _palette[i % _palette.length];

                      final initials = name.trim().split(' ')
                          .where((x) => x.isNotEmpty)
                          .take(2)
                          .map((x) => x[0].toUpperCase())
                          .join();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            AvatarWidget(initials: initials.isEmpty ? '?' : initials, color: color, size: 44),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Row(children: [
                                _MiniPill('Basic: ${_fmt(basic)}', AppColors.textSecondary),
                                const SizedBox(width: 6),
                                _MiniPill('Net: ${_fmt(net)}', AppColors.primary),
                              ]),
                              if (deductions > 0) ...[
                                const SizedBox(height: 3),
                                _MiniPill('Deductions: ${_fmt(deductions)}', AppColors.error),
                              ],
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_fmt(net),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 6),
                              StatusBadge(
                                label: isPaid ? 'Paid' : 'Pending',
                                color: isPaid ? AppColors.success : AppColors.warning,
                              ),
                            ]),
                          ]),
                        ),
                      ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05);
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final int index;
  const _SummaryTile(this.label, this.value, this.color, this.index);

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Column(children: [
      Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  ).animate(delay: Duration(milliseconds: index * 80)).fadeIn();
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniPill(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
