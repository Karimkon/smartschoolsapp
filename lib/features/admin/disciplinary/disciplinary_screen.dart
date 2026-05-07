import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final disciplinaryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/disciplinary$query');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String s) {
  switch (s.toLowerCase()) {
    case 'resolved': return AppColors.success;
    case 'open':     return AppColors.warning;
    default:         return AppColors.error; // escalated, etc.
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class DisciplinaryScreen extends ConsumerStatefulWidget {
  const DisciplinaryScreen({super.key});
  @override ConsumerState<DisciplinaryScreen> createState() => _DisciplinaryScreenState();
}

class _DisciplinaryScreenState extends ConsumerState<DisciplinaryScreen> {
  String _filter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  final _filters = const ['All', 'open', 'resolved'];
  final _filterLabels = const ['All', 'Open', 'Resolved'];

  String get _apiQuery {
    if (_filter == 'All') return '';
    return '?status=$_filter';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(disciplinaryProvider(_apiQuery));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Disciplinary',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(disciplinaryProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Counts
              async.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  final counts = data['counts'] as Map? ?? {};
                  final total  = (data['data'] as Map?)?['total'] ?? 0;
                  return Row(children: [
                    Expanded(child: _QuickStat('Total', '$total', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickStat('Open', (counts['open'] ?? 0).toString(), AppColors.warning)),
                    const SizedBox(width: 10),
                    Expanded(child: _QuickStat('Resolved', (counts['resolved'] ?? 0).toString(), AppColors.success)),
                  ]).animate().fadeIn();
                },
              ),
              const SizedBox(height: 12),

              // Search
              AppSearchField(
                hint: 'Search student or incident...',
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ).animate(delay: 100.ms).fadeIn(),

              const SizedBox(height: 12),

              // Filter chips
              Row(children: List.generate(_filters.length, (i) {
                final sel   = _filter == _filters[i];
                final color = i == 0 ? AppColors.primary : _statusColor(_filters[i]);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = _filters[i]),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                          color: sel ? color : AppColors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? color : Colors.white.withOpacity(0.07))),
                      child: Text(_filterLabels[i],
                          style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary,
                              fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              })),
            ]),
          ),

          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: 5,
                itemBuilder: (_, __) =>
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 90)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load records', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(disciplinaryProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (data) {
                final raw     = data['data'];
                final all     = (raw is Map ? raw['data'] : raw) as List? ?? [];
                // Client-side search filter
                final records = _query.isEmpty ? all : all.where((r) {
                  final m = r as Map;
                  final sn = (m['student_name'] ?? '').toString().toLowerCase();
                  final it = (m['incident_type'] ?? '').toString().toLowerCase();
                  final q  = _query.toLowerCase();
                  return sn.contains(q) || it.contains(q);
                }).toList();

                if (records.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.gavel_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No disciplinary records', style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () => ref.refresh(disciplinaryProvider(_apiQuery).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: records.length,
                    itemBuilder: (_, i) {
                      final r          = records[i] as Map;
                      final student    = r['student_name']?.toString() ?? '';
                      final className  = r['class_name']?.toString() ?? '';
                      final incident   = r['incident_type']?.toString() ?? '';
                      final desc       = r['description']?.toString() ?? '';
                      final action     = r['action_taken']?.toString() ?? '';
                      final date       = r['incident_date']?.toString() ?? '';
                      final status     = r['status']?.toString() ?? 'open';
                      final reportedBy = r['reported_by_name']?.toString() ?? '';
                      final statColor  = _statusColor(status);

                      final initials = student.trim().split(' ')
                          .where((x) => x.isNotEmpty)
                          .take(2)
                          .map((x) => x[0].toUpperCase())
                          .join();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              AvatarWidget(initials: initials.isEmpty ? '?' : initials,
                                  color: statColor, size: 40),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(student,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  if (className.isNotEmpty) ...[
                                    Text(className,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(width: 6),
                                  ],
                                  Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                                  const SizedBox(width: 3),
                                  Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ]),
                              ])),
                              StatusBadge(
                                  label: status[0].toUpperCase() + status.substring(1),
                                  color: statColor),
                            ]),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const Icon(Icons.report_rounded, size: 13, color: AppColors.error),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(incident,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary))),
                                ]),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(desc,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                                if (action.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.gavel_rounded, size: 12, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text('Action: $action',
                                        style: const TextStyle(fontSize: 11, color: AppColors.warning))),
                                  ]),
                                ],
                                if (reportedBy.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Reported by: $reportedBy',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ],
                              ]),
                            ),
                          ]),
                        ),
                      ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05);
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _QuickStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]),
  );
}
