import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import 'parent_fees_screen.dart' show parentChildrenProvider;

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
  int? _expandedReport;

  Color _gradeColor(String? grade) {
    if (grade == null) return AppColors.textHint;
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.primary;
    if (grade.startsWith('C')) return AppColors.warning;
    return AppColors.error;
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
                const Text('Report Cards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
                            onTap: () => setState(() { _selectedChildId = cid; _expandedReport = null; }),
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
        ElevatedButton(onPressed: () => ref.refresh(parentReportsProvider(childId)), child: const Text('Retry')),
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
              final r       = reports[i] as Map;
              final rid     = r['id'];
              final expanded = _expandedReport == rid;
              final avg     = r['average_score'];
              final grade   = r['overall_grade']?.toString();
              final term    = r['term']?.toString();
              final session = r['session_name']?.toString() ?? '';
              final subjects = (r['subjects'] as List?) ?? [];
              final rank    = r['rank'];
              final total   = r['total_students'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header row
                    GestureDetector(
                      onTap: () => setState(() => _expandedReport = expanded ? null : rid),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: _gradeColor(grade).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(grade ?? '-',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _gradeColor(grade)))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Term $term  •  $session',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Row(children: [
                            if (avg != null)
                              Text('Avg: ${(avg as num).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (rank != null && total != null) ...[
                              const SizedBox(width: 12),
                              const Icon(Icons.emoji_events_rounded, size: 12, color: AppColors.warning),
                              const SizedBox(width: 3),
                              Text('Rank $rank / $total', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ]),
                        ])),
                        Icon(expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textHint),
                      ]),
                    ),

                    // Expanded subjects
                    if (expanded) ...[
                      const Divider(color: Colors.white12, height: 20),
                      if (subjects.isEmpty)
                        const Text('No subject details', style: TextStyle(fontSize: 12, color: AppColors.textHint))
                      else
                        ...subjects.map((sub) {
                          final subMap = sub as Map;
                          final marks  = (subMap['marks_obtained'] as num?)?.toDouble() ?? 0;
                          final total2 = (subMap['total_marks'] as num?)?.toInt() ?? 100;
                          final sg     = subMap['grade']?.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: _gradeColor(sg).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(child: Text(sg ?? '-', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _gradeColor(sg)))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(subMap['subject']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: total2 > 0 ? (marks / total2).clamp(0.0, 1.0) : 0,
                                    minHeight: 4,
                                    backgroundColor: AppColors.surface3,
                                    valueColor: AlwaysStoppedAnimation<Color>(_gradeColor(sg)),
                                  ),
                                ),
                              ])),
                              const SizedBox(width: 10),
                              Text('${marks.toStringAsFixed(0)}/$total2',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ]),
                          );
                        }),

                      // Teacher comment
                      if (r['class_teacher_comment'] != null && r['class_teacher_comment'].toString().isNotEmpty) ...[
                        const Divider(color: Colors.white12, height: 16),
                        Text('Teacher\'s Comment', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        const SizedBox(height: 4),
                        Text(r['class_teacher_comment'].toString(),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
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
