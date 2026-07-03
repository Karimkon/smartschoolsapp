import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

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
                  final billed  = toD(s['billed'], 0);
                  final paid    = toD(s['paid']  , 0);
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
                itemBuilder: (context, i) {
                  final inv     = Map<String, dynamic>.from(invoices[i] as Map);
                  final status  = inv['status']?.toString() ?? 'pending';
                  final color   = _statusColor(status);
                  final total   = toD(inv['total_amount'], 0);
                  final paid    = toD(inv['paid_amount'], 0);
                  final balance = (total - paid).clamp(0.0, double.infinity);
                  final due     = inv['due_date']?.toString() ?? '';
                  final invNo   = inv['invoice_number']?.toString() ?? '';
                  final student = inv['student_name']?.toString() ?? '';
                  final cls     = inv['class_name']?.toString() ?? '';
                  final isPaid  = status.toLowerCase() == 'paid';

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
                          Text(_fmtUGX(total),
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          StatusBadge(
                              label: status[0].toUpperCase() + status.substring(1),
                              color: color),
                          if (!isPaid) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final ok = await showModalBottomSheet<bool>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _CollectPaymentSheet(
                                    invoiceId: inv['id'] as int,
                                    studentName: student,
                                    balance: balance,
                                  ),
                                );
                                if (ok == true) {
                                  ref.invalidate(feesInvoicesProvider);
                                  ref.invalidate(feesPaymentsProvider);
                                  ref.invalidate(feesSummaryProvider);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.success.withOpacity(0.4)),
                                ),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.add_rounded, size: 12, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text('Collect',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                ]),
                              ),
                            ),
                          ],
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
              final amount  = toD(p['amount'], 0);
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

// ── Collect Payment Sheet ─────────────────────────────────────────────────────

class _CollectPaymentSheet extends StatefulWidget {
  final int    invoiceId;
  final String studentName;
  final double balance;

  const _CollectPaymentSheet({
    required this.invoiceId,
    required this.studentName,
    required this.balance,
  });

  @override
  State<_CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends State<_CollectPaymentSheet> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String _method    = 'cash';
  bool   _saving    = false;

  final _methods = ['cash', 'bank', 'mobile_money'];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.balance > 0
        ? widget.balance.toStringAsFixed(0)
        : '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _collect() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid amount'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().post('/fees/payments', data: {
        'fee_invoice_id': widget.invoiceId,
        'amount':         amount,
        'payment_method': _method,
        if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment of ${_fmtUGX(amount)} recorded'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${e.toString().replaceAll('DioException', '').trim()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  String _methodLabel(String m) {
    switch (m) {
      case 'mobile_money': return 'Mobile Money';
      case 'bank':         return 'Bank Transfer';
      default:             return 'Cash';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Collect Payment',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                    Text(widget.studentName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ]),
                ),
              ]),
              if (widget.balance > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Text('Balance due: ${_fmtUGX(widget.balance)}',
                        style: const TextStyle(
                            color: AppColors.warning, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Amount (UGX) *',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixText: 'UGX ',
                  prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Method',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _method,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _methods.map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(_methodLabel(m)),
                    )).toList(),
                    onChanged: (v) => setState(() => _method = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Notes (optional)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Receipt no, remarks...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(label: 'Record Payment', loading: _saving, onTap: _collect),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
