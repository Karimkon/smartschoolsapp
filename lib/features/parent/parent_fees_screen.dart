import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

  static double _n(dynamic v) =>
      v == null ? 0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

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
                        final total  = _n(inv['total_amount']);
                        final paidA  = _n(inv['paid_amount']);
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
                        final amount = _n(p['amount']);
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
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(inv: inv, balance: balance, fmt: _fmt),
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

// ── Payment Sheet ─────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final Map inv;
  final double balance;
  final String Function(double) fmt;
  const _PaymentSheet({required this.inv, required this.balance, required this.fmt});
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  List<dynamic>? _methods;
  String? _currency;
  bool _loading = true;
  bool _initiating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final res = await ApiService().get('/parent/payment/methods');
      final data = Map<String, dynamic>.from(res.data as Map);
      setState(() {
        _methods  = List<dynamic>.from(data['methods'] ?? []);
        _currency = data['currency']?.toString() ?? 'UGX';
        _loading  = false;
      });
    } catch (_) {
      setState(() { _loading = false; _error = 'Could not load payment methods'; });
    }
  }

  Future<void> _inititateDpo() async {
    setState(() => _initiating = true);
    try {
      final res = await ApiService().post('/parent/payment/initiate', data: {
        'invoice_id': widget.inv['id'],
        'amount':     widget.balance,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final url  = data['payment_url']?.toString();
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().contains('422') ? 'Payment not configured' : 'Failed to initiate payment'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _initiating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pay Fees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Invoice: ${widget.inv['invoice_number'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 6),
          Text('${_currency ?? 'UGX'} ${widget.fmt(widget.balance)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.warning)),
        ]),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary))
        else if (_error != null)
          Text(_error!, style: const TextStyle(color: AppColors.error))
        else if (_methods != null) ...[
          const Text('Choose Payment Method',
              style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...(_methods!).map((m) {
            final method = Map<String, dynamic>.from(m as Map);
            final type   = method['type']?.toString() ?? 'none';
            final avail  = method['available'] == true;
            final name   = method['name']?.toString() ?? '';
            final desc   = method['description']?.toString() ?? '';
            final code   = method['school_code']?.toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: !avail ? null : () {
                  if (type == 'dpo') _inititateDpo();
                  if (type == 'schoolpay' && code != null) {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('School code copied!'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: avail ? AppColors.surface2 : AppColors.surface3,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: avail ? AppColors.roleParent.withOpacity(0.3) : Colors.white12,
                    ),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(
                        type == 'dpo'       ? Icons.credit_card_rounded
                            : type == 'schoolpay' ? Icons.phone_android_rounded
                            : Icons.info_rounded,
                        color: avail ? AppColors.roleParent : AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(name,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: avail ? AppColors.textPrimary : AppColors.textHint,
                          ))),
                      if (type == 'dpo' && _initiating)
                        const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.roleParent))
                      else if (avail)
                        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.roleParent, size: 14),
                    ]),
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                    if (code != null && type == 'schoolpay') ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.roleParent.withOpacity(0.4)),
                        ),
                        child: Row(children: [
                          Expanded(child: Text('School Code: $code',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.roleParent))),
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.textHint),
                        ]),
                      ),
                      const SizedBox(height: 4),
                      Text(method['instructions']?.toString() ?? '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                    ],
                  ]),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 8),
      ]),
    );
  }
}
