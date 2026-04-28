import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final studentReportCardsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/report-cards');
  final data = res.data;
  if (data is List) return data;
  if (data is Map) return (data['data'] as List?) ?? [];
  return [];
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentResultsScreen extends ConsumerStatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  ConsumerState<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends ConsumerState<StudentResultsScreen> {
  int _selectedIdx = 0;

  Color _gradeColor(String? g) {
    if (g == null) return AppColors.textSecondary;
    if (g.startsWith('A')) return AppColors.success;
    if (g.startsWith('B')) return AppColors.primary;
    if (g.startsWith('C')) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentReportCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Results', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(studentReportCardsProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              const ShimmerCard(height: 56),
              const SizedBox(height: 16),
              const ShimmerCard(height: 110),
              const SizedBox(height: 16),
              ...List.generate(5, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerCard(height: 68),
              )),
            ],
          ),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
              const SizedBox(height: 12),
              const Text('Could not load results', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(studentReportCardsProvider),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (cards) {
            if (cards.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.assignment_outlined, color: AppColors.textHint, size: 64),
                  const SizedBox(height: 16),
                  const Text('No report cards available yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Results will appear here once published by your teacher',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12), textAlign: TextAlign.center),
                ]),
              );
            }

            final card = cards[_selectedIdx.clamp(0, cards.length - 1)] as Map;

            return RefreshIndicator(
              color: AppColors.roleStudent,
              backgroundColor: AppColors.surface1,
              onRefresh: () async => ref.invalidate(studentReportCardsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                children: [
                  // Term selector
                  if (cards.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedIdx.clamp(0, cards.length - 1),
                          isExpanded: true,
                          dropdownColor: AppColors.surface1,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                          items: List.generate(cards.length, (i) {
                            final c    = cards[i] as Map;
                            final term = c['term']?.toString() ?? '';
                            final year = c['session_name']?.toString() ?? c['session_year']?.toString() ?? '';
                            return DropdownMenuItem(
                              value: i,
                              child: Text([if (term.isNotEmpty) 'Term $term', if (year.isNotEmpty) year].join(' — ')),
                            );
                          }),
                          onChanged: (v) { if (v != null) setState(() => _selectedIdx = v); },
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                  const SizedBox(height: 16),

                  // Summary card
                  _buildSummaryCard(card),

                  const SizedBox(height: 20),

                  // Subjects list
                  _buildSubjectsSection(card),

                  const SizedBox(height: 20),

                  // Grade legend
                  _buildGradeLegend(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map card) {
    final grade   = card['overall_grade']?.toString() ?? card['grade']?.toString() ?? '—';
    final avg     = (card['average_score'] as num?)?.toDouble() ?? (card['average'] as num?)?.toDouble() ?? 0;
    final rank    = card['rank']?.toString() ?? card['position']?.toString() ?? '—';
    final total   = card['total_students']?.toString() ?? '—';
    final term    = card['term']?.toString() ?? '—';
    final year    = card['session_name']?.toString() ?? card['session_year']?.toString() ?? '';

    return GlassCard(
      gradient: AppColors.primaryGradient,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Grade', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(grade, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Average: ${avg.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                if (year.isNotEmpty)
                  Text('Term $term — $year', style: const TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          if (rank != '—')
            Column(children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text('#$rank', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('of $total', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ]),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08);
  }

  Widget _buildSubjectsSection(Map card) {
    final rows = (card['subject_rows'] as List?) ?? (card['subjects'] as List?) ?? [];

    if (rows.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.assignment_outlined, color: AppColors.textHint, size: 36),
            SizedBox(height: 8),
            Text('No subject details available', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      );
    }

    final colors = [AppColors.primary, AppColors.roleTeacher, AppColors.accent,
                    AppColors.warning, AppColors.roleAccountant, AppColors.success];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Subject Results'),
        const SizedBox(height: 12),
        ...rows.asMap().entries.map((e) {
          final row     = e.value as Map;
          final i       = e.key;
          final subject = (row['subject'] as Map?)?['name']?.toString()
              ?? row['subject_name']?.toString()
              ?? row['subject']?.toString()
              ?? 'Subject';
          final total   = (row['total'] as num?)?.toDouble() ?? 0;
          final grade   = row['grade']?.toString() ?? '—';
          final remarks = row['remarks']?.toString() ?? '';
          final color   = colors[i % colors.length];
          final gradeColor = _gradeColor(grade);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(width: 4, height: 52,
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject.toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Row(children: [
                          if (total > 0) ...[
                            Text('${total.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total / 100,
                                minHeight: 5,
                                backgroundColor: AppColors.surface3,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                        ]),
                        if (remarks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(remarks, style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: gradeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(grade, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: gradeColor)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: 150 + i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
        }),
      ],
    );
  }

  Widget _buildGradeLegend() {
    const legend = [
      ('A+', '90–100', AppColors.accent),
      ('A',  '80–89',  AppColors.success),
      ('B+', '70–79',  AppColors.primary),
      ('B',  '60–69',  AppColors.primary),
      ('C',  '50–59',  AppColors.warning),
      ('D',  '40–49',  AppColors.error),
      ('F',  '0–39',   AppColors.error),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Grade Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: legend.map((l) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: l.$3.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: l.$3.withOpacity(0.3)),
              ),
              child: Text('${l.$1}: ${l.$2}',
                  style: TextStyle(fontSize: 10, color: l.$3, fontWeight: FontWeight.w600)),
            )).toList(),
          ),
        ],
      ),
    ).animate(delay: 400.ms).fadeIn();
  }
}
