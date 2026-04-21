import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

const _classes = ['Grade 7A', 'Grade 7B', 'Grade 8A', 'Grade 8B', 'Grade 9A', 'Grade 9B'];

const _classMockStudents = {
  'Grade 7A': ['Amara Osei', 'Brian Mukasa', 'Chloe Wanjiru', 'David Kamau', 'Esther Auko'],
  'Grade 7B': ['Faith Otieno', 'George Lule', 'Hannah Juma', 'Isaac Ndung\'u', 'Joy Nalwanga'],
  'Grade 8A': ['Kevin Mwangi', 'Linda Ssali', 'Moses Kariuki', 'Nancy Akello', 'Oscar Tendo'],
  'Grade 8B': ['Phoebe Nyambura', 'Quest Obuya', 'Rachel Adong', 'Samuel Kimani', 'Tina Namutebi'],
  'Grade 9A': ['Umar Hassan', 'Violet Kerubo', 'Walter Opondo', 'Xenia Nakakawa', 'Yusuf Otieno'],
  'Grade 9B': ['Zara Mukami', 'Abel Ssenyonga', 'Betty Awino', 'Calvin Rotich', 'Debra Achieng'],
};

enum AttendanceStatus { none, present, absent, late }

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  DateTime _date = DateTime.now();
  String _selectedClass = 'Grade 7A';
  final Map<String, AttendanceStatus> _attendance = {};
  bool _submitting = false;

  List<String> get _students => _classMockStudents[_selectedClass] ?? [];

  int get _presentCount => _attendance.values.where((v) => v == AttendanceStatus.present).length;
  int get _absentCount  => _attendance.values.where((v) => v == AttendanceStatus.absent).length;
  int get _lateCount    => _attendance.values.where((v) => v == AttendanceStatus.late).length;

  void _setStatus(String name, AttendanceStatus status) {
    setState(() => _attendance[name] = status);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface1),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance submitted for $_selectedClass'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

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
        title: const Text('Mark Attendance', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date picker row
                  GlassCard(
                    onTap: _pickDate,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_date.day.toString().padLeft(2, '0')} / ${_date.month.toString().padLeft(2, '0')} / ${_date.year}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 10),

                  // Class dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.07)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClass,
                        isExpanded: true,
                        dropdownColor: AppColors.surface1,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                        items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() { _selectedClass = v; _attendance.clear(); });
                        },
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 10),

                  // Summary bar
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryBadge('Total', _students.length, AppColors.textSecondary),
                        _vDivider(),
                        _SummaryBadge('Present', _presentCount, AppColors.success),
                        _vDivider(),
                        _SummaryBadge('Absent', _absentCount, AppColors.error),
                        _vDivider(),
                        _SummaryBadge('Late', _lateCount, AppColors.warning),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn(),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _students.length,
                itemBuilder: (context, i) {
                  final name   = _students[i];
                  final status = _attendance[name] ?? AttendanceStatus.none;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          AvatarWidget(
                            initials: _initials(name),
                            color: _avatarColor(i),
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AttBtn(
                                label: 'P',
                                color: AppColors.success,
                                active: status == AttendanceStatus.present,
                                onTap: () => _setStatus(name, AttendanceStatus.present),
                              ),
                              const SizedBox(width: 6),
                              _AttBtn(
                                label: 'A',
                                color: AppColors.error,
                                active: status == AttendanceStatus.absent,
                                onTap: () => _setStatus(name, AttendanceStatus.absent),
                              ),
                              const SizedBox(width: 6),
                              _AttBtn(
                                label: 'L',
                                color: AppColors.warning,
                                active: status == AttendanceStatus.late,
                                onTap: () => _setStatus(name, AttendanceStatus.late),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
            ),

            // Submit button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GradientButton(
                label: 'Submit Attendance',
                loading: _submitting,
                onTap: _submit,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.white12);

  String _initials(String name) {
    final p = name.split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : name[0];
  }

  Color _avatarColor(int i) {
    const colors = [AppColors.primary, AppColors.accent, AppColors.roleTeacher, AppColors.warning, AppColors.success];
    return colors[i % colors.length];
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryBadge(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ],
  );
}

class _AttBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _AttBtn({required this.label, required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 150.ms,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? color : color.withOpacity(0.25)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : color,
          ),
        ),
      ),
    ),
  );
}
