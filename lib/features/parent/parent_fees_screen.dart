import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final parentChildrenProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/parent/children');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

final parentFeesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, childId) async {
  final res = await ApiService().get('/parent/children/$childId/fees');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ParentFeesScreen extends ConsumerStatefulWidget {
  const ParentFeesScreen({super.key});

  @override
  ConsumerState<ParentFeesScreen> createState() => _ParentFeesScreenState();
}

class _ParentFeesScreenState extends ConsumerState<ParentFeesScreen>
    with SingleTickerProviderStateMixin {
  int? _selectedChildId;
  late TabController _tabs;

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
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    return v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':    return AppColors.success;
      case 'partial': return AppColors.warning;
      case 'overdue': return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Text('School Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            ),

            // Child selector
            childrenAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerCard(height: 60)),
              error: (_, __) => const SizedBox(),
              data: (children) {
                if (_selectedChildId == null && children.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedChildId = children.first['id'] as int);
                  });
                }
                if (children.length <= 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: children.map((c) {
                        final cid   = c['id'] as int;
                        final name  = '${c['first_name']} ${c['last_name']}'.trim();
                        final sel   = _selectedChildId == cid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedChildId = cid),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(name, style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            // Content
            Expanded(
              child: _selectedChildId == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildFeeContent(_selectedChildId!),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildFeeContent(int childId) {
    final feesAsync = ref.watch(parentFeesProvider(childId));

    return feesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load fees', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(parentFeesProvider(childId)),
          child: const Text('Retry'),
        ),
      ])),
      data: (data) {
        final summary  = data['summary'] as Map? ?? {};
        final invoices = (data['invoices'] as List?) ?? [];
        final payments = (data['payments'] as List?) ?? [];
        final billed   = (summary['billed']  as num?)?.toDouble() ?? 0;
        final paid     = (summary['paid']    as num?)?.toDouble() ?? 0;
        final balance  = (summary['balance'] as num?)?.toDouble() ?? 0;

        return Column(children: [
          // Summary card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _SumCol('Total Billed', 'UGX ${_fmt(billed)}', AppColors.textPrimary),
                  _SumCol('Paid', 'UGX ${_fmt(paid)}', AppColors.success),
                  _SumCol('Balance', 'UGX ${_fmt(balance)}', balance > 0 ? AppColors.warning : AppColors.success),
                ]),
                if (billed > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (paid / billed).clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: AppColors.surface3,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${((paid / billed) * 100).toStringAsFixed(0)}% paid',
                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ]),
            ).animate().fadeIn(),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(12)),
              child: TabBar(
                controller: _tabs,
                indicatorColor: AppColors.roleParent,
                labelColor: AppColors.roleParent,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [Tab(text: 'Invoices'), Tab(text: 'Payments')],
              ),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(controller: _tabs, children: [
              // Invoices
              invoices.isEmpty
                  ? const Center(child: Text('No invoices', style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: invoices.length,
                      itemBuilder: (_, i) {
                        final inv    = invoices[i] as Map;
                        final status = inv['status']?.toString() ?? 'pending';
                        final total  = (inv['total_amount'] as num?)?.toDouble() ?? 0;
                        final paidA  = (inv['paid_amount']  as num?)?.toDouble() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Expanded(child: Text(inv['invoice_number']?.toString() ?? 'Invoice',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                                StatusBadge(label: status.toUpperCase(), color: _statusColor(status)),
                              ]),
                              const SizedBox(height: 8),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                _FeeItem('Billed',  'UGX ${_fmt(total)}'),
                                _FeeItem('Paid',    'UGX ${_fmt(paidA)}'),
                                _FeeItem('Balance', 'UGX ${_fmt(total - paidA)}'),
                              ]),
                              if (inv['due_date'] != null) ...[
                                const SizedBox(height: 6),
                                Text('Due: ${inv['due_date']}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                              ],
                              // Pay button for unpaid invoices
                              if (status != 'paid' && (total - paidA) > 0) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showPayDialog(context, inv, total - paidA),
                                    icon: const Icon(Icons.payment_rounded, size: 16),
                                    label: Text('Pay UGX ${_fmt(total - paidA)}'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.roleParent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
                        );
                      },
                    ),

              // Payments
              payments.isEmpty
                  ? const Center(child: Text('No payments yet', style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: payments.length,
                      itemBuilder: (_, i) {
                        final p      = payments[i] as Map;
                        final amount = (p['amount'] as num?)?.toDouble() ?? 0;
                        final method = p['payment_method']?.toString() ?? 'Cash';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('UGX ${_fmt(amount)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success)),
                                const SizedBox(height: 3),
                                Text('$method  •  ${p['payment_date'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                if (p['receipt_number'] != null)
                                  Text('Receipt: ${p['receipt_number']}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                              ])),
                            ]),
                          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(),
                        );
                      },
                    ),
            ]),
          ),
        ]);
      },
    );
  }

  void _showPayDialog(BuildContext context, Map inv, double balance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pay Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text('Invoice: ${inv['invoice_number']}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text('Amount Due: UGX ${_fmt(balance)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.warning)),
          const SizedBox(height: 20),
          const Text('Payment Options', style: TextStyle(fontSize: 13, color: AppColors.textHint)),
          const SizedBox(height: 12),
          _PayOption(Icons.phone_android_rounded, 'Mobile Money (MTN/Airtel)', 'Pay via Mobile Money', AppColors.warning, () => Navigator.pop(context)),
          const SizedBox(height: 10),
          _PayOption(Icons.account_balance_rounded, 'Bank Transfer', 'Pay via Bank', AppColors.primary, () => Navigator.pop(context)),
          const SizedBox(height: 10),
          _PayOption(Icons.money_rounded, 'Cash at School', 'Pay at the school office', AppColors.success, () => Navigator.pop(context)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _SumCol extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumCol(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

class _FeeItem extends StatelessWidget {
  final String label, value;
  const _FeeItem(this.label, this.value);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    ],
  );
}

class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _PayOption(this.icon, this.title, this.subtitle, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Icon(Icons.arrow_forward_ios_rounded, color: color, size: 14),
      ]),
    ),
  );
}
