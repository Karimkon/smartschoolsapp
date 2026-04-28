import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final examsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final queryParams = <String, dynamic>{};
  if ((params['search'] ?? '').isNotEmpty) queryParams['search'] = params['search'];
  if ((params['status'] ?? 'All') != 'All') {
    queryParams['status'] = params['status']!.toLowerCase();
  }
  final res = await ApiService().get('/exams', params: queryParams);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'upcoming': return AppColors.warning;
      case 'ongoing':  return AppColors.success;
      case 'completed':return AppColors.textHint;
      default:         return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(examsProvider({'search': _query, 'status': _filter}));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Exam Schedules',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(children: [
              AppSearchField(
                hint: 'Search exam, subject, class...',
                controller: _searchCtrl,
                onChanged: _onSearch,
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((f) {
                    final sel = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.warning : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? AppColors.warning : Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  color: sel ? Colors.white : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: 5,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ShimmerBox(height: 110, borderRadius: 14),
                ),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load exams',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(examsProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
              data: (data) {
                final exams = List<dynamic>.from(data['data'] ?? data['exams'] ?? []);
                if (exams.isEmpty) {
                  return const Center(
                    child: Text('No exams found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(examsProvider),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: exams.length,
                    itemBuilder: (ctx, i) {
                      final e = Map<String, dynamic>.from(exams[i] as Map);
                      final title = e['title'] ?? e['name'] ?? 'Exam';
                      final subject = e['subject'] ?? e['subject_name'] ?? '';
                      final className = e['class'] ?? e['class_name'] ?? '';
                      final date = e['date'] ?? e['exam_date'] ?? '';
                      final startTime = e['start_time'] ?? '';
                      final endTime = e['end_time'] ?? '';
                      final room = e['room'] ?? e['venue'] ?? '';
                      final status = e['status'] ?? 'upcoming';
                      final statusLabel = status.toString()[0].toUpperCase() +
                          status.toString().substring(1);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.quiz_rounded,
                                      color: AppColors.warning, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title.toString(),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        [subject, className]
                                            .where((s) => s.toString().isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(
                                    label: statusLabel,
                                    color: _statusColor(status.toString())),
                              ]),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(children: [
                                  if (date.toString().isNotEmpty)
                                    _InfoChip(Icons.calendar_today_rounded, date.toString()),
                                  if (startTime.toString().isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    _InfoChip(Icons.access_time_rounded,
                                        '$startTime${endTime.toString().isNotEmpty ? ' – $endTime' : ''}'),
                                  ],
                                  if (room.toString().isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    _InfoChip(Icons.room_rounded, room.toString()),
                                  ],
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: i * 50))
                          .fadeIn()
                          .slideY(begin: 0.05, end: 0);
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]);
}
