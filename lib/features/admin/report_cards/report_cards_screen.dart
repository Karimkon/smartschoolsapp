import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final reportCardsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/report-cards$query');
  if (res.data is List) return res.data as List;
  if (res.data is Map) {
    final d = res.data as Map;
    return (d['data'] ?? d['report_cards'] ?? []) as List;
  }
  return [];
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _gradeColor(double avg) {
  if (avg >= 80) return AppColors.success;
  if (avg >= 65) return AppColors.primary;
  if (avg >= 50) return AppColors.warning;
  return AppColors.error;
}

String _grade(double avg) {
  if (avg >= 80) return 'A';
  if (avg >= 65) return 'B';
  if (avg >= 50) return 'C';
  if (avg >= 35) return 'D';
  return 'F';
}

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'published': return AppColors.success;
    case 'draft':     return AppColors.warning;
    default:          return AppColors.textHint;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportCardsScreen extends ConsumerStatefulWidget {
  const ReportCardsScreen({super.key});
  @override ConsumerState<ReportCardsScreen> createState() => _ReportCardsScreenState();
}

class _ReportCardsScreenState extends ConsumerState<ReportCardsScreen> {
  String _query   = '';
  String _student = '';
  final _searchCtrl = TextEditingController();

  String get _apiQuery => _student.isNotEmpty ? '?student_id=$_student' : '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reportCardsProvider(_apiQuery));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Report Cards',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(reportCardsProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AppSearchField(
              hint: 'Search student or class...',
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ).animate().fadeIn(),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: 5,
                itemBuilder: (_, __) =>
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 84)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load report cards',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(reportCardsProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (allCards) {
                // Client-side search
                final cards = _query.isEmpty ? allCards : allCards.where((r) {
                  final m  = r as Map;
                  final sn = (m['student_name'] ?? '').toString().toLowerCase();
                  final cn = (m['class_name'] ?? '').toString().toLowerCase();
                  final q  = _query.toLowerCase();
                  return sn.contains(q) || cn.contains(q);
                }).toList();

                if (cards.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.assignment_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No report cards found', style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }

                // Stats
                final published = cards.where((r) =>
                    (r as Map)['status']?.toString().toLowerCase() == 'published').length;
                final draft = cards.where((r) =>
                    (r as Map)['status']?.toString().toLowerCase() == 'draft').length;

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(children: [
                      _ReportStat('Total', '${cards.length}', AppColors.primary),
                      const SizedBox(width: 12),
                      _ReportStat('Published', '$published', AppColors.success),
                      const SizedBox(width: 12),
                      _ReportStat('Draft', '$draft', AppColors.warning),
                    ]),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface1,
                      onRefresh: () => ref.refresh(reportCardsProvider(_apiQuery).future),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: cards.length,
                        itemBuilder: (ctx, i) {
                          final r         = cards[i] as Map;
                          final student   = r['student_name']?.toString() ?? '';
                          final className = r['class_name']?.toString() ?? '';
                          final session   = r['session_name']?.toString() ?? r['session_year_id']?.toString() ?? '';
                          final status    = r['status']?.toString() ?? 'draft';
                          final marks     = (r['marks_obtained'] as num?)?.toDouble() ?? 0;
                          final total     = (r['total_marks'] as num?)?.toDouble() ?? 0;
                          final average   = total > 0 ? (marks / total * 100) : 0.0;
                          final grade     = r['grade']?.toString() ?? _grade(average);
                          final gColor    = _gradeColor(average);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: gColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: gColor.withOpacity(0.3)),
                                  ),
                                  child: Center(child: Text(grade,
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: gColor))),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(student,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    if (className.isNotEmpty) ...[
                                      const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint),
                                      const SizedBox(width: 4),
                                      Text(className, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(width: 8),
                                    ],
                                    if (session.isNotEmpty) ...[
                                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                                      const SizedBox(width: 4),
                                      Text(session, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ]),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Text('Average: ',
                                        style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                                    Text('${average.toStringAsFixed(1)}%',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: gColor)),
                                  ]),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  StatusBadge(
                                      label: status[0].toUpperCase() + status.substring(1),
                                      color: _statusColor(status)),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    _IBtn(Icons.remove_red_eye_rounded, AppColors.primary, () {}),
                                    const SizedBox(width: 6),
                                    _IBtn(Icons.download_rounded, AppColors.success, () {}),
                                  ]),
                                ]),
                              ]),
                            ),
                          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                        },
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ReportStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]),
  );
}

class _IBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
          color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 15),
    ),
  );
}
