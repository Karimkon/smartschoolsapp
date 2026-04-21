import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Invoice {
  final String term, status;
  final double amount;
  const _Invoice(this.term, this.amount, this.status);
}

class _PaymentRecord {
  final String date, method;
  final double amount;
  const _PaymentRecord(this.date, this.method, this.amount);
}

const _totalFee    = 135000.0;
const _paidAmount  = 90000.0;
const _balanceDue  = _totalFee - _paidAmount;

const _invoices = [
  _Invoice('Term 1, 2025', 45000, 'Paid'),
  _Invoice('Term 2, 2025', 45000, 'Partial'),
  _Invoice('Term 3, 2025', 45000, 'Pending'),
];

const _paymentHistory = [
  _PaymentRecord('Apr 18, 2025', 'MoMo',  25000),
  _PaymentRecord('Mar 02, 2025', 'Bank',  30000),
  _PaymentRecord('Jan 15, 2025', 'Cash',  20000),
  _PaymentRecord('Jan 05, 2025', 'Bank',  15000),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentFeesScreen extends StatelessWidget {
  const StudentFeesScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid':    return AppColors.success;
      case 'Partial': return AppColors.primary;
      case 'Pending': return AppColors.warning;
      case 'Overdue': return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

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
    final progress = _totalFee > 0 ? _paidAmount / _totalFee : 0.0;

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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Summary card
            GlassCard(
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
                      _FeeStat('Total Fee', 'KES ${_totalFee.toStringAsFixed(0)}', AppColors.textPrimary),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _FeeStat('Amount Paid', 'KES ${_paidAmount.toStringAsFixed(0)}', AppColors.success),
                      Container(width: 1, height: 40, color: Colors.white12),
                      _FeeStat('Balance Due', 'KES ${_balanceDue.toStringAsFixed(0)}', AppColors.warning),
                    ],
                  ),
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
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% paid',
                        style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${((1 - progress) * 100).toStringAsFixed(0)}% remaining',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // Invoices section
            const SectionHeader(title: 'Invoices').animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 12),

            ..._invoices.asMap().entries.map((e) {
              final inv = e.value;
              final i   = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 48,
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
                            Text(inv.term, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            Text('KES ${inv.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusBadge(label: inv.status, color: _statusColor(inv.status)),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 150 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 20),

            // Payment history
            const SectionHeader(title: 'Payment History').animate(delay: 350.ms).fadeIn(),
            const SizedBox(height: 12),

            ..._paymentHistory.asMap().entries.map((e) {
              final p = e.value;
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
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
                            Text(p.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 3),
                            StatusBadge(label: p.method, color: _methodColor(p.method)),
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
              ).animate(delay: Duration(milliseconds: 400 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
            }),
          ],
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
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ],
  );
}
