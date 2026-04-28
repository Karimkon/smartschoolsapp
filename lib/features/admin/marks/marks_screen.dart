import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _marksClassesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/marks');
  return Map<String, dynamic>.from(res.data as Map);
});

final _marksStudentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final res = await ApiService().get('/marks', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MarksScreen extends ConsumerStatefulWidget {
  const MarksScreen({super.key});

  @override
  ConsumerState<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends ConsumerState<MarksScreen> {
  String? _classId;
  String _className = '';
  String? _subjectId;
  String _subjectName = '';
  String? _examId;
  String _examName = '';
  bool _saving = false;

  // Map of student_id → score text controller
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, int?> _scores = {};

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  String _grade(int? score) {
    if (score == null) return '-';
    if (score >= 80) return 'A';
    if (score >= 65) return 'B';
    if (score >= 50) return 'C';
    if (score >= 35) return 'D';
    return 'F';
  }

  Color _gradeColor(int? score) {
    if (score == null) return AppColors.textHint;
    if (score >= 80) return AppColors.success;
    if (score >= 65) return AppColors.primary;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  int get _entered => _scores.values.where((s) => s != null).length;
  double get _avg {
    final scored = _scores.values.whereType<int>().toList();
    if (scored.isEmpty) return 0;
    return scored.reduce((a, b) => a + b) / scored.length;
  }

  Future<void> _saveMarks(List<dynamic> students) async {
    if (_classId == null || _subjectId == null || _examId == null) return;
    setState(() => _saving = true);
    try {
      final marks = students
          .where((s) => _scores[s['id'].toString()] != null)
          .map((s) => {
                'student_id': s['id'],
                'score': _scores[s['id'].toString()],
              })
          .toList();

      await ApiService().post('/marks', data: {
        'class_id': _classId,
        'subject_id': _subjectId,
        'exam_id': _examId,
        'marks': marks,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Marks saved successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save marks'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metaAsync = ref.watch(_marksClassesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Marks Entry',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : () {},
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('Save',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: metaAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              const Text('Failed to load data',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_marksClassesProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (meta) {
            final classes = List<dynamic>.from(meta['classes'] ?? []);
            final subjects = List<dynamic>.from(meta['subjects'] ?? []);
            final exams = List<dynamic>.from(meta['exams'] ?? []);

            // Auto-select first options
            if (_classId == null && classes.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {
                  _classId = classes[0]['id'].toString();
                  _className = classes[0]['name']?.toString() ?? '';
                });
              });
            }
            if (_subjectId == null && subjects.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {
                  _subjectId = subjects[0]['id'].toString();
                  _subjectName = subjects[0]['name']?.toString() ?? '';
                });
              });
            }
            if (_examId == null && exams.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {
                  _examId = exams[0]['id'].toString();
                  _examName = exams[0]['name']?.toString() ?? '';
                });
              });
            }

            final canLoad = _classId != null && _subjectId != null && _examId != null;

            return Column(children: [
              // Selectors
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Class
                  _buildDropdown(
                    label: 'Class',
                    value: _classId,
                    items: classes.map((c) => DropdownMenuItem(
                          value: c['id'].toString(),
                          child: Text(c['name']?.toString() ?? ''),
                        )).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        final cls = classes.firstWhere(
                            (c) => c['id'].toString() == v, orElse: () => {});
                        setState(() {
                          _classId = v;
                          _className = cls['name']?.toString() ?? '';
                          _scores.clear();
                          _controllers.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _buildDropdown(
                        label: 'Subject',
                        value: _subjectId,
                        items: subjects.map((s) => DropdownMenuItem(
                              value: s['id'].toString(),
                              child: Text(s['name']?.toString() ?? ''),
                            )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final sub = subjects.firstWhere(
                                (s) => s['id'].toString() == v, orElse: () => {});
                            setState(() {
                              _subjectId = v;
                              _subjectName = sub['name']?.toString() ?? '';
                              _scores.clear();
                              _controllers.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        label: 'Exam',
                        value: _examId,
                        items: exams.map((e) => DropdownMenuItem(
                              value: e['id'].toString(),
                              child: Text(e['name']?.toString() ?? ''),
                            )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            final ex = exams.firstWhere(
                                (e) => e['id'].toString() == v, orElse: () => {});
                            setState(() {
                              _examId = v;
                              _examName = ex['name']?.toString() ?? '';
                              _scores.clear();
                              _controllers.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatMini('Entered', '$_entered', AppColors.primary),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _StatMini('Average', _entered > 0 ? '${_avg.toStringAsFixed(1)}%' : '—', AppColors.success),
                        Container(width: 1, height: 30, color: Colors.white12),
                        _StatMini('Pending', '—', AppColors.warning),
                      ],
                    ),
                  ).animate(delay: 150.ms).fadeIn(),
                ]).animate().fadeIn(),
              ),

              // Students list
              Expanded(
                child: !canLoad
                    ? const Center(
                        child: Text('Select class, subject and exam above',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : _StudentsMarksView(
                        classId: _classId!,
                        subjectId: _subjectId!,
                        examId: _examId!,
                        scores: _scores,
                        controllers: _controllers,
                        gradeColor: _gradeColor,
                        grade: _grade,
                        onSave: _saveMarks,
                        saving: _saving,
                        onScoreChanged: (id, score) {
                          setState(() => _scores[id] = score);
                        },
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Text('$label: ',
            style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface1,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Students Marks View ────────────────────────────────────────────────────────

class _StudentsMarksView extends ConsumerStatefulWidget {
  final String classId, subjectId, examId;
  final Map<String, int?> scores;
  final Map<String, TextEditingController> controllers;
  final Color Function(int?) gradeColor;
  final String Function(int?) grade;
  final Future<void> Function(List<dynamic>) onSave;
  final bool saving;
  final void Function(String id, int? score) onScoreChanged;

  const _StudentsMarksView({
    required this.classId,
    required this.subjectId,
    required this.examId,
    required this.scores,
    required this.controllers,
    required this.gradeColor,
    required this.grade,
    required this.onSave,
    required this.saving,
    required this.onScoreChanged,
  });

  @override
  ConsumerState<_StudentsMarksView> createState() => _StudentsMarksViewState();
}

class _StudentsMarksViewState extends ConsumerState<_StudentsMarksView> {
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_marksStudentsProvider({
      'class_id': widget.classId,
      'subject_id': widget.subjectId,
      'exam_id': widget.examId,
    }));

    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: 6,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ShimmerBox(height: 60, borderRadius: 14),
        ),
      ),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          const Text('Failed to load students',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(_marksStudentsProvider),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry'),
          ),
        ]),
      ),
      data: (data) {
        final students = List<dynamic>.from(
            data['students'] ?? data['data'] ?? []);

        // Init controllers for new students
        for (final s in students) {
          final sid = s['id'].toString();
          if (!widget.controllers.containsKey(sid)) {
            final existingScore = s['score'] as int?;
            widget.controllers[sid] = TextEditingController(
                text: existingScore != null ? existingScore.toString() : '');
            if (existingScore != null) widget.scores[sid] = existingScore;
          }
        }

        return Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(_marksStudentsProvider),
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  final sid = s['id'].toString();
                  final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                  final score = widget.scores[sid];
                  final ctrl = widget.controllers[sid]!;
                  final gradeVal = widget.grade(score);
                  final gradeClr = widget.gradeColor(score);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        AvatarWidget(
                          initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
                          color: [AppColors.primary, AppColors.roleTeacher,
                              AppColors.accent, AppColors.success][i % 4],
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              if (score != null)
                                Text('Grade: $gradeVal',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: gradeClr,
                                        fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15),
                            decoration: InputDecoration(
                              hintText: '0-100',
                              hintStyle:
                                  const TextStyle(color: AppColors.textHint, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.surface2,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              widget.onScoreChanged(sid, n != null ? n.clamp(0, 100) : null);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: gradeClr.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(gradeVal,
                                style: TextStyle(
                                    color: gradeClr,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
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
              label: 'Save Marks',
              loading: widget.saving,
              onTap: () => widget.onSave(students),
            ),
          ),
        ]);
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatMini(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
        ],
      );
}
