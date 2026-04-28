import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import '../../core/providers/auth_provider.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _teacherClassesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? data['classes'] ?? []);
  return List<dynamic>.from(data ?? []);
});

final _teacherAttendanceProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final res = await ApiService().get('/attendance', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Attendance Status ─────────────────────────────────────────────────────────

enum _AttStatus { none, present, absent, late }

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends ConsumerState<TeacherAttendanceScreen> {
  DateTime _date = DateTime.now();
  String? _selectedClassId;
  String _selectedClassName = '';
  final Map<String, _AttStatus> _attendance = {};
  bool _submitting = false;

  String get _dateStr =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  int _count(_AttStatus s) => _attendance.values.where((v) => v == s).length;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.roleTeacher, surface: AppColors.surface1),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() { _date = picked; _attendance.clear(); });
  }

  Future<void> _submit(List<dynamic> students) async {
    if (_selectedClassId == null) return;
    setState(() => _submitting = true);
    try {
      final records = students.map((s) {
        final sid = s['id'].toString();
        final status = _attendance[sid] ?? _AttStatus.none;
        return {
          'student_id': s['id'],
          'status': status == _AttStatus.present
              ? 'present'
              : status == _AttStatus.absent
                  ? 'absent'
                  : status == _AttStatus.late
                      ? 'late'
                      : 'absent',
        };
      }).toList();

      await ApiService().post('/attendance/mark', data: {
        'class_id': _selectedClassId,
        'date': _dateStr,
        'attendance': records,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Attendance submitted for $_selectedClassName'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        ref.invalidate(_teacherAttendanceProvider);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit attendance'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name[0].toUpperCase();
  }

  static const _avatarColors = [
    AppColors.roleTeacher, AppColors.primary, AppColors.accent,
    AppColors.warning, AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classesAsync = ref.watch(_teacherClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Mark Attendance',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(user.name.split(' ').first,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: classesAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.roleTeacher)),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load classes',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_teacherClassesProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleTeacher),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (classes) {
            if (_selectedClassId == null && classes.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedClassId = classes[0]['id'].toString();
                    _selectedClassName = classes[0]['name']?.toString() ?? '';
                  });
                }
              });
            }

            if (_selectedClassId == null) {
              return const Center(
                  child: Text('No classes assigned',
                      style: TextStyle(color: AppColors.textSecondary)));
            }

            final attendanceAsync = ref.watch(_teacherAttendanceProvider(
                {'class_id': _selectedClassId!, 'date': _dateStr}));

            return attendanceAsync.when(
              loading: () => Column(children: [
                _buildControls(classes),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: 6,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ShimmerBox(height: 60, borderRadius: 14),
                    ),
                  ),
                ),
              ]),
              error: (e, _) => Column(children: [
                _buildControls(classes),
                const Expanded(
                  child: Center(
                    child: Text('Failed to load students',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ]),
              data: (data) {
                final students = List<dynamic>.from(
                    data['students'] ?? data['data'] ?? []);

                // Pre-fill existing attendance
                for (final s in students) {
                  final sid = s['id'].toString();
                  if (!_attendance.containsKey(sid)) {
                    final existing = s['attendance_status']?.toString();
                    if (existing != null) {
                      _attendance[sid] = existing == 'present'
                          ? _AttStatus.present
                          : existing == 'late'
                              ? _AttStatus.late
                              : existing == 'absent'
                                  ? _AttStatus.absent
                                  : _AttStatus.none;
                    }
                  }
                }

                return Column(children: [
                  _buildControls(classes, students: students),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref.invalidate(_teacherAttendanceProvider),
                      color: AppColors.roleTeacher,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: students.length,
                        itemBuilder: (ctx, i) {
                          final s = students[i];
                          final sid = s['id'].toString();
                          final name =
                              '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                          final status = _attendance[sid] ?? _AttStatus.none;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(children: [
                                AvatarWidget(
                                  initials: _initials(name),
                                  color: _avatarColors[i % _avatarColors.length],
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                ),
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  _AttBtn(
                                    label: 'P',
                                    color: AppColors.success,
                                    active: status == _AttStatus.present,
                                    onTap: () => setState(
                                        () => _attendance[sid] = _AttStatus.present),
                                  ),
                                  const SizedBox(width: 6),
                                  _AttBtn(
                                    label: 'A',
                                    color: AppColors.error,
                                    active: status == _AttStatus.absent,
                                    onTap: () => setState(
                                        () => _attendance[sid] = _AttStatus.absent),
                                  ),
                                  const SizedBox(width: 6),
                                  _AttBtn(
                                    label: 'L',
                                    color: AppColors.warning,
                                    active: status == _AttStatus.late,
                                    onTap: () => setState(
                                        () => _attendance[sid] = _AttStatus.late),
                                  ),
                                ]),
                              ]),
                            ),
                          ).animate(delay: Duration(milliseconds: i * 40))
                              .fadeIn()
                              .slideX(begin: 0.05, end: 0);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: GradientButton(
                      label: 'Submit Attendance',
                      loading: _submitting,
                      gradient: const LinearGradient(
                          colors: [AppColors.roleTeacher, AppColors.primary]),
                      onTap: () => _submit(students),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
                  ),
                ]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls(List<dynamic> classes, {List<dynamic> students = const []}) {
    final total = students.length;
    final present = _count(_AttStatus.present);
    final absent = _count(_AttStatus.absent);
    final late = _count(_AttStatus.late);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        GlassCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                color: AppColors.roleTeacher, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_date.day.toString().padLeft(2, '0')} / ${_date.month.toString().padLeft(2, '0')} / ${_date.year}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          ]),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedClassId,
              isExpanded: true,
              dropdownColor: AppColors.surface1,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              items: classes.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['name']?.toString() ?? ''),
                  )).toList(),
              onChanged: (v) {
                if (v != null) {
                  final cls = classes.firstWhere(
                      (c) => c['id'].toString() == v, orElse: () => {});
                  setState(() {
                    _selectedClassId = v;
                    _selectedClassName = cls['name']?.toString() ?? '';
                    _attendance.clear();
                  });
                }
              },
            ),
          ),
        ).animate(delay: 100.ms).fadeIn(),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Summary('Total', total, AppColors.textSecondary),
              _vDivider(),
              _Summary('Present', present, AppColors.success),
              _vDivider(),
              _Summary('Absent', absent, AppColors.error),
              _vDivider(),
              _Summary('Late', late, AppColors.warning),
            ],
          ),
        ).animate(delay: 150.ms).fadeIn(),
      ]),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 30, color: Colors.white12);
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Summary extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Summary(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
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
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : color)),
          ),
        ),
      );
}
