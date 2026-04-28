import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _studentInvoicesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/fees/invoices');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

final _studentPaymentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/fees/payments');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

final _studentFeeSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/fees/summary');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentFeesScreen extends ConsumerWidget {
  const StudentFeesScreen({super.key});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':    return AppColors.success;
      case 'partial': return AppColors.primary;
      case 'pending': return AppColors.warning;
      case 'overdue': return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  Color _methodColor(String m) {
    switch (m.toLowerCase()) {
      case 'cash':         return AppColors.success;
      case 'mobile_money':
      case 'mobile money':
      case 'momo':         return AppColors.accent;
      case 'bank':         return AppColors.primary;
      default:             return AppColors.textSecondary;
    }
  }

  IconData _methodIcon(String m) {
    switch (m.toLowerCase()) {
      case 'cash':         return Icons.payments_rounded;
      case 'mobile_money':
      case 'mobile money':
      case 'momo':         return Icons.phone_android_rounded;
      case 'bank':         return Icons.account_balance_rounded;
      default:             return Icons.payment_rounded;
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month-1]}, ${dt.year}';
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync  = ref.watch(_studentFeeSummaryProvider);
    final invoicesAsync = ref.watch(_studentInvoicesProvider);
    final paymentsAsync = ref.watch(_studentPaymentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Fees', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(_studentFeeSummaryProvider);
              ref.invalidate(_studentInvoicesProvider);
              ref.invalidate(_studentPaymentsProvider);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: RefreshIndicator(
          color: AppColors.roleStudent,
          backgroundColor: AppColors.surface1,
          onRefresh: () async {
            ref.invalidate(_studentFeeSummaryProvider);
            ref.invalidate(_studentInvoicesProvider);
            ref.invalidate(_studentPaymentsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // ── Summary Card ─────────────────────────────────────────────────
              summaryAsync.when(
                loading: () => const ShimmerCard(height: 130),
                error: (_, __) => const SizedBox(),
                data: (s) {
                  final sum     = s['summary'] as Map? ?? {};
                  final billed  = (sum['billed']  as num?)?.toDouble() ?? 0;
                  final paid    = (sum['paid']    as num?)?.toDouble() ?? 0;
                  final balance = (billed - paid).clamp(0.0, double.infinity);
                  final progress = billed > 0 ? (paid / billed).clamp(0.0, 1.0) : 0.0;

                  return GlassCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2F52), Color(0xFF111F3C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fee Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _FeeStat('Total Fee', 'UGX ${_fmt(billed)}', AppColors.textPrimary),
                            Container(width: 1, height: 40, color: Colors.white12),
                            _FeeStat('Amount Paid', 'UGX ${_fmt(paid)}', AppColors.success),
                            Container(width: 1, height: 40, color: Colors.white12),
                            _FeeStat('Balance Due', 'UGX ${_fmt(balance)}', balance > 0 ? AppColors.warning : AppColors.success),
                          ],
                        ),
                        if (billed > 0) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: AppColors.surface3,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${(progress * 100).toStringAsFixed(0)}% paid',
                                  style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
                              Text('${((1 - progress) * 100).toStringAsFixed(0)}% remaining',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08);
                },
              ),

              const SizedBox(height: 20),

              // ── Invoices ──────────────────────────────────────────────────────
              const SectionHeader(title: 'Invoices').animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 12),

              invoicesAsync.when(
                loading: () => Column(children: List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerCard(height: 72),
                ))),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Could not load invoices', style: TextStyle(color: AppColors.textSecondary))),
                ),
                data: (invoices) {
                  if (invoices.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: const Center(
                        child: Column(children: [
                          Icon(Icons.receipt_long_outlined, color: AppColors.textHint, size: 36),
                          SizedBox(height: 8),
                          Text('No invoices yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ]),
                      ),
                    );
                  }
                  return Column(
                    children: invoices.asMap().entries.map((e) {
                      final inv    = e.value as Map;
                      final i      = e.key;
                      final status = inv['status']?.toString() ?? 'pending';
                      final term   = inv['term']?.toString() ?? inv['description']?.toString() ?? 'Invoice';
                      final total  = (inv['total_amount'] as num?)?.toDouble() ?? 0;
                      final paid   = (inv['paid_amount']  as num?)?.toDouble() ?? 0;
                      final bal    = (total - paid).clamp(0.0, double.infinity);
                      final color  = _statusColor(status);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(width: 4, height: 52,
                                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(term.isNotEmpty ? term : 'Invoice #${inv['id']}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const SizedBox(height: 3),
                                    Text('UGX ${_fmt(total)}  •  Paid: UGX ${_fmt(paid)}  •  Balance: UGX ${_fmt(bal)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              StatusBadge(label: status[0].toUpperCase() + status.substring(1), color: color),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 150 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ── Payment History ───────────────────────────────────────────────
              const SectionHeader(title: 'Payment History').animate(delay: 350.ms).fadeIn(),
              const SizedBox(height: 12),

              paymentsAsync.when(
                loading: () => Column(children: List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerCard(height: 72),
                ))),
                error: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Could not load payments', style: TextStyle(color: AppColors.textSecondary))),
                ),
                data: (payments) {
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
                    );
                  }
                  return Column(
                    children: payments.asMap().entries.map((e) {
                      final p      = e.value as Map;
                      final i      = e.key;
                      final method = p['payment_method']?.toString() ?? 'Cash';
                      final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                      final date   = p['payment_date']?.toString() ?? p['created_at']?.toString() ?? '';
                      final color  = _methodColor(method);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(_methodIcon(method), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (date.isNotEmpty)
                                      Text(_fmtDate(date), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 3),
                                    StatusBadge(label: method[0].toUpperCase() + method.substring(1), color: color),
                                  ],
                                ),
                              ),
                              Text('UGX ${_fmt(amount)}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 400 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _FeeStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center,
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ],
  );
}
