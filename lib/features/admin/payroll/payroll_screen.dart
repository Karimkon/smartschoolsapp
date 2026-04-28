import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _PayrollRecord {
  final int id;
  final String name, designation, initials;
  final double grossSalary, deductions;
  final Color avatarColor;
  bool isPaid;

  _PayrollRecord({
    required this.id,
    required this.name,
    required this.designation,
    required this.initials,
    required this.grossSalary,
    required this.deductions,
    required this.avatarColor,
    this.isPaid = false,
  });

  double get netPay => grossSalary - deductions;
}

final List<_PayrollRecord> _mockPayroll = [
  _PayrollRecord(id: 1, name: 'Alice Mensah',     designation: 'Senior Teacher',    initials: 'AM', grossSalary: 85000, deductions: 12750, avatarColor: AppColors.roleTeacher,    isPaid: true),
  _PayrollRecord(id: 2, name: 'Brian Osei',        designation: 'Mathematics Tutor', initials: 'BO', grossSalary: 72000, deductions: 10800, avatarColor: AppColors.primary,         isPaid: true),
  _PayrollRecord(id: 3, name: 'Chidi Okonkwo',     designation: 'Science Teacher',   initials: 'CO', grossSalary: 78000, deductions: 11700, avatarColor: AppColors.accent,          isPaid: false),
  _PayrollRecord(id: 4, name: 'Diana Kamau',       designation: 'English Teacher',   initials: 'DK', grossSalary: 74000, deductions: 11100, avatarColor: AppColors.roleParent,       isPaid: false),
  _PayrollRecord(id: 5, name: 'Emmanuel Ssali',    designation: 'PE Instructor',     initials: 'ES', grossSalary: 65000, deductions: 9750,  avatarColor: AppColors.roleAccountant,   isPaid: true),
  _PayrollRecord(id: 6, name: 'Fatima Hassan',     designation: 'Admin Officer',     initials: 'FH', grossSalary: 60000, deductions: 9000,  avatarColor: AppColors.warning,         isPaid: false),
  _PayrollRecord(id: 7, name: 'George Weru',       designation: 'ICT Coordinator',   initials: 'GW', grossSalary: 80000, deductions: 12000, avatarColor: AppColors.roleTeacher,    isPaid: true),
  _PayrollRecord(id: 8, name: 'Halima Juma',       designation: 'Librarian',         initials: 'HJ', grossSalary: 55000, deductions: 8250,  avatarColor: AppColors.roleLibrarian,   isPaid: false),
];

String _fmt(double v) {
  if (v >= 1000000) return 'UGX ${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000)    return 'UGX ${(v / 1000).toStringAsFixed(0)}K';
  return 'UGX ${v.toStringAsFixed(0)}';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminPayrollScreen extends StatefulWidget {
  const AdminPayrollScreen({super.key});

  @override
  State<AdminPayrollScreen> createState() => _AdminPayrollScreenState();
}

class _AdminPayrollScreenState extends State<AdminPayrollScreen> {
  late List<_PayrollRecord> _records;
  DateTime _selectedMonth = DateTime(2025, 4);

  @override
  void initState() {
    super.initState();
    _records = List.from(_mockPayroll);
  }

  void _prevMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
  void _nextMonth() => setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));

  String get _monthLabel {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  double get _totalNet   => _records.fold(0.0, (s, r) => s + r.netPay);
  double get _totalPaid  => _records.where((r) => r.isPaid).fold(0.0, (s, r) => s + r.netPay);
  double get _totalPending => _records.where((r) => !r.isPaid).fold(0.0, (s, r) => s + r.netPay);
  int    get _paidCount  => _records.where((r) => r.isPaid).length;

  void _payRecord(int id) {
    setState(() {
      final idx = _records.indexWhere((r) => r.id == id);
      if (idx != -1) _records[idx].isPaid = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payment processed successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showGenerateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Generate Payroll', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Generate payroll records for all staff for $_monthLabel?\n\nThis will create ${_records.length} payroll entries.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payroll generated for $_monthLabel'),
                  backgroundColor: AppColors.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Generate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Payroll', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGenerateDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: const Text('Generate Payroll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          StatCard(label: 'Total Payroll',  value: _fmt(_totalNet),     icon: Icons.account_balance_wallet_rounded, color: AppColors.primary,  index: 0),
                          StatCard(label: 'Paid',           value: _fmt(_totalPaid),    icon: Icons.check_circle_rounded,          color: AppColors.success,  index: 1),
                          StatCard(label: 'Pending',        value: _fmt(_totalPending), icon: Icons.pending_rounded,               color: AppColors.warning,  index: 2),
                          StatCard(label: 'Staff Count',    value: '${_records.length}',icon: Icons.people_alt_rounded,            color: AppColors.accent,   index: 3),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Month Selector
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: _prevMonth,
                              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 28),
                            ),
                            Column(
                              children: [
                                Text(_monthLabel, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                                Text('${_paidCount}/${_records.length} paid', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                            IconButton(
                              onPressed: _nextMonth,
                              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 28),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),

                      const SectionHeader(title: 'Staff Payroll'),
                      const SizedBox(height: 12),

                      // Payroll List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final r = _records[i];
                          return _PayrollCard(
                            record: r,
                            onPay: () => _payRecord(r.id),
                          ).animate(delay: Duration(milliseconds: i * 60))
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Net This Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text(_fmt(_totalNet), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Text('$_paidCount Paid', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payroll Card ──────────────────────────────────────────────────────────────

class _PayrollCard extends StatelessWidget {
  final _PayrollRecord record;
  final VoidCallback onPay;

  const _PayrollCard({required this.record, required this.onPay});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              AvatarWidget(initials: record.initials, color: record.avatarColor, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(record.designation, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(
                label: record.isPaid ? 'Paid' : 'Pending',
                color: record.isPaid ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SalaryItem(label: 'Gross', value: _fmt(record.grossSalary), color: AppColors.textPrimary)),
              Container(width: 1, height: 32, color: Colors.white.withOpacity(0.08)),
              Expanded(child: _SalaryItem(label: 'Deductions', value: _fmt(record.deductions), color: AppColors.error)),
              Container(width: 1, height: 32, color: Colors.white.withOpacity(0.08)),
              Expanded(child: _SalaryItem(label: 'Net Pay', value: _fmt(record.netPay), color: AppColors.accent)),
            ],
          ),
          if (!record.isPaid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payments_rounded, size: 16),
                label: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.success,
                  side: const BorderSide(color: AppColors.success),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalaryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SalaryItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
      ],
    );
  }
}
