import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final marksSetupProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/marks/setup');
  return Map<String, dynamic>.from(res.data as Map);
});

final marksEntryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final res = await ApiService().get('/marks/entry', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MarksScreen extends ConsumerStatefulWidget {
  const MarksScreen({super.key});

  @override
  ConsumerState<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends ConsumerState<MarksScreen> {
  // Filter state
  String? _classId, _className;
  String? _curriculumId, _curriculumName;
  String? _sessionYearId, _sessionName;
  String? _subjectId, _subjectName;
  String? _componentId, _componentName;
  double? _componentMax;
  int _term = 1;

  // Score entry state
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double?> _scores = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Color _scoreColor(double? score, double max) {
    if (score == null || max == 0) return AppColors.textHint;
    final pct = score / max;
    if (pct >= 0.8) return AppColors.success;
    if (pct >= 0.65) return AppColors.primary;
    if (pct >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  int get _entered => _scores.values.where((s) => s != null).length;
  double get _avg {
    final scored = _scores.values.whereType<double>().toList();
    if (scored.isEmpty) return 0;
    return scored.reduce((a, b) => a + b) / scored.length;
  }

  bool get _readyToLoad =>
      _classId != null && _curriculumId != null && _sessionYearId != null;
  bool get _readyToEnter =>
      _readyToLoad && _subjectId != null && _componentId != null;

  Map<String, String> get _entryParams => {
    'class_id': _classId ?? '',
    'curriculum_id': _curriculumId ?? '',
    'session_year_id': _sessionYearId ?? '',
    if (_subjectId != null) 'subject_id': _subjectId!,
    if (_componentId != null) 'component_id': _componentId!,
    'term': _term.toString(),
  };

  Future<void> _saveMarks(List<dynamic> students) async {
    if (!_readyToEnter) return;
    setState(() => _saving = true);
    try {
      final scoresMap = <String, dynamic>{};
      for (final s in students) {
        final sid = s['id'].toString();
        if (_scores[sid] != null) scoresMap[sid] = _scores[sid];
      }
      await ApiService().post('/marks/save', data: {
        'curriculum_id':   _curriculumId,
        'session_year_id': _sessionYearId,
        'subject_id':      _subjectId,
        'component_id':    _componentId,
        'term':            _term,
        'scores':          scoresMap,
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
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final setupAsync = ref.watch(marksSetupProvider);

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
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: setupAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load data', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(marksSetupProvider),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ])),
          data: (setup) {
            final classes      = List<dynamic>.from(setup['classes']      ?? []);
            final curricula    = List<dynamic>.from(setup['curricula']    ?? []);
            final sessionYears = List<dynamic>.from(setup['session_years'] ?? []);
            final currentSessId= setup['current_session_id']?.toString();

            // Auto-select current session
            if (_sessionYearId == null && currentSessId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final sess = sessionYears.firstWhere(
                  (s) => s['id'].toString() == currentSessId, orElse: () => null);
                if (sess != null) {
                  setState(() {
                    _sessionYearId = currentSessId;
                    _sessionName = sess['name']?.toString();
                  });
                }
              });
            }

            return Column(children: [
              // ── Filter Bar ────────────────────────────────────────────────
              Container(
                color: AppColors.surface1,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(children: [
                  // Row 1: Session + Term
                  Row(children: [
                    Expanded(child: _dropdown(
                      label: 'Session',
                      value: _sessionYearId,
                      items: sessionYears.map((s) => DropdownMenuItem(
                        value: s['id'].toString(),
                        child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _sessionYearId = v;
                        _sessionName = sessionYears.firstWhere(
                          (s) => s['id'].toString() == v, orElse: () => {})['name']?.toString();
                        _subjectId = null; _componentId = null; _scores.clear();
                      }),
                    )),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: _dropdown(
                        label: 'Term',
                        value: _term.toString(),
                        items: [1, 2, 3].map((t) => DropdownMenuItem(
                          value: t.toString(),
                          child: Text('Term $t'),
                        )).toList(),
                        onChanged: (v) => setState(() {
                          _term = int.parse(v!);
                          _scores.clear();
                        }),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Row 2: Class + Curriculum
                  Row(children: [
                    Expanded(child: _dropdown(
                      label: 'Class',
                      value: _classId,
                      items: classes.map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _classId = v;
                        _className = classes.firstWhere(
                          (c) => c['id'].toString() == v, orElse: () => {})['name']?.toString();
                        _subjectId = null; _componentId = null; _scores.clear();
                      }),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _dropdown(
                      label: 'Curriculum',
                      value: _curriculumId,
                      items: curricula.map((c) => DropdownMenuItem(
                        value: c['id'].toString(),
                        child: Text(c['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _curriculumId = v;
                        _curriculumName = curricula.firstWhere(
                          (c) => c['id'].toString() == v, orElse: () => {})['name']?.toString();
                        _subjectId = null; _componentId = null; _scores.clear();
                      }),
                    )),
                  ]),
                ]),
              ),

              // ── Entry Area ────────────────────────────────────────────────
              Expanded(
                child: !_readyToLoad
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.filter_list_rounded, size: 52, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Select session, class, and curriculum to begin',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ]))
                    : _buildEntryArea(),
              ),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildEntryArea() {
    final entryAsync = ref.watch(marksEntryProvider(_entryParams));

    return entryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
        const SizedBox(height: 12),
        const Text('Failed to load entry data', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(marksEntryProvider(_entryParams)),
          child: const Text('Retry'),
        ),
      ])),
      data: (entry) {
        final subjects    = List<dynamic>.from(entry['subjects']   ?? []);
        final components  = List<dynamic>.from(entry['components'] ?? []);
        final students    = List<dynamic>.from(entry['students']   ?? []);
        final existing    = Map<String, dynamic>.from(entry['existing_scores'] ?? {});

        // Load existing scores into controllers
        if (_readyToEnter) {
          for (final s in students) {
            final sid = s['id'].toString();
            if (!_scores.containsKey(sid)) {
              final exScore = existing[s['id'].toString()]?['score'];
              final score   = exScore != null ? (exScore as num).toDouble() : null;
              _scores[sid]  = score;
              _controllers.putIfAbsent(sid, () => TextEditingController());
              if (score != null) _controllers[sid]!.text = score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1);
            }
          }
        }

        return Column(children: [
          // Subject + Component selectors
          Container(
            color: AppColors.surface2,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              Expanded(child: _dropdown(
                label: 'Subject',
                value: _subjectId,
                items: subjects.map((s) => DropdownMenuItem(
                  value: s['id'].toString(),
                  child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() {
                  _subjectId = v;
                  _subjectName = subjects.firstWhere(
                    (s) => s['id'].toString() == v, orElse: () => {})['name']?.toString();
                  _componentId = null; _scores.clear();
                }),
              )),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(
                label: 'Component',
                value: _componentId,
                items: components.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['label']?.toString() ?? c['name']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => setState(() {
                  _componentId = v;
                  final comp = components.firstWhere(
                    (c) => c['id'].toString() == v, orElse: () => {});
                  _componentName = comp['label']?.toString();
                  _componentMax  = (comp['max_score'] as num?)?.toDouble();
                  _scores.clear(); _controllers.clear();
                }),
              )),
            ]),
          ),

          if (!_readyToEnter)
            const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.edit_note_rounded, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('Select a subject and component to enter marks',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])))
          else ...[
            // Summary bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface1,
              child: Row(children: [
                Expanded(child: Text(
                  '${_componentName ?? ''} / ${_componentMax?.toStringAsFixed(0) ?? '?'} marks',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )),
                Text('$_entered / ${students.length} entered',
                    style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                if (_entered > 0) ...[
                  const SizedBox(width: 10),
                  Text('Avg: ${_avg.toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ]),
            ),

            // Student list
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No students found', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                      itemCount: students.length,
                      itemBuilder: (_, i) {
                        final s      = students[i] as Map;
                        final sid    = s['id'].toString();
                        final name   = s['name']?.toString() ?? '';
                        final admNo  = s['admission_number']?.toString() ?? '';
                        final score  = _scores[sid];
                        final max    = _componentMax ?? 100;
                        final ctrl   = _controllers.putIfAbsent(sid, () => TextEditingController());

                        final initials = name.trim().split(' ').where((p) => p.isNotEmpty)
                            .take(2).map((p) => p[0]).join().toUpperCase();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(children: [
                              AvatarWidget(
                                imageUrl: s['photo_url']?.toString(),
                                initials: initials,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(admNo, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                              ])),
                              SizedBox(
                                width: 72,
                                child: TextField(
                                  controller: ctrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _scoreColor(score, max),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '—',
                                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                                    filled: true,
                                    fillColor: score != null
                                        ? _scoreColor(score, max).withOpacity(0.1)
                                        : AppColors.surface2,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: score != null ? _scoreColor(score, max) : Colors.white12,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: score != null ? _scoreColor(score, max).withOpacity(0.4) : Colors.white12,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final parsed = double.tryParse(val);
                                    setState(() {
                                      _scores[sid] = parsed != null
                                          ? parsed.clamp(0, max)
                                          : null;
                                    });
                                  },
                                ),
                              ),
                            ]),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 20)).fadeIn();
                      },
                    ),
            ),

            // Save button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving || _entered == 0
                        ? null
                        : () => _saveMarks(students),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saving…' : 'Save $_entered Scores'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ]);
      },
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: items.any((i) => i.value == value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        isDense: true,
      ),
      dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }
}
