import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _feeSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/fees/summary');
  return Map<String, dynamic>.from(res.data as Map);
});

final _invoicesProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, status) async {
  final params = status == 'All' ? <String, dynamic>{} : {'status': status.toLowerCase()};
  final res = await ApiService().get('/fees/invoices', params: params);
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

final _paymentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/fees/payments');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

const _statusFilters = ['All', 'Pending', 'Partial', 'Paid', 'Overdue'];
const _methodFilters = ['All', 'Cash', 'Mobile Money', 'Bank'];

// ── Screen ────────────────────────────────────────────────────────────────────

class AccountantFeesScreen extends ConsumerStatefulWidget {
  const AccountantFeesScreen({super.key});

  @override
  ConsumerState<AccountantFeesScreen> createState() => _AccountantFeesScreenState();
}

class _AccountantFeesScreenState extends ConsumerState<AccountantFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _statusFilter = 'All';
  String _methodFilter = 'All';

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

  String _fmt(double v) {
    if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000)    return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
    return 'UGX ${v.toStringAsFixed(0)}';
  }

  String _fmtRaw(double v) {
    return v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(_feeSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Finance Management', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(_feeSummaryProvider);
              ref.invalidate(_invoicesProvider);
              ref.invalidate(_paymentsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.roleAccountant,
          labelColor: AppColors.roleAccountant,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Invoices'), Tab(text: 'Payments')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: summaryAsync.when(
                loading: () => Row(children: [
                  Expanded(child: ShimmerCard(height: 70)),
                  const SizedBox(width: 8),
                  Expanded(child: ShimmerCard(height: 70)),
                  const SizedBox(width: 8),
                  Expanded(child: ShimmerCard(height: 70)),
                ]),
                error: (_, __) => const SizedBox(),
                data: (s) {
                  final sum     = s['summary'] as Map? ?? {};
                  final billed  = (sum['billed']  as num?)?.toDouble() ?? 0;
                  final paid    = (sum['paid']    as num?)?.toDouble() ?? 0;
                  final pending = (billed - paid).clamp(0.0, double.infinity);
                  return Row(children: [
                    Expanded(child: _SummaryCard('Total Billed',  _fmt(billed),  AppColors.roleAccountant, Icons.receipt_long_rounded,  0)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard('Collected',     _fmt(paid),    AppColors.success,        Icons.check_circle_rounded,  1)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard('Outstanding',   _fmt(pending), AppColors.warning,        Icons.pending_actions_rounded, 2)),
                  ]);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InvoicesTab(
                    statusFilter: _statusFilter,
                    onFilterChanged: (v) => setState(() => _statusFilter = v),
                  ),
                  _PaymentsTab(
                    methodFilter: _methodFilter,
                    onMethodChanged: (v) => setState(() => _methodFilter = v),
                  ),
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
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    ),
  ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.1);
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends ConsumerWidget {
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  const _InvoicesTab({required this.statusFilter, required this.onFilterChanged});

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':    return AppColors.success;
      case 'partial': return AppColors.primary;
      case 'pending': return AppColors.warning;
      case 'overdue': return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(_invoicesProvider(statusFilter));

    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.roleAccountant : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.roleAccountant : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(f, style: TextStyle(
                        fontSize: 11,
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: invoicesAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
              children: List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerCard(height: 110),
              )),
            ),
            error: (e, _) => Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.textHint, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load invoices', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_invoicesProvider),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (invoices) {
              if (invoices.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    Text(
                      statusFilter == 'All' ? 'No invoices yet' : 'No $statusFilter invoices',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ]),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
                itemCount: invoices.length,
                itemBuilder: (_, i) {
                  final inv     = invoices[i] as Map;
                  final status  = inv['status']?.toString() ?? 'pending';
                  final student = inv['student_name']?.toString() ?? 'Unknown';
                  final cls     = inv['class_name']?.toString() ?? '';
                  final term    = inv['term']?.toString() ?? inv['description']?.toString() ?? '';
                  final due     = inv['due_date']?.toString() ?? '';
                  final total   = (inv['total_amount']  as num?)?.toDouble() ?? 0;
                  final paid    = (inv['paid_amount']   as num?)?.toDouble() ?? 0;
                  final balance = (total - paid).clamp(0.0, double.infinity);
                  final color   = _statusColor(status);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      color: status == 'overdue' ? AppColors.error.withOpacity(0.05) : null,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(width: 4, height: 60,
                                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(student,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                                      StatusBadge(label: status[0].toUpperCase() + status.substring(1), color: color),
                                    ]),
                                    const SizedBox(height: 3),
                                    Text([if (cls.isNotEmpty) cls, if (term.isNotEmpty) term].join('  •  '),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    if (due.isNotEmpty)
                                      Text('Due: ${_fmtDate(due)}',
                                          style: TextStyle(fontSize: 10,
                                              color: status == 'overdue' ? AppColors.error : AppColors.textHint)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _AmtCell('Billed',  'UGX ${_fmt(total)}',   AppColors.textPrimary),
                              _AmtCell('Paid',    'UGX ${_fmt(paid)}',    AppColors.success),
                              _AmtCell('Balance', 'UGX ${_fmt(balance)}', balance > 0 ? AppColors.warning : AppColors.success),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]}, ${dt.year}';
    } catch (_) { return d; }
  }
}

class _AmtCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AmtCell(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ],
  );
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  final String methodFilter;
  final ValueChanged<String> onMethodChanged;
  const _PaymentsTab({required this.methodFilter, required this.onMethodChanged});

  Color _methodColor(String m) {
    switch (m.toLowerCase()) {
      case 'cash':         return AppColors.success;
      case 'mobile_money':
      case 'momo':
      case 'mobile money': return AppColors.accent;
      case 'bank':         return AppColors.primary;
      default:             return AppColors.textSecondary;
    }
  }

  IconData _methodIcon(String m) {
    switch (m.toLowerCase()) {
      case 'cash':         return Icons.payments_rounded;
      case 'mobile_money':
      case 'momo':
      case 'mobile money': return Icons.phone_android_rounded;
      case 'bank':         return Icons.account_balance_rounded;
      default:             return Icons.payment_rounded;
    }
  }

  String _methodLabel(String m) {
    switch (m.toLowerCase()) {
      case 'mobile_money': return 'Mobile Money';
      default:             return m[0].toUpperCase() + m.substring(1);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  bool _matchesFilter(String method) {
    if (methodFilter == 'All') return true;
    return _methodLabel(method).toLowerCase() == methodFilter.toLowerCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(_paymentsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: _methodFilters.map((m) {
              final sel = m == methodFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onMethodChanged(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? _methodColor(m) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _methodColor(m) : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(m, style: TextStyle(
                        fontSize: 12,
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: paymentsAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
              children: List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerCard(height: 80),
              )),
            ),
            error: (e, _) => Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.textHint, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load payments', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(_paymentsProvider),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (allPayments) {
              final payments = allPayments
                  .where((p) => _matchesFilter((p as Map)['payment_method']?.toString() ?? ''))
                  .toList();

              if (payments.isEmpty) {
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.payments_outlined, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('No payments recorded yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                itemCount: payments.length,
                itemBuilder: (_, i) {
                  final p       = payments[i] as Map;
                  final name    = p['student_name']?.toString() ?? 'Unknown';
                  final method  = p['payment_method']?.toString() ?? 'Cash';
                  final amount  = (p['amount'] as num?)?.toDouble() ?? 0;
                  final date    = p['payment_date']?.toString() ?? p['created_at']?.toString() ?? '';
                  final ref_no  = p['reference']?.toString() ?? p['receipt_number']?.toString() ?? '';
                  final color   = _methodColor(method);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(_methodIcon(method), color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  StatusBadge(label: _methodLabel(method), color: color),
                                  const SizedBox(width: 8),
                                  if (date.isNotEmpty)
                                    Text(_fmtDate(date), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ]),
                                if (ref_no.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(ref_no, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                  ),
                              ],
                            ),
                          ),
                          Text('UGX ${_fmt(amount)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]}, ${dt.year}';
    } catch (_) { return d; }
  }
}
