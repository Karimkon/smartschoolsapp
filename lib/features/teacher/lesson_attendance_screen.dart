import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _lessonClassesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? data['classes'] ?? []);
  return List<dynamic>.from(data ?? []);
});

final _lessonSubjectsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, classId) async {
  final res = await ApiService().get('/lesson-attendance/subjects', params: {'class_id': classId});
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? []);
  return List<dynamic>.from(data ?? []);
});

// Key format: "classId|subjectId|date|streamId" — String key so Riverpod family
// equality works (a Map literal is a new instance every build → infinite refetch loop).
final _lessonSessionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final params = <String, String>{
    'class_id': parts[0],
    'subject_id': parts[1],
    'date': parts[2],
  };
  if (parts.length > 3 && parts[3].isNotEmpty) params['stream_id'] = parts[3];
  final res = await ApiService().get('/lesson-attendance', params: params);
  if (res.data is! Map) throw Exception('Unexpected response format');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

enum _AttStatus { none, present, absent, late }

class LessonAttendanceScreen extends ConsumerStatefulWidget {
  const LessonAttendanceScreen({super.key});

  @override
  ConsumerState<LessonAttendanceScreen> createState() => _LessonAttendanceScreenState();
}

class _LessonAttendanceScreenState extends ConsumerState<LessonAttendanceScreen> {
  DateTime _date = DateTime.now();
  String? _classId;
  String _className = '';
  String? _subjectId;
  String _subjectName = '';
  String? _streamId;
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
    if (_classId == null || _subjectId == null) return;
    setState(() => _submitting = true);
    try {
      final records = students.map((s) {
        final sid = s['id'].toString();
        final status = _attendance[sid] ?? _AttStatus.absent;
        return {
          'student_id': s['id'],
          'status': status == _AttStatus.present
              ? 'present'
              : status == _AttStatus.late
                  ? 'late'
                  : 'absent',
        };
      }).toList();

      await ApiService().post('/lesson-attendance/mark', data: {
        'class_id':  _classId,
        'subject_id': _subjectId,
        'date': _dateStr,
        'attendance': records,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lesson attendance saved for $_subjectName'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        ref.invalidate(_lessonSessionProvider);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save attendance'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final p = name.trim().split(' ');
    return p.length >= 2 ? '${p[0][0]}${p[1][0]}'.toUpperCase() : name[0].toUpperCase();
  }

  static const _avatarColors = [
    AppColors.roleTeacher, AppColors.primary, AppColors.accent,
    AppColors.warning, AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(_lessonClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Lesson Attendance',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: classesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.roleTeacher)),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load classes', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_lessonClassesProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleTeacher),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (classes) {
            if (_classId == null && classes.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {
                  _classId   = classes[0]['id'].toString();
                  _className = classes[0]['name']?.toString() ?? '';
                  _subjectId = null;
                });
              });
            }

            return Column(children: [
              _buildSelectors(classes),
              if (_classId != null && _subjectId != null)
                Expanded(child: _buildStudentList()),
              if (_classId == null || _subjectId == null)
                Expanded(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.textHint, size: 56),
                      const SizedBox(height: 12),
                      const Text('Select a class and subject', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildSelectors(List<dynamic> classes) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Date picker
        GlassCard(
          onTap: _pickDate,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.roleTeacher, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_date.day.toString().padLeft(2, '0')} / ${_date.month.toString().padLeft(2, '0')} / ${_date.year}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          ]),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 10),

        // Class picker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _classId,
              isExpanded: true,
              dropdownColor: AppColors.surface1,
              hint: const Text('Select Class', style: TextStyle(color: AppColors.textHint)),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              items: classes.map((c) => DropdownMenuItem(
                value: c['id'].toString(),
                child: Text(c['name']?.toString() ?? ''),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  final cls = classes.firstWhere((c) => c['id'].toString() == v, orElse: () => {});
                  setState(() {
                    _classId   = v;
                    _className = cls['name']?.toString() ?? '';
                    _subjectId = null;
                    _subjectName = '';
                    _streamId  = null;
                    _attendance.clear();
                  });
                }
              },
            ),
          ),
        ).animate(delay: 100.ms).fadeIn(),
        if (_streamsForClass(classes).isNotEmpty) ...[
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
                value: _streamId ?? '',
                isExpanded: true,
                dropdownColor: AppColors.surface1,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All Streams')),
                  ..._streamsForClass(classes).map((s) => DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text('Stream: ${s['name']}'),
                      )),
                ],
                onChanged: (v) => setState(() {
                  _streamId = (v == null || v.isEmpty) ? null : v;
                  _attendance.clear();
                }),
              ),
            ),
          ).animate(delay: 120.ms).fadeIn(),
        ],
        const SizedBox(height: 10),

        // Subject picker
        if (_classId != null) _buildSubjectPicker(),
      ]),
    );
  }

  Widget _buildSubjectPicker() {
    final subjectsAsync = ref.watch(_lessonSubjectsProvider(_classId!));
    return subjectsAsync.when(
      loading: () => const ShimmerCard(height: 52),
      error: (_, __) => const SizedBox.shrink(),
      data: (subjects) {
        if (subjects.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppColors.textHint, size: 18),
              SizedBox(width: 8),
              Text('No subjects assigned for this class', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            ]),
          );
        }
        // Auto-select first subject if none selected
        if (_subjectId == null && subjects.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _subjectId == null) {
              setState(() {
                _subjectId   = subjects[0]['id'].toString();
                _subjectName = subjects[0]['name']?.toString() ?? '';
                _attendance.clear();
              });
            }
          });
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: subjects.any((s) => s['id'].toString() == _subjectId) ? _subjectId : null,
              isExpanded: true,
              dropdownColor: AppColors.surface1,
              hint: const Text('Select Subject', style: TextStyle(color: AppColors.textHint)),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              items: subjects.map((s) => DropdownMenuItem(
                value: s['id'].toString(),
                child: Row(children: [
                  Expanded(child: Text(s['name']?.toString() ?? '')),
                  if ((s['track']?.toString() ?? '') == 'theology')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Theology', style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                    ),
                ]),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  final sub = subjects.firstWhere((s) => s['id'].toString() == v, orElse: () => {});
                  setState(() {
                    _subjectId   = v;
                    _subjectName = sub['name']?.toString() ?? '';
                    _attendance.clear();
                  });
                }
              },
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _streamsForClass(List<dynamic> classes) {
    if (_classId == null) return const [];
    final cls = classes.firstWhere(
        (c) => c['id'].toString() == _classId, orElse: () => null);
    if (cls == null || cls['streams'] == null) return const [];
    return List<dynamic>.from(cls['streams'] as List);
  }

  Widget _buildStudentList() {
    final sessionAsync = ref.watch(_lessonSessionProvider(
        '${_classId!}|${_subjectId!}|$_dateStr|${_streamId ?? ''}'));

    return sessionAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: 6,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerCard(height: 60, radius: 14),
        ),
      ),
      error: (e, _) => Center(
        child: Text('Failed to load students', style: TextStyle(color: AppColors.textSecondary)),
      ),
      data: (data) {
        final students = List<dynamic>.from(data['students'] ?? []);
        final session  = data['session'] as Map?;

        // Pre-fill existing status
        for (final s in students) {
          final sid = s['id'].toString();
          if (!_attendance.containsKey(sid)) {
            final existing = s['status']?.toString();
            if (existing != null) {
              _attendance[sid] = existing == 'present'
                  ? _AttStatus.present
                  : existing == 'late'
                      ? _AttStatus.late
                      : _AttStatus.absent;
            }
          }
        }

        final total   = students.length;
        final present = _count(_AttStatus.present);
        final absent  = _count(_AttStatus.absent);
        final late    = _count(_AttStatus.late);

        return Column(children: [
          // Summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: GlassCard(
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
                  if (session != null) ...[
                    _vDivider(),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                      const Text('Saved', style: TextStyle(fontSize: 10, color: AppColors.success)),
                    ]),
                  ],
                ],
              ),
            ).animate().fadeIn(),
          ),

          Expanded(
            child: students.isEmpty
                ? const Center(
                    child: Text('No active students in this class',
                        style: TextStyle(color: AppColors.textSecondary)))
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(_lessonSessionProvider),
                    color: AppColors.roleTeacher,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: students.length,
                      itemBuilder: (ctx, i) {
                        final s   = students[i];
                        final sid = s['id'].toString();
                        final name   = s['name']?.toString() ?? '';
                        final admNo  = s['admission_number']?.toString() ?? '';
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    if (admNo.isNotEmpty)
                                      Text(admNo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                              ),
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                _AttBtn(label: 'P', color: AppColors.success, active: status == _AttStatus.present,
                                    onTap: () => setState(() => _attendance[sid] = _AttStatus.present)),
                                const SizedBox(width: 6),
                                _AttBtn(label: 'A', color: AppColors.error, active: status == _AttStatus.absent,
                                    onTap: () => setState(() => _attendance[sid] = _AttStatus.absent)),
                                const SizedBox(width: 6),
                                _AttBtn(label: 'L', color: AppColors.warning, active: status == _AttStatus.late,
                                    onTap: () => setState(() => _attendance[sid] = _AttStatus.late)),
                              ]),
                            ]),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                      },
                    ),
                  ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GradientButton(
              label: 'Save Lesson Attendance',
              loading: _submitting,
              gradient: const LinearGradient(colors: [AppColors.roleTeacher, AppColors.primary]),
              onTap: students.isEmpty ? null : () => _submit(students),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          ),
        ]);
      },
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
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: active ? Colors.white : color)),
      ),
    ),
  );
}
