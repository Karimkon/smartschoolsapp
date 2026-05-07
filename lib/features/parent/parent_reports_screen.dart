import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import 'parent_fees_screen.dart' show parentChildrenProvider;
import '../shared/report_card_pdf_screen.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final parentReportsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, int>((ref, childId) async {
  final res = await ApiService().get('/parent/children/$childId/reports');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ParentReportsScreen extends ConsumerStatefulWidget {
  const ParentReportsScreen({super.key});

  @override
  ConsumerState<ParentReportsScreen> createState() => _ParentReportsScreenState();
}

class _ParentReportsScreenState extends ConsumerState<ParentReportsScreen> {
  int? _selectedChildId;
  int? _expandedIndex;

  Color _gradeColor(String? grade) {
    if (grade == null || grade == '—' || grade == '-') return AppColors.textHint;
    if (grade.startsWith('A') || grade == 'ممتاز') return AppColors.success;
    if (grade.startsWith('B') || grade == 'جيد جداً') return AppColors.primary;
    if (grade.startsWith('C') || grade == 'جيد') return AppColors.roleTeacher;
    if (grade.startsWith('D') || grade == 'مقبول') return AppColors.warning;
    return AppColors.error;
  }

  Color _curriculumColor(String type) {
    switch (type) {
      case 'arabic':   return AppColors.roleSuperAdmin;
      case 'a_level':  return AppColors.roleTeacher;
      case 'cbc':      return AppColors.primary;
      default:         return AppColors.roleAccountant;
    }
  }

  String _curriculumLabel(String type) {
    switch (type) {
      case 'arabic':   return 'Theology';
      case 'a_level':  return 'A-Level';
      case 'cbc':      return 'CBC';
      default:         return 'Standard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Text('Report Cards',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            ),

            // Child selector
            childrenAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerCard(height: 48)),
              error: (_, __) => const SizedBox(),
              data: (children) {
                if (_selectedChildId == null && children.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedChildId = children.first['id'] as int);
                  });
                }
                if (children.length <= 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: children.map((c) {
                        final cid  = c['id'] as int;
                        final name = '${c['first_name']} ${c['last_name']}'.trim();
                        final sel  = _selectedChildId == cid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() { _selectedChildId = cid; _expandedIndex = null; }),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(name, style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: _selectedChildId == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildReports(_selectedChildId!),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildReports(int childId) {
    final reportsAsync = ref.watch(parentReportsProvider(childId));

    return reportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load reports', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.refresh(parentReportsProvider(childId)),
          child: const Text('Retry'),
        ),
      ])),
      data: (reports) {
        if (reports.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.school_rounded, color: AppColors.textHint, size: 52),
            SizedBox(height: 12),
            Text('No report cards yet', style: TextStyle(color: AppColors.textSecondary)),
          ]));
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface1,
          onRefresh: () => ref.refresh(parentReportsProvider(childId).future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: reports.length,
            itemBuilder: (_, i) {
              final r          = Map<String, dynamic>.from(reports[i] as Map);
              final expanded   = _expandedIndex == i;
              final grade      = r['overall_grade']?.toString();
              final achievement= r['overall_achievement']?.toString() ?? '';
              final term       = r['term']?.toString();
              final session    = r['session_name']?.toString() ?? '';
              final currName   = r['curriculum_name']?.toString() ?? '';
              final currType   = r['curriculum_type']?.toString() ?? 'standard';
              final subjects   = (r['subjects'] as List?) ?? [];
              final rank       = r['rank'];
              final totalStu   = r['total_students'];
              final avg        = r['average_score'];
              final comment    = (r['teacher_comment']?.toString() ?? '').isNotEmpty
                                    ? r['teacher_comment']
                                    : r['auto_class_comment'];
              final commentAr  = r['auto_class_comment_ar']?.toString() ?? '';
              final headComment= r['head_comment']?.toString() ?? '';

              final currColor = _curriculumColor(currType);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header row
                    GestureDetector(
                      onTap: () => setState(() => _expandedIndex = expanded ? null : i),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: _gradeColor(grade).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(
                            grade ?? '-',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _gradeColor(grade)),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text('Term $term  •  $session',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: currColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_curriculumLabel(currType),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: currColor)),
                            ),
                          ]),
                          if (currName.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(currName, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ],
                          const SizedBox(height: 4),
                          Wrap(spacing: 12, children: [
                            if (avg != null)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.bar_chart_rounded, size: 11, color: AppColors.textSecondary),
                                const SizedBox(width: 3),
                                Text('Avg: ${(avg as num).toStringAsFixed(1)}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ]),
                            if (rank != null && totalStu != null)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.emoji_events_rounded, size: 11, color: AppColors.warning),
                                const SizedBox(width: 3),
                                Text('Rank $rank / $totalStu',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ]),
                          ]),
                          if (achievement.isNotEmpty)
                            Text(achievement,
                                style: TextStyle(fontSize: 11, color: _gradeColor(grade), fontWeight: FontWeight.w600)),
                        ])),
                        Icon(expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textHint),
                      ]),
                    ),

                    // Expanded content
                    if (expanded) ...[
                      const Divider(color: Colors.white12, height: 20),

                      // Subject rows
                      if (subjects.isEmpty)
                        const Text('No subject details', style: TextStyle(fontSize: 12, color: AppColors.textHint))
                      else
                        ...subjects.asMap().entries.map((entry) {
                          final sub    = Map<String, dynamic>.from(entry.value as Map);
                          final sName  = sub['name']?.toString() ?? '';
                          final sGrade = sub['grade']?.toString() ?? '—';
                          final sAch   = sub['achievement']?.toString() ?? '';
                          final sPct   = (sub['percent'] as num?)?.toDouble();
                          final sWt    = (sub['weighted'] as num?)?.toDouble();
                          final sTotal = (sub['total'] as num?)?.toDouble();

                          // For display: use percent if available, else weighted or total
                          double? displayPct = sPct;
                          if (displayPct == null && sWt != null && currType == 'a_level') {
                            displayPct = sWt / 5.0 * 100;
                          } else if (displayPct == null && sTotal != null) {
                            displayPct = sTotal.clamp(0, 100).toDouble();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _gradeColor(sGrade).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text(sGrade,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _gradeColor(sGrade)))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(sName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                if (sAch.isNotEmpty)
                                  Text(sAch, style: TextStyle(fontSize: 10, color: _gradeColor(sGrade))),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: displayPct != null ? (displayPct / 100).clamp(0.0, 1.0) : 0,
                                    minHeight: 4,
                                    backgroundColor: AppColors.surface3,
                                    valueColor: AlwaysStoppedAnimation<Color>(_gradeColor(sGrade)),
                                  ),
                                ),
                              ])),
                              const SizedBox(width: 10),
                              Text(
                                displayPct != null ? '${displayPct.toStringAsFixed(1)}%' : '—',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                            ]),
                          );
                        }),

                      // Comments section
                      if ((comment?.toString() ?? '').isNotEmpty || commentAr.isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 16),
                        const Text('Class Teacher\'s Comment',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 6),
                        if (commentAr.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(commentAr,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                                    fontStyle: FontStyle.italic)),
                          ),
                        if ((comment?.toString() ?? '').isNotEmpty)
                          Text(comment.toString(),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                                  fontStyle: FontStyle.italic)),
                      ],

                      if (headComment.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Head Teacher\'s Comment',
                            style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 4),
                        Text(headComment,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
                      ],

                      // ── View Full PDF ──────────────────────────────────
                      if (r['curriculum_id'] != null && r['session_year_id'] != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final termInt = int.tryParse(r['term']?.toString() ?? '1') ?? 1;
                              final firstName = (r['student_name'] ?? '').toString().isNotEmpty
                                  ? r['student_name'].toString()
                                  : 'Student';
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ReportCardPdfScreen(
                                  studentId:     _selectedChildId!,
                                  curriculumId:  int.parse(r['curriculum_id'].toString()),
                                  sessionYearId: int.parse(r['session_year_id'].toString()),
                                  term:          termInt,
                                  studentName:   firstName,
                                  isParent:      true,
                                ),
                              ));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                            label: const Text('View Full Report Card',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ],
                  ]),
                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(),
              );
            },
          ),
        );
      },
    );
  }
}
