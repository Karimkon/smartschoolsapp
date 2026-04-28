import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Data models ───────────────────────────────────────────────────────────────
class _Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String status; // Approved | Pending | Rejected
  final String? notes;

  const _Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.status,
    this.notes,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────
final List<_Expense> _mockExpenses = [
  _Expense(
    id: 'e1',
    description: 'Electricity Bill — April',
    amount: 45000,
    category: 'Utilities',
    date: DateTime(2026, 4, 15),
    status: 'Approved',
    notes: 'Monthly electricity for main campus',
  ),
  _Expense(
    id: 'e2',
    description: 'Exercise Books Restock',
    amount: 12500,
    category: 'Stationery',
    date: DateTime(2026, 4, 14),
    status: 'Approved',
    notes: '500 exercise books for Grade 1–3',
  ),
  _Expense(
    id: 'e3',
    description: 'Classroom Roof Repair',
    amount: 85000,
    category: 'Maintenance',
    date: DateTime(2026, 4, 12),
    status: 'Pending',
    notes: 'Leaking roof in block B, 3 classrooms',
  ),
  _Expense(
    id: 'e4',
    description: 'Staff Canteen Supplies',
    amount: 22000,
    category: 'Food',
    date: DateTime(2026, 4, 10),
    status: 'Approved',
    notes: 'Weekly food supplies for staff canteen',
  ),
  _Expense(
    id: 'e5',
    description: 'Bus Fuel & Maintenance',
    amount: 38000,
    category: 'Transport',
    date: DateTime(2026, 4, 9),
    status: 'Approved',
    notes: 'Diesel for 3 school buses + oil change',
  ),
  _Expense(
    id: 'e6',
    description: 'Printer Toner Cartridges',
    amount: 8500,
    category: 'Stationery',
    date: DateTime(2026, 4, 7),
    status: 'Rejected',
    notes: 'Rejected — use existing stock first',
  ),
  _Expense(
    id: 'e7',
    description: 'Water Bill — Q1',
    amount: 18000,
    category: 'Utilities',
    date: DateTime(2026, 4, 5),
    status: 'Approved',
    notes: 'Quarterly water bill',
  ),
  _Expense(
    id: 'e8',
    description: 'Sports Equipment',
    amount: 55000,
    category: 'Other',
    date: DateTime(2026, 4, 3),
    status: 'Pending',
    notes: 'New footballs, nets, and athletics equipment',
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  switch (status) {
    case 'Approved':
      return AppColors.success;
    case 'Pending':
      return AppColors.warning;
    case 'Rejected':
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

Color _categoryColor(String cat) {
  switch (cat) {
    case 'Utilities':
      return AppColors.primary;
    case 'Stationery':
      return AppColors.accent;
    case 'Maintenance':
      return AppColors.warning;
    case 'Food':
      return const Color(0xFFEC4899);
    case 'Transport':
      return const Color(0xFF7C3AED);
    default:
      return AppColors.textSecondary;
  }
}

IconData _categoryIcon(String cat) {
  switch (cat) {
    case 'Utilities':
      return Icons.bolt_rounded;
    case 'Stationery':
      return Icons.edit_rounded;
    case 'Maintenance':
      return Icons.build_rounded;
    case 'Food':
      return Icons.restaurant_rounded;
    case 'Transport':
      return Icons.directions_bus_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

String _formatAmount(double amount) {
  if (amount >= 1000) {
    return 'UGX ${(amount / 1000).toStringAsFixed(1)}K';
  }
  return 'UGX ${amount.toStringAsFixed(0)}';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

const List<String> _categories = [
  'Utilities', 'Stationery', 'Maintenance', 'Food', 'Transport', 'Other'
];

// ── Screen ────────────────────────────────────────────────────────────────────
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _dateFilter = 'This Month';
  int? _touchedPieIndex;

  final List<String> _dateFilters = ['This Month', 'Last Month', 'This Year'];

  // ── Stats ─────────────────────────────────────────────────────────────────
  List<_Expense> get _filteredExpenses {
    // All mock data is April 2026; filters are illustrative
    return _mockExpenses;
  }

  double get _totalThisMonth => _filteredExpenses
      .where((e) => e.status != 'Rejected')
      .fold(0, (s, e) => s + e.amount);

  double get _totalThisYear => _totalThisMonth * 4; // mock

  double get _budgetUsed => 68.5; // mock percentage

  int get _pendingCount =>
      _filteredExpenses.where((e) => e.status == 'Pending').length;

  // ── Chart data ────────────────────────────────────────────────────────────
  Map<String, double> get _categoryTotals {
    final map = <String, double>{};
    for (final e in _filteredExpenses) {
      if (e.status != 'Rejected') {
        map[e.category] = (map[e.category] ?? 0) + e.amount;
      }
    }
    return map;
  }

  void _showAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddExpenseSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpense,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Expenses',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${expenses.length} records',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats row ────────────────────────────────────────
                      Row(
                        children: [
                          _ExpenseStat(
                            label: 'This Month',
                            value: _formatAmount(_totalThisMonth),
                            color: AppColors.error,
                            icon: Icons.calendar_today_rounded,
                            index: 0,
                          ),
                          const SizedBox(width: 10),
                          _ExpenseStat(
                            label: 'This Year',
                            value: _formatAmount(_totalThisYear),
                            color: AppColors.primary,
                            icon: Icons.bar_chart_rounded,
                            index: 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _ExpenseStat(
                            label: 'Budget Used',
                            value: '${_budgetUsed.toStringAsFixed(1)}%',
                            color: AppColors.warning,
                            icon: Icons.pie_chart_rounded,
                            index: 2,
                          ),
                          const SizedBox(width: 10),
                          _ExpenseStat(
                            label: 'Pending',
                            value: '$_pendingCount',
                            color: AppColors.warning,
                            icon: Icons.hourglass_top_rounded,
                            index: 3,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Date filter chips ────────────────────────────────
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _dateFilters.map((f) {
                            final sel = _dateFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _dateFilter = f),
                                child: AnimatedContainer(
                                  duration: 220.ms,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.error
                                        : AppColors.surface2,
                                    borderRadius:
                                        BorderRadius.circular(24),
                                    border: Border.all(
                                      color: sel
                                          ? AppColors.error
                                          : Colors.white
                                              .withOpacity(0.07),
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 20),

                      // ── Donut chart ──────────────────────────────────────
                      _CategoryDonutChart(
                        categoryTotals: _categoryTotals,
                        touchedIndex: _touchedPieIndex,
                        onTouch: (i) =>
                            setState(() => _touchedPieIndex = i),
                      ),

                      const SizedBox(height: 20),

                      // ── Expense list header ──────────────────────────────
                      const Text(
                        'Expense Records',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),

                      // ── List ─────────────────────────────────────────────
                      ...expenses.asMap().entries.map((entry) {
                        return _ExpenseCard(
                          expense: entry.value,
                          index: entry.key,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expense Stat Card ─────────────────────────────────────────────────────────
class _ExpenseStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final int index;

  const _ExpenseStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                        color: color,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      )),
                  Text(label,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: index * 80))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
    );
  }
}

// ── Donut Chart ───────────────────────────────────────────────────────────────
class _CategoryDonutChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  const _CategoryDonutChart({
    required this.categoryTotals,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final entries = categoryTotals.entries.toList();
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    final palette = AppColors.chartPalette;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expenses by Category',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Donut
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (ev, resp) {
                        if (ev is FlTapUpEvent || ev is FlLongPressEnd) {
                          onTouch(null);
                        } else if (resp?.touchedSection != null) {
                          onTouch(resp!.touchedSection!.touchedSectionIndex);
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: List.generate(entries.length, (i) {
                      final isTouched = touchedIndex == i;
                      final pct = total > 0
                          ? (entries[i].value / total * 100)
                          : 0.0;
                      return PieChartSectionData(
                        color: palette[i % palette.length],
                        value: entries[i].value,
                        title: isTouched
                            ? '${pct.toStringAsFixed(1)}%'
                            : '',
                        radius: isTouched ? 36 : 28,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(entries.length, (i) {
                    final entry = entries[i];
                    final color = palette[i % palette.length];
                    final pct = total > 0
                        ? (entry.value / total * 100).toStringAsFixed(1)
                        : '0';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }
}

// ── Expense Card ──────────────────────────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  final _Expense expense;
  final int index;

  const _ExpenseCard({required this.expense, required this.index});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(expense.status);
    final catColor = _categoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: catColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_categoryIcon(expense.category),
                color: catColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(expense.date),
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        expense.category,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatAmount(expense.amount),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              StatusBadge(
                label: expense.status,
                color: statusColor,
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 55))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Add Expense Sheet ─────────────────────────────────────────────────────────
class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _category = _categories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() async {
    if (_descCtrl.text.isEmpty || _amtCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense submitted for approval'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Expense',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Description
              _Label('Description'),
              const SizedBox(height: 8),
              _Field(controller: _descCtrl, hint: 'What was this expense for?'),
              const SizedBox(height: 16),

              // Amount + Category
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Amount (UGX)'),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _amtCtrl,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Category'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _category,
                              isExpanded: true,
                              dropdownColor: AppColors.surface2,
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13),
                              iconEnabledColor:
                                  AppColors.textSecondary,
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _category = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date
              _Label('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_date),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.edit_calendar_rounded,
                          size: 16,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              _Label('Notes (optional)'),
              const SizedBox(height: 8),
              _Field(
                controller: _notesCtrl,
                hint: 'Additional details...',
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Submit Expense',
                loading: _saving,
                gradient: AppColors.warmGradient,
                onTap: _save,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
