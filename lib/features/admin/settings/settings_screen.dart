import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _schoolNameCtrl = TextEditingController(text: 'SmartSchools Academy');
  final _emailCtrl     = TextEditingController(text: 'admin@smartschools.ac.ke');
  final _phoneCtrl     = TextEditingController(text: '+254 700 000000');
  final _addressCtrl   = TextEditingController(text: '123 School Road, Nairobi, Kenya');
  final _mottoCtrl     = TextEditingController(text: 'Excellence Through Learning');

  bool _allowLateAtt = true;
  bool _autoNotifyParents = true;
  bool _onlinePayments = false;
  bool _smsEnabled = true;
  String _term = 'Term 1';
  String _year = '2026';
  bool _saving = false;

  @override void dispose() {
    for (final c in [_schoolNameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _mottoCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('School Settings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // School Info section
            _SectionTitle('School Information'),
            const SizedBox(height: 12),
            _Field('School Name', _schoolNameCtrl, Icons.school_rounded),
            const SizedBox(height: 12),
            _Field('Email Address', _emailCtrl, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _Field('Phone Number', _phoneCtrl, Icons.phone_rounded, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _Field('Address', _addressCtrl, Icons.location_on_rounded, maxLines: 2),
            const SizedBox(height: 12),
            _Field('School Motto', _mottoCtrl, Icons.format_quote_rounded),
            const SizedBox(height: 24),

            // Academic Year
            _SectionTitle('Academic Settings'),
            const SizedBox(height: 12),
            GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Current Term', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                      value: _term, dropdownColor: AppColors.surface1, isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      items: ['Term 1','Term 2','Term 3'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _term = v); },
                    ))),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Academic Year', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                      value: _year, dropdownColor: AppColors.surface1, isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      items: ['2024','2025','2026','2027'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) { if (v != null) setState(() => _year = v); },
                    ))),
                ])),
              ]),
            ])).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 24),

            // Feature toggles
            _SectionTitle('Features & Notifications'),
            const SizedBox(height: 12),
            GlassCard(padding: const EdgeInsets.all(4), child: Column(children: [
              _Toggle('Allow Late Attendance Mark', 'Teachers can mark after cutoff time', Icons.access_time_rounded, _allowLateAtt, (v) => setState(() => _allowLateAtt = v)),
              _Divider(),
              _Toggle('Auto-notify Parents', 'Send SMS when student is absent', Icons.notifications_rounded, _autoNotifyParents, (v) => setState(() => _autoNotifyParents = v)),
              _Divider(),
              _Toggle('Online Fee Payments', 'Allow parents to pay fees online', Icons.payment_rounded, _onlinePayments, (v) => setState(() => _onlinePayments = v)),
              _Divider(),
              _Toggle('SMS Gateway', 'Send SMS notifications to parents & staff', Icons.sms_rounded, _smsEnabled, (v) => setState(() => _smsEnabled = v)),
            ])).animate(delay: 300.ms).fadeIn(),
            const SizedBox(height: 24),

            // Danger zone
            _SectionTitle('Danger Zone', color: AppColors.error),
            const SizedBox(height: 12),
            GlassCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Reset academic year data. This cannot be undone.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showConfirmDialog(context),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text('Reset Year Data', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ])).animate(delay: 400.ms).fadeIn(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context) => showDialog(context: context, builder: (_) => AlertDialog(
    backgroundColor: AppColors.surface1,
    title: const Text('Confirm Reset', style: TextStyle(color: AppColors.textPrimary)),
    content: const Text('This will clear all attendance, marks, and fee records for the current year. Are you sure?', style: TextStyle(color: AppColors.textSecondary)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textHint))),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Confirm', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700))),
    ],
  ));
}

class _SectionTitle extends StatelessWidget {
  final String text; final Color? color;
  const _SectionTitle(this.text, {this.color});
  @override Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color ?? AppColors.textHint, letterSpacing: 0.5));
}

class _Field extends StatelessWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final TextInputType? keyboardType; final int maxLines;
  const _Field(this.label, this.controller, this.icon, {this.keyboardType, this.maxLines = 1});

  @override Widget build(BuildContext context) => TextFormField(
    controller: controller, keyboardType: keyboardType, maxLines: maxLines,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      filled: true, fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class _Toggle extends StatelessWidget {
  final String title, subtitle; final IconData icon; final bool value; final ValueChanged<bool> onChanged;
  const _Toggle(this.title, this.subtitle, this.icon, this.value, this.onChanged);
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
      ])),
      Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    ]),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override Widget build(BuildContext context) => Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 60, endIndent: 12);
}
