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
  if (res.data is! Map) throw Exception('Unexpected response format');
  return Map<String, dynamic>.from(res.data as Map);
});

// Key format: "classId|curriculumId|sessionId|subjectId|term|streamId"
// Using String (not Map) so Riverpod family equality works correctly.
final marksEntryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
  final parts = key.split('|');
  final params = <String, String>{
    'class_id':        parts[0],
    'curriculum_id':   parts[1],
    'session_year_id': parts[2],
    'term':            parts[4],
  };
  if (parts[3].isNotEmpty) params['subject_id'] = parts[3];
  if (parts.length > 5 && parts[5].isNotEmpty) params['stream_id'] = parts[5];
  final res = await ApiService().get('/marks/entry', params: params);
  if (res.data is! Map) throw Exception('Unexpected response format');
  return Map<String, dynamic>.from(res.data as Map);
});

final classStreamsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, classId) async {
  final res = await ApiService().get('/streams', params: {'class_id': classId});
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? []);
  return const [];
});

/// MySQL DECIMAL columns arrive as JSON strings ("100.00") — never cast with `as num`.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

String _fmtScore(double v) =>
    v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

// ── Screen ────────────────────────────────────────────────────────────────────

class MarksScreen extends ConsumerStatefulWidget {
  const MarksScreen({super.key});

  @override
  ConsumerState<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends ConsumerState<MarksScreen> {
  // Filter state
  String? _classId, _className;
  String? _curriculumId;
  String? _sessionYearId;
  String? _subjectId, _subjectName;
  String? _streamId;
  int _term = 1;

  // Grid state — cell key is "studentId|componentId"
  final Map<String, TextEditingController> _cellCtrl = {};
  final Map<String, double?> _cellVal = {};
  final Set<String> _prefilled = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _cellCtrl.values) c.dispose();
    super.dispose();
  }

  bool get _readyToLoad =>
      _classId != null && _curriculumId != null && _sessionYearId != null;
  bool get _readyToEnter => _readyToLoad && _subjectId != null;

  String get _entryKey =>
      '${_classId ?? ''}|${_curriculumId ?? ''}|${_sessionYearId ?? ''}|${_subjectId ?? ''}|$_term|${_streamId ?? ''}';

  void _resetGrid() {
    _cellVal.clear();
    _prefilled.clear();
    for (final c in _cellCtrl.values) c.dispose();
    _cellCtrl.clear();
  }

  Color _scoreColor(double? score, double max) {
    if (score == null || max == 0) return AppColors.textHint;
    final pct = score / max;
    if (pct >= 0.8) return AppColors.success;
    if (pct >= 0.65) return AppColors.primary;
    if (pct >= 0.5) return AppColors.warning;
    return AppColors.error;
  }

  int get _entered => _cellVal.values.where((v) => v != null).length;

  Future<void> _saveAll(List<dynamic> components) async {
    if (!_readyToEnter || _saving) return;
    setState(() => _saving = true);
    int savedTotal = 0, compCount = 0;
    try {
      for (final comp in components) {
        final cid = comp['id'].toString();
        final scores = <String, dynamic>{};
        _cellVal.forEach((key, val) {
          final parts = key.split('|');
          if (parts.length == 2 && parts[1] == cid && val != null) {
            scores[parts[0]] = val;
          }
        });
        if (scores.isEmpty) continue;
        await ApiService().post('/marks/save', data: {
          'curriculum_id':   _curriculumId,
          'session_year_id': _sessionYearId,
          'subject_id':      _subjectId,
          'component_id':    cid,
          'term':            _term,
          'scores':          scores,
        });
        savedTotal += scores.length;
        compCount++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(savedTotal > 0
              ? 'Saved $savedTotal scores across $compCount component${compCount == 1 ? '' : 's'} ✓'
              : 'Nothing to save — enter some scores first'),
          backgroundColor: savedTotal > 0 ? AppColors.success : AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
        if (savedTotal > 0) {
          _resetGrid();
          ref.invalidate(marksEntryProvider(_entryKey));
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to save marks — check your connection and try again'),
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
                if (sess != null) setState(() => _sessionYearId = currentSessId);
              });
            }
            // Auto-select when the teacher has exactly one class
            if (_classId == null && classes.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _classId != null) return;
                setState(() {
                  _classId = classes[0]['id'].toString();
                  _className = classes[0]['name']?.toString();
                });
              });
            }

            return Column(children: [
              // ── Filter Bar ────────────────────────────────────────────────
              Container(
                color: AppColors.surface1,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(children: [
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
                        _subjectId = null; _resetGrid();
                      }),
                    )),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: _dropdown(
                        label: 'Term',
                        value: _term.toString(),
                        items: [1, 2, 3].map((t) => DropdownMenuItem(
                          value: t.toString(),
                          child: Text('Term $t'),
                        )).toList(),
                        onChanged: (v) => setState(() {
                          _term = int.parse(v!);
                          _resetGrid();
                        }),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
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
                        _subjectId = null; _streamId = null; _resetGrid();
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
                        _subjectId = null; _resetGrid();
                      }),
                    )),
                  ]),
                  if (_classId != null) _buildStreamRow(),
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

  Widget _buildStreamRow() {
    final streamsAsync = ref.watch(classStreamsProvider(_classId!));
    return streamsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        if (streams.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: _dropdown(
            label: 'Stream (optional)',
            value: _streamId ?? '',
            items: [
              const DropdownMenuItem(value: '', child: Text('All Streams')),
              ...streams.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['name']?.toString() ?? '',
                        overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => setState(() {
              _streamId = (v == null || v.isEmpty) ? null : v;
              _resetGrid();
            }),
          ),
        );
      },
    );
  }

  Widget _buildEntryArea() {
    final entryAsync = ref.watch(marksEntryProvider(_entryKey));

    return entryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
        const SizedBox(height: 12),
        const Text('Failed to load entry data', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(marksEntryProvider(_entryKey)),
          child: const Text('Retry'),
        ),
      ])),
      data: (entry) {
        final subjects   = List<dynamic>.from(entry['subjects']   ?? []);
        final components = List<dynamic>.from(entry['components'] ?? []);
        final students   = List<dynamic>.from(entry['students']   ?? []);
        final rawAll     = entry['existing_scores_all'];
        final existingAll = (rawAll is Map)
            ? Map<String, dynamic>.from(rawAll)
            : <String, dynamic>{};

        // Auto-select when the teacher has exactly one subject
        if (_subjectId == null && subjects.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _subjectId != null) return;
            setState(() {
              _subjectId = subjects[0]['id'].toString();
              _subjectName = subjects[0]['name']?.toString();
            });
          });
        }

        // Prefill grid from existing scores AFTER build
        if (_readyToEnter && students.isNotEmpty && components.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            bool changed = false;
            for (final s in students) {
              final sid = s['id'].toString();
              final exStudent = existingAll[sid];
              for (final comp in components) {
                final cid = comp['id'].toString();
                final key = '$sid|$cid';
                if (_prefilled.contains(key)) continue;
                _prefilled.add(key);
                final raw = (exStudent is Map) ? exStudent[cid] : null;
                final score = _toDouble((raw is Map) ? raw['score'] : null);
                if (score != null) {
                  _cellVal[key] = score;
                  _cellCtrl.putIfAbsent(key, () => TextEditingController()).text =
                      _fmtScore(score);
                  changed = true;
                }
              }
            }
            if (changed) setState(() {});
          });
        }

        return Column(children: [
          // Subject selector
          Container(
            color: AppColors.surface2,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: _dropdown(
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
                _resetGrid();
              }),
            ),
          ),

          if (!_readyToEnter)
            const Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.menu_book_rounded, size: 48, color: AppColors.textHint),
              SizedBox(height: 12),
              Text('Select a subject to start entering marks',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ])))
          else if (components.isEmpty)
            const Expanded(child: Center(child: Text(
              'No assessment components configured for this curriculum.\nSet them up on the web (Assessment Builder).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )))
          else ...[
            // Component legend — teacher always knows what each column means
            Container(
              width: double.infinity,
              color: AppColors.surface1,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(
                    '${_subjectName ?? ''} — ${_className ?? ''} · ${students.length} students',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  )),
                  Text('$_entered entered',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textHint)),
                ]),
                const SizedBox(height: 6),
                Wrap(spacing: 10, runSpacing: 4, children: [
                  for (final comp in components)
                    Text(
                      '${_compShort(comp)} = ${comp['label'] ?? comp['name']} (out of ${_fmtScore(_toDouble(comp['max_score']) ?? 100)})',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                ]),
              ]),
            ),

            // ── Grid ─────────────────────────────────────────────────────
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No students found', style: TextStyle(color: AppColors.textSecondary)))
                  : LayoutBuilder(builder: (ctx, constraints) {
                      const nameW = 148.0, cellW = 74.0, initialsW = 46.0;
                      final tableW = (nameW + components.length * cellW + initialsW)
                          .clamp(constraints.maxWidth, double.infinity);
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableW,
                          child: Column(children: [
                            // Header row
                            Container(
                              color: AppColors.surface2,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                const SizedBox(width: nameW, child: Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text('STUDENT', style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w800,
                                      color: AppColors.textHint, letterSpacing: 0.5)),
                                )),
                                for (final comp in components)
                                  SizedBox(width: cellW, child: Column(children: [
                                    Text(_compShort(comp),
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                    Text('/${_fmtScore(_toDouble(comp['max_score']) ?? 100)}',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                  ])),
                                const SizedBox(width: initialsW, child: Center(
                                  child: Text('INT.', style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w800,
                                      color: AppColors.textHint)),
                                )),
                              ]),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: students.length,
                                itemBuilder: (_, i) {
                                  final s   = students[i] as Map;
                                  final sid = s['id'].toString();
                                  final name = s['name']?.toString() ?? '';
                                  final exStudent = existingAll[sid];
                                  String initials = '';
                                  if (exStudent is Map) {
                                    for (final v in exStudent.values) {
                                      final ini = (v is Map) ? v['initials']?.toString() : null;
                                      if (ini != null && ini.isNotEmpty) { initials = ini; break; }
                                    }
                                  }
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: i.isEven ? Colors.transparent : Colors.white.withOpacity(0.02),
                                      border: const Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(children: [
                                      SizedBox(width: nameW, child: Padding(
                                        padding: const EdgeInsets.only(left: 12, right: 6),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                          if ((s['stream_name'] ?? '').toString().isNotEmpty)
                                            Text(s['stream_name'].toString(),
                                                style: const TextStyle(fontSize: 9.5, color: AppColors.textHint)),
                                        ]),
                                      )),
                                      for (final comp in components)
                                        SizedBox(width: cellW, child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: _scoreCell(sid, comp),
                                        )),
                                      SizedBox(width: initialsW, child: Center(
                                        child: Text(initials,
                                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
                                      )),
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ]),
                        ),
                      );
                    }),
            ),

            // Save button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving || _entered == 0 ? null : () => _saveAll(components),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saving…' : 'Save All ($_entered scores)'),
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

  /// Short column label: prefer the component's code-like name (C1, EOT…);
  /// fall back to initials of the label.
  String _compShort(dynamic comp) {
    final name = comp['name']?.toString().trim() ?? '';
    final label = comp['label']?.toString().trim() ?? '';
    if (name.isNotEmpty && name.length <= 6) return name.toUpperCase();
    final src = label.isNotEmpty ? label : name;
    final words = src.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length == 1) return words[0].substring(0, words[0].length.clamp(0, 5)).toUpperCase();
    return words.map((w) => w[0]).take(4).join().toUpperCase();
  }

  Widget _scoreCell(String sid, dynamic comp) {
    final cid  = comp['id'].toString();
    final key  = '$sid|$cid';
    final max  = _toDouble(comp['max_score']) ?? 100;
    final val  = _cellVal[key];
    final ctrl = _cellCtrl.putIfAbsent(key, () => TextEditingController());

    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _scoreColor(val, max),
      ),
      decoration: InputDecoration(
        hintText: '—',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
        filled: true,
        fillColor: val != null ? _scoreColor(val, max).withOpacity(0.1) : AppColors.surface2,
        contentPadding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: val != null ? _scoreColor(val, max) : Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(
            color: val != null ? _scoreColor(val, max).withOpacity(0.4) : Colors.white12,
          ),
        ),
      ),
      onChanged: (raw) {
        final parsed = double.tryParse(raw);
        setState(() {
          if (parsed == null) {
            _cellVal[key] = null;
          } else if (parsed > max) {
            // Never allow a score above the component maximum
            _cellVal[key] = max;
            ctrl.text = _fmtScore(max);
            ctrl.selection = TextSelection.collapsed(offset: ctrl.text.length);
          } else {
            _cellVal[key] = parsed < 0 ? 0 : parsed;
          }
        });
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
