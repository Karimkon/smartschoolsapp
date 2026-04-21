import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Invoice {
  final int id;
  final String student, term, dueDate, status, className;
  final double amount, paid;

  const _Invoice({
    required this.id, required this.student, required this.term,
    required this.dueDate, required this.status, required this.className,
    required this.amount, required this.paid,
  });

  double get balance => amount - paid;
  bool get isOverdue => status == 'Overdue';
}

class _Payment {
  final String student, date, method, reference;
  final double amount;
  const _Payment({required this.student, required this.date, required this.method, required this.reference, required this.amount});
}

class _Bursary {
  final String student, sponsor, status;
  final double amount;
  const _Bursary({required this.student, required this.sponsor, required this.status, required this.amount});
}

const _invoices = [
  _Invoice(id: 1,  student: 'Amara Osei',     term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Paid',    className: 'Grade 7A',  amount: 45000, paid: 45000),
  _Invoice(id: 2,  student: 'Brian Mwangi',   term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Partial', className: 'Grade 8B',  amount: 50000, paid: 25000),
  _Invoice(id: 3,  student: 'Chidi Okonkwo',  term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Pending', className: 'Grade 9A',  amount: 47500, paid: 0),
  _Invoice(id: 4,  student: 'Diana Kamau',    term: 'Term 2 2025', dueDate: 'Apr 01, 2025', status: 'Overdue', className: 'Grade 7B',  amount: 48000, paid: 0),
  _Invoice(id: 5,  student: 'Emmanuel Ssali', term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Paid',    className: 'Grade 10A', amount: 55000, paid: 55000),
  _Invoice(id: 6,  student: 'Fatima Hassan',  term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Partial', className: 'Grade 8A',  amount: 46000, paid: 23000),
  _Invoice(id: 7,  student: 'George Weru',    term: 'Term 2 2025', dueDate: 'Mar 15, 2025', status: 'Overdue', className: 'Grade 11B', amount: 49000, paid: 10000),
  _Invoice(id: 8,  student: 'Halima Juma',    term: 'Term 2 2025', dueDate: 'May 01, 2025', status: 'Pending', className: 'Grade 9B',  amount: 45500, paid: 0),
];

const _payments = [
  _Payment(student: 'Amara Osei',     date: 'Apr 18, 2025', method: 'MoMo',  reference: 'TXN-001-2025', amount: 45000),
  _Payment(student: 'Emmanuel Ssali', date: 'Apr 15, 2025', method: 'Bank',   reference: 'TXN-002-2025', amount: 55000),
  _Payment(student: 'Fatima Hassan',  date: 'Apr 10, 2025', method: 'Cash',   reference: 'TXN-003-2025', amount: 23000),
  _Payment(student: 'Brian Mwangi',   date: 'Mar 28, 2025', method: 'MoMo',  reference: 'TXN-004-2025', amount: 25000),
  _Payment(student: 'George Weru',    date: 'Mar 20, 2025', method: 'Bank',   reference: 'TXN-005-2025', amount: 10000),
  _Payment(student: 'Halima Juma',    date: 'Mar 05, 2025', method: 'Cash',   reference: 'TXN-006-2025', amount: 0),
];

const _bursaries = [
  _Bursary(student: 'Diana Kamau',   sponsor: 'Gov Education Fund',  status: 'Approved', amount: 48000),
  _Bursary(student: 'Chidi Okonkwo', sponsor: 'Community Trust',     status: 'Pending',  amount: 25000),
  _Bursary(student: 'George Weru',   sponsor: 'NGO Scholars Program', status: 'Approved', amount: 39000),
  _Bursary(student: 'Halima Juma',   sponsor: 'School Welfare Fund',  status: 'Review',   amount: 45500),
];

const _statusFilters   = ['All', 'Pending', 'Partial', 'Paid', 'Overdue'];
const _methodFilters   = ['All', 'Cash', 'MoMo', 'Bank'];

// ── Screen ────────────────────────────────────────────────────────────────────

class AccountantFeesScreen extends StatefulWidget {
  const AccountantFeesScreen({super.key});

  @override
  State<AccountantFeesScreen> createState() => _AccountantFeesScreenState();
}

class _AccountantFeesScreenState extends State<AccountantFeesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _statusFilter = 'All';
  String _methodFilter = 'All';
  bool _sortByOverdue  = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_Invoice> get _filteredInvoices {
    var list = _invoices.where((inv) => _statusFilter == 'All' || inv.status == _statusFilter).toList();
    if (_sortByOverdue) {
      list.sort((a, b) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        return 0;
      });
    }
    return list;
  }

  List<_Payment> get _filteredPayments => _payments.where((p) =>
    _methodFilter == 'All' || p.method == _methodFilter
  ).toList();

  double get _totalBilled    => _invoices.fold(0, (s, i) => s + i.amount);
  double get _totalCollected => _invoices.fold(0, (s, i) => s + i.paid);
  double get _totalPending   => _totalBilled - _totalCollected;

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
        title: const Text('Finance Management', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.roleAccountant,
          labelColor: AppColors.roleAccountant,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [Tab(text: 'Invoices'), Tab(text: 'Payments'), Tab(text: 'Bursary')],
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
                  Expanded(child: _SummaryCard('Total Billed',    'KES ${(_totalBilled / 1000).toStringAsFixed(0)}K',    AppColors.roleAccountant, Icons.receipt_long_rounded,            0)),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryCard('Collected',       'KES ${(_totalCollected / 1000).toStringAsFixed(0)}K', AppColors.success,        Icons.check_circle_rounded,            1)),
                  const SizedBox(width: 8),
                  Expanded(child: _SummaryCard('Outstanding',     'KES ${(_totalPending / 1000).toStringAsFixed(0)}K',   AppColors.warning,        Icons.pending_actions_rounded,         2)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InvoicesTab(
                    invoices: _filteredInvoices,
                    statusFilter: _statusFilter,
                    sortByOverdue: _sortByOverdue,
                    onFilterChanged: (v) => setState(() => _statusFilter = v),
                    onSortToggle: () => setState(() => _sortByOverdue = !_sortByOverdue),
                  ),
                  _PaymentsTab(
                    payments: _filteredPayments,
                    methodFilter: _methodFilter,
                    onMethodChanged: (v) => setState(() => _methodFilter = v),
                  ),
                  _BursaryTab(bursaries: _bursaries),
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
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      ],
    ),
  ).animate(delay: Duration(milliseconds: index * 80)).fadeIn().slideY(begin: 0.1);
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  final List<_Invoice> invoices;
  final String statusFilter;
  final bool sortByOverdue;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSortToggle;

  const _InvoicesTab({
    required this.invoices, required this.statusFilter, required this.sortByOverdue,
    required this.onFilterChanged, required this.onSortToggle,
  });

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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.roleAccountant : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppColors.roleAccountant : Colors.white.withOpacity(0.07)),
                          ),
                          child: Text(f, style: TextStyle(fontSize: 11, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onSortToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sortByOverdue ? AppColors.error.withOpacity(0.2) : AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sortByOverdue ? AppColors.error : Colors.white.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 14, color: sortByOverdue ? AppColors.error : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('Overdue', style: TextStyle(fontSize: 11, color: sortByOverdue ? AppColors.error : AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
            itemCount: invoices.length,
            itemBuilder: (_, i) {
              final inv = invoices[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  color: inv.isOverdue ? AppColors.error.withOpacity(0.05) : null,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4, height: 60,
                            decoration: BoxDecoration(color: _statusColor(inv.status), borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(inv.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                                    StatusBadge(label: inv.status, color: _statusColor(inv.status)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text('${inv.className}  •  ${inv.term}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text('Due: ${inv.dueDate}', style: TextStyle(fontSize: 10, color: inv.isOverdue ? AppColors.error : AppColors.textHint)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _AmtCell('Billed',  'KES ${inv.amount.toStringAsFixed(0)}', AppColors.textPrimary),
                          _AmtCell('Paid',    'KES ${inv.paid.toStringAsFixed(0)}',   AppColors.success),
                          _AmtCell('Balance', 'KES ${inv.balance.toStringAsFixed(0)}', inv.balance > 0 ? AppColors.warning : AppColors.success),
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

class _PaymentsTab extends StatelessWidget {
  final List<_Payment> payments;
  final String methodFilter;
  final ValueChanged<String> onMethodChanged;
  const _PaymentsTab({required this.payments, required this.methodFilter, required this.onMethodChanged});

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
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? _methodColor(m) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _methodColor(m) : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(m, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: _methodColor(p.method).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_methodIcon(p.method), color: _methodColor(p.method), size: 22),
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
                            const SizedBox(height: 2),
                            Text(p.reference, style: const TextStyle(fontSize: 10, color: AppColors.textHint, fontFamily: 'monospace')),
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
          ),
        ),
      ],
    );
  }
}

// ── Bursary Tab ───────────────────────────────────────────────────────────────

class _BursaryTab extends StatelessWidget {
  final List<_Bursary> bursaries;
  const _BursaryTab({required this.bursaries});

  Color _statusColor(String s) {
    switch (s) {
      case 'Approved': return AppColors.success;
      case 'Pending':  return AppColors.warning;
      case 'Review':   return AppColors.primary;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBursary = bursaries.fold<double>(0, (s, b) => s + b.amount);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: bursaries.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              gradient: const LinearGradient(colors: [AppColors.surface1, AppColors.surface2]),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.roleAccountant.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.volunteer_activism_rounded, color: AppColors.roleAccountant, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Bursary Allocated', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('KES ${totalBursary.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.roleAccountant)),
                      Text('${bursaries.length} student${bursaries.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(),
          );
        }

        final b = bursaries[i - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _statusColor(b.status).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.school_rounded, color: AppColors.textSecondary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.student, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(b.sponsor, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('KES ${b.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    StatusBadge(label: b.status, color: _statusColor(b.status)),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
      },
    );
  }
}
