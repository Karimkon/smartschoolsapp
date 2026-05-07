import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final settingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/settings');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _schoolNameCtrl = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _addressCtrl    = TextEditingController();
  final _mottoCtrl      = TextEditingController();

  bool _allowLateAtt      = true;
  bool _autoNotifyParents = true;
  bool _onlinePayments    = false;
  bool _smsEnabled        = true;
  String _term = 'Term 1';
  String _year = '2026';
  bool _saving  = false;
  bool _loaded  = false;

  @override void dispose() {
    for (final c in [_schoolNameCtrl, _emailCtrl, _phoneCtrl, _addressCtrl, _mottoCtrl]) c.dispose();
    super.dispose();
  }

  void _populate(Map<String, dynamic> d) {
    if (_loaded) return;
    _loaded = true;
    _schoolNameCtrl.text = d['school_name']?.toString() ?? '';
    _emailCtrl.text      = d['email']?.toString() ?? '';
    _phoneCtrl.text      = d['phone']?.toString() ?? '';
    _addressCtrl.text    = d['address']?.toString() ?? '';
    _mottoCtrl.text      = d['motto']?.toString() ?? '';
    _allowLateAtt      = d['allow_late_att']      == true;
    _autoNotifyParents = d['auto_notify_parents'] == true;
    _onlinePayments    = d['online_payments']     == true;
    _smsEnabled        = d['sms_enabled']         == true;
    final t = d['current_term']?.toString() ?? 'Term 1';
    _term = ['Term 1','Term 2','Term 3'].contains(t) ? t : 'Term 1';
    _year = d['academic_year']?.toString() ?? '2026';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiService().put('/settings', data: {
        'school_name':         _schoolNameCtrl.text.trim(),
        'email':               _emailCtrl.text.trim(),
        'phone':               _phoneCtrl.text.trim(),
        'address':             _addressCtrl.text.trim(),
        'motto':               _mottoCtrl.text.trim(),
        'current_term':        _term,
        'academic_year':       _year,
        'allow_late_att':      _allowLateAtt,
        'auto_notify_parents': _autoNotifyParents,
        'online_payments':     _onlinePayments,
        'sms_enabled':         _smsEnabled,
      });
      ref.invalidate(settingsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save: ${e.toString().split(':').last.trim()}'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    // Populate fields once data loads
    settingsAsync.whenData((d) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _populate(d));
      });
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('School Settings', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          settingsAsync.isLoading
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
              : TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                    : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load settings', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(settingsProvider), child: const Text('Retry')),
        ])),
        data: (_) => Container(
          decoration: const BoxDecoration(gradient: AppColors.bgGradient),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
