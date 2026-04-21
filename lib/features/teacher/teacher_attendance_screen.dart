import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Mock Data (teacher-scoped) ────────────────────────────────────────────────

// Teacher is assigned to these classes
const _teacherClasses = ['Grade 8A', 'Grade 9B', 'Grade 10A'];

const _classMockStudents = {
  'Grade 8A': ['Kevin Mwangi', 'Linda Ssali', 'Moses Kariuki', 'Nancy Akello', 'Oscar Tendo', 'Phoebe Nyambura'],
  'Grade 9B': ['Quest Obuya', 'Rachel Adong', 'Samuel Kimani', 'Tina Namutebi', 'Umar Hassan', 'Violet Kerubo'],
  'Grade 10A': ['Walter Opondo', 'Xenia Nakakawa', 'Yusuf Otieno', 'Zara Mukami', 'Abel Ssenyonga', 'Betty Awino'],
};

enum _AttStatus { none, present, absent, late }

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  DateTime _date = DateTime.now();
  String _selectedClass = _teacherClasses[0];
  final Map<String, _AttStatus> _attendance = {};
  bool _submitting = false;

  List<String> get _students => _classMockStudents[_selectedClass] ?? [];

  int get _presentCount => _attendance.values.where((v) => v == _AttStatus.present).length;
  int get _absentCount  => _attendance.values.where((v) => v == _AttStatus.absent).length;
  int get _lateCount    => _attendance.values.where((v) => v == _AttStatus.late).length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.roleTeacher, surface: AppColors.surface1),
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
    final user = ref.watch(currentUserProvider);

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
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(user.name.split(' ').first, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Date picker
                  GlassCard(
                    onTap: _pickDate,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.roleTeacher, size: 20),
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

                  // Class dropdown (only teacher's classes)
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
                        items: _teacherClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                        _Summary('Total',   _students.length, AppColors.textSecondary),
                        _vDivider(),
                        _Summary('Present', _presentCount,    AppColors.success),
                        _vDivider(),
                        _Summary('Absent',  _absentCount,     AppColors.error),
                        _vDivider(),
                        _Summary('Late',    _lateCount,       AppColors.warning),
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
                  final status = _attendance[name] ?? _AttStatus.none;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          AvatarWidget(initials: _initials(name), color: _avatarColor(i), size: 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AttBtn(label: 'P', color: AppColors.success,  active: status == _AttStatus.present, onTap: () => setState(() => _attendance[name] = _AttStatus.present)),
                              const SizedBox(width: 6),
                              _AttBtn(label: 'A', color: AppColors.error,    active: status == _AttStatus.absent,  onTap: () => setState(() => _attendance[name] = _AttStatus.absent)),
                              const SizedBox(width: 6),
                              _AttBtn(label: 'L', color: AppColors.warning,  active: status == _AttStatus.late,    onTap: () => setState(() => _attendance[name] = _AttStatus.late)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
            ),

            // Submit
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GradientButton(
                label: 'Submit Attendance',
                loading: _submitting,
                gradient: const LinearGradient(colors: [AppColors.roleTeacher, AppColors.primary]),
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
    const colors = [AppColors.roleTeacher, AppColors.primary, AppColors.accent, AppColors.warning, AppColors.success];
    return colors[i % colors.length];
  }
}

class _Summary extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Summary(this.label, this.count, this.color);

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
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: active ? color : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? color : color.withOpacity(0.25)),
      ),
      child: Center(
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : color)),
      ),
    ),
  );
}
