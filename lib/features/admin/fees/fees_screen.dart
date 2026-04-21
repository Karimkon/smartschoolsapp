import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Invoice {
  final int id;
  final String student, term, dueDate, status;
  final double amount;

  const _Invoice({
    required this.id, required this.student, required this.term,
    required this.dueDate, required this.status, required this.amount,
  });
}

class _Payment {
  final String student, date, method;
  final double amount;
  const _Payment({required this.student, required this.date, required this.method, required this.amount});
}

const _invoices = [
  _Invoice(id: 1, student: 'Amara Osei',     term: 'Term 1 2025', dueDate: 'Jan 15, 2025', status: 'Paid',    amount: 45000),
  _Invoice(id: 2, student: 'Brian Mwangi',   term: 'Term 1 2025', dueDate: 'Jan 15, 2025', status: 'Partial', amount: 50000),
  _Invoice(id: 3, student: 'Chidi Okonkwo',  term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Pending', amount: 47500),
  _Invoice(id: 4, student: 'Diana Kamau',    term: 'Term 2 2025', dueDate: 'Apr 01, 2025', status: 'Overdue', amount: 48000),
  _Invoice(id: 5, student: 'Emmanuel Ssali', term: 'Term 1 2025', dueDate: 'Jan 15, 2025', status: 'Paid',    amount: 55000),
  _Invoice(id: 6, student: 'Fatima Hassan',  term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Partial', amount: 46000),
  _Invoice(id: 7, student: 'George Weru',    term: 'Term 2 2025', dueDate: 'Mar 15, 2025', status: 'Overdue', amount: 49000),
  _Invoice(id: 8, student: 'Halima Juma',    term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Pending', amount: 45500),
];

const _payments = [
  _Payment(student: 'Amara Osei',     date: 'Apr 18, 2025', method: 'MoMo',  amount: 45000),
  _Payment(student: 'Emmanuel Ssali', date: 'Apr 15, 2025', method: 'Bank',   amount: 55000),
  _Payment(student: 'Fatima Hassan',  date: 'Apr 10, 2025', method: 'Cash',   amount: 23000),
  _Payment(student: 'Brian Mwangi',   date: 'Mar 28, 2025', method: 'MoMo',  amount: 25000),
  _Payment(student: 'Chidi Okonkwo',  date: 'Mar 20, 2025', method: 'Bank',   amount: 47500),
  _Payment(student: 'Halima Juma',    date: 'Mar 05, 2025', method: 'Cash',   amount: 10000),
];

const _statusFilters = ['All', 'Pending', 'Partial', 'Paid', 'Overdue'];

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminFeesScreen extends StatefulWidget {
  const AdminFeesScreen({super.key});

  @override
  State<AdminFeesScreen> createState() => _AdminFeesScreenState();
}

class _AdminFeesScreenState extends State<AdminFeesScreen> with SingleTickerProviderStateMixin {
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

  List<_Invoice> get _filteredInvoices => _invoices.where((inv) =>
    _statusFilter == 'All' || inv.status == _statusFilter
  ).toList();

  double get _totalBilled   => _invoices.fold(0, (s, i) => s + i.amount);
  double get _totalCollected => _payments.fold(0, (s, p) => s + p.amount);
  double get _totalPending  => _totalBilled - _totalCollected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fee Management', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
            // Summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(child: _SummaryCard('Total Billed', 'KES ${(_totalBilled / 1000).toStringAsFixed(0)}K', AppColors.primary, Icons.receipt_long_rounded, 0)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryCard('Collected', 'KES ${(_totalCollected / 1000).toStringAsFixed(0)}K', AppColors.success, Icons.check_circle_rounded, 1)),
                  const SizedBox(width: 10),
                  Expanded(child: _SummaryCard('Pending', 'KES ${(_totalPending / 1000).toStringAsFixed(0)}K', AppColors.warning, Icons.pending_rounded, 2)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InvoicesTab(
                    invoices: _filteredInvoices,
                    statusFilter: _statusFilter,
                    onFilterChanged: (v) => setState(() => _statusFilter = v),
                  ),
                  _PaymentsTab(payments: _payments),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.1);
  }
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  final List<_Invoice> invoices;
  final String statusFilter;
  final ValueChanged<String> onFilterChanged;
  const _InvoicesTab({required this.invoices, required this.statusFilter, required this.onFilterChanged});

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid':    return AppColors.success;
      case 'Partial': return AppColors.primary;
      case 'Pending': return AppColors.warning;
      case 'Overdue': return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                final f = _statusFilters[i];
                final sel = f == statusFilter;
                return GestureDetector(
                  onTap: () => onFilterChanged(f),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.primary : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(f, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: invoices.length,
            itemBuilder: (_, i) {
              final inv = invoices[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _statusColor(inv.status),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text(inv.term, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text('Due: ${inv.dueDate}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('KES ${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          StatusBadge(label: inv.status, color: _statusColor(inv.status)),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final List<_Payment> payments;
  const _PaymentsTab({required this.payments});

  Color _methodColor(String m) {
    switch (m) {
      case 'Cash': return AppColors.success;
      case 'MoMo': return AppColors.accent;
      case 'Bank': return AppColors.primary;
      default:     return AppColors.textSecondary;
    }
  }

  IconData _methodIcon(String m) {
    switch (m) {
      case 'Cash': return Icons.payments_rounded;
      case 'MoMo': return Icons.phone_android_rounded;
      case 'Bank': return Icons.account_balance_rounded;
      default:     return Icons.payment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: payments.length,
      itemBuilder: (_, i) {
        final p = payments[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _methodColor(p.method).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_methodIcon(p.method), color: _methodColor(p.method), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          StatusBadge(label: p.method, color: _methodColor(p.method)),
                          const SizedBox(width: 8),
                          Text(p.date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  'KES ${p.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
      },
    );
  }
}
