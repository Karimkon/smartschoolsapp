import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final feesSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/fees/summary');
  return Map<String, dynamic>.from(res.data as Map);
});

final feesInvoicesProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, queryString) async {
  final res = await ApiService().get('/fees/invoices$queryString');
  return Map<String, dynamic>.from(res.data as Map);
});

final feesPaymentsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/fees/payments');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtUGX(double v) {
  if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
  return 'UGX ${v.toStringAsFixed(0)}';
}

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'paid':    return AppColors.success;
    case 'partial': return AppColors.primary;
    case 'pending': return AppColors.warning;
    case 'overdue': return AppColors.error;
    default:        return AppColors.textSecondary;
  }
}

const _statusFilters = ['All', 'Pending', 'Partial', 'Paid', 'Overdue'];

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminFeesScreen extends ConsumerStatefulWidget {
  const AdminFeesScreen({super.key});
  @override
  ConsumerState<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends ConsumerState<AdminFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _invoiceQuery =>
      _statusFilter == 'All' ? '' : '?status=${_statusFilter.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(feesSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fee Management',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(feesSummaryProvider);
              ref.invalidate(feesInvoicesProvider);
              ref.invalidate(feesPaymentsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Invoices'), Tab(text: 'Payments')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Summary cards ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: summaryAsync.when(
                loading: () => Row(children: const [
                  Expanded(child: ShimmerCard(height: 80)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerCard(height: 80)),
                  SizedBox(width: 10),
                  Expanded(child: ShimmerCard(height: 80)),
                ]),
                error: (_, __) => const SizedBox.shrink(),
                data: (d) {
                  final s       = d['summary'] as Map? ?? {};
                  final billed  = (s['billed'] as num?)?.toDouble() ?? 0;
                  final paid    = (s['paid']   as num?)?.toDouble() ?? 0;
                  final pending = (billed - paid).clamp(0.0, double.infinity);
                  return Row(children: [
                    Expanded(child: _SummaryCard('Billed',    _fmtUGX(billed),  AppColors.primary, Icons.receipt_long_rounded,  0)),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryCard('Collected', _fmtUGX(paid),    AppColors.success, Icons.check_circle_rounded,   1)),
                    const SizedBox(width: 10),
                    Expanded(child: _SummaryCard('Pending',   _fmtUGX(pending), AppColors.warning, Icons.pending_rounded,        2)),
                  ]);
                },
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab views ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InvoicesTab(
                    queryString:     _invoiceQuery,
                    statusFilter:    _statusFilter,
                    onFilterChanged: (v) => setState(() => _statusFilter = v),
                  ),
                  const _PaymentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final int index;
  const _SummaryCard(this.label, this.value, this.color, this.icon, this.index);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ]),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.1);
  }
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends ConsumerWidget {
  final String queryString;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;

  const _InvoicesTab({
    required this.queryString,
    required this.statusFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feesInvoicesProvider(queryString));

    return Column(children: [
      // Filter chips
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f   = _statusFilters[i];
              final sel = f == statusFilter;
              return GestureDetector(
                onTap: () => onFilterChanged(f),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.primary : Colors.white.withOpacity(0.07)),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : AppColors.textSecondary,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            },
          ),
        ),
      ),

      // List
      Expanded(
        child: async.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: 5,
            itemBuilder: (_, __) =>
                const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 80)),
          ),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load invoices',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => ref.refresh(feesInvoicesProvider(queryString)),
                  child: const Text('Retry')),
            ]),
          ),
          data: (data) {
            final invoices = (data['data'] as List?) ?? [];
            if (invoices.isEmpty) {
              return const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.textHint, size: 48),
                  SizedBox(height: 12),
                  Text('No invoices found',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface1,
              onRefresh: () => ref.refresh(feesInvoicesProvider(queryString).future),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: invoices.length,
                itemBuilder: (_, i) {
                  final inv    = invoices[i] as Map;
                  final status = inv['status']?.toString() ?? 'pending';
                  final color  = _statusColor(status);
                  final amount = (inv['total_amount'] as num?)?.toDouble() ?? 0;
                  final due    = inv['due_date']?.toString() ?? '';
                  final invNo  = inv['invoice_number']?.toString() ?? '';
                  final student = inv['student_name']?.toString() ?? '';
                  final cls    = inv['class_name']?.toString() ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(
                          width: 4,
                          height: 56,
                          decoration: BoxDecoration(
                              color: color, borderRadius: BorderRadius.circular(4)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(student,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            if (cls.isNotEmpty)
                              Text(cls,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.tag_rounded, size: 10, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Text(invNo,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                              if (due.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('Due: $due',
                                    style: const TextStyle(
                                        fontSize: 10, color: AppColors.textHint)),
                              ],
                            ]),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(_fmtUGX(amount),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          StatusBadge(
                              label: status[0].toUpperCase() + status.substring(1),
                              color: color),
                        ]),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab();

  Color _methodColor(String m) {
    switch (m.toLowerCase()) {
      case 'cash': return AppColors.success;
      case 'momo':
      case 'mobile_money': return AppColors.accent;
      case 'bank':
      case 'bank_transfer': return AppColors.primary;
      default: return AppColors.textSecondary;
    }
  }

  IconData _methodIcon(String m) {
    switch (m.toLowerCase()) {
      case 'cash':         return Icons.payments_rounded;
      case 'momo':
      case 'mobile_money': return Icons.phone_android_rounded;
      case 'bank':
      case 'bank_transfer': return Icons.account_balance_rounded;
      default:             return Icons.payment_rounded;
    }
  }

  String _methodLabel(String m) {
    switch (m.toLowerCase()) {
      case 'mobile_money': return 'MoMo';
      case 'bank_transfer': return 'Bank';
      default: return m[0].toUpperCase() + m.substring(1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(feesPaymentsProvider);

    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: 5,
        itemBuilder: (_, __) =>
            const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 72)),
      ),
      error: (e, _) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load payments',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => ref.refresh(feesPaymentsProvider),
              child: const Text('Retry')),
        ]),
      ),
      data: (data) {
        final payments = (data['data'] as List?) ?? [];
        if (payments.isEmpty) {
          return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.payments_rounded, color: AppColors.textHint, size: 48),
              SizedBox(height: 12),
              Text('No payments recorded',
                  style: TextStyle(color: AppColors.textSecondary)),
            ]),
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface1,
          onRefresh: () => ref.refresh(feesPaymentsProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: payments.length,
            itemBuilder: (_, i) {
              final p       = payments[i] as Map;
              final method  = p['payment_method']?.toString() ?? 'cash';
              final color   = _methodColor(method);
              final amount  = (p['amount'] as num?)?.toDouble() ?? 0;
              final date    = p['payment_date']?.toString() ?? '';
              final receipt = p['receipt_number']?.toString() ?? '';
              final student = p['student_name']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(_methodIcon(method), color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(student,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          StatusBadge(label: _methodLabel(method), color: color),
                          const SizedBox(width: 8),
                          Text(date,
                              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ]),
                        if (receipt.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Rcpt: $receipt',
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ],
                      ]),
                    ),
                    Text(_fmtUGX(amount),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
            },
          ),
        );
      },
    );
  }
}
