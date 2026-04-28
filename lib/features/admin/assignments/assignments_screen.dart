import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final assignmentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, String>>((ref, params) async {
  final queryParams = <String, dynamic>{};
  if ((params['search'] ?? '').isNotEmpty) queryParams['search'] = params['search'];
  if ((params['status'] ?? 'All') != 'All') {
    queryParams['status'] = params['status']!.toLowerCase();
  }
  final res = await ApiService().get('/assignments', params: queryParams);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAssignmentsScreen extends ConsumerStatefulWidget {
  const AdminAssignmentsScreen({super.key});

  @override
  ConsumerState<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends ConsumerState<AdminAssignmentsScreen> {
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
      case 'active':    return AppColors.primary;
      case 'overdue':   return AppColors.error;
      case 'completed': return AppColors.success;
      default:          return AppColors.textSecondary;
    }
  }

  Color _filterColor(String f) {
    switch (f) {
      case 'Active':    return AppColors.primary;
      case 'Overdue':   return AppColors.error;
      case 'Completed': return AppColors.success;
      default:          return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(assignmentsProvider({'search': _query, 'status': _filter}));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assignments',
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
                hint: 'Search by title or class...',
                controller: _searchCtrl,
                onChanged: _onSearch,
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['All', 'Active', 'Overdue', 'Completed'].map((f) {
                    final sel = f == _filter;
                    final color = _filterColor(f);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? color : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? color : Colors.white.withOpacity(0.07),
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
                  const Text('Failed to load assignments',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(assignmentsProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
              data: (data) {
                final assignments = List<dynamic>.from(
                    data['data'] ?? data['assignments'] ?? []);
                if (assignments.isEmpty) {
                  return const Center(
                    child: Text('No assignments found',
                        style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(assignmentsProvider),
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: assignments.length,
                    itemBuilder: (ctx, i) {
                      final a = Map<String, dynamic>.from(assignments[i] as Map);
                      final title = a['title'] ?? a['name'] ?? 'Assignment';
                      final subject = a['subject'] ?? a['subject_name'] ?? '';
                      final className = a['class_name'] ?? a['class'] ?? '';
                      final teacher = a['teacher'] ?? a['teacher_name'] ?? '';
                      final dueDate = a['due_date'] ?? a['deadline'] ?? '';
                      final status = a['status'] ?? 'active';
                      final statusLabel = status.toString()[0].toUpperCase() +
                          status.toString().substring(1);
                      final submitted = a['submitted_count'] as int? ??
                          a['submitted'] as int? ?? 0;
                      final total = a['total_students'] as int? ??
                          a['total'] as int? ?? 0;
                      final pct = total > 0 ? submitted / total : 0.0;
                      final color = _statusColor(status.toString());

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.roleTeacher.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.assignment_rounded,
                                      color: AppColors.roleTeacher, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title.toString(),
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        [subject, className]
                                            .where((s) => s.toString().isNotEmpty)
                                            .join(' · '),
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(label: statusLabel, color: color),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                if (teacher.toString().isNotEmpty) ...[
                                  const Icon(Icons.person_rounded,
                                      size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text(teacher.toString(),
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textSecondary)),
                                ],
                                const Spacer(),
                                if (dueDate.toString().isNotEmpty) ...[
                                  const Icon(Icons.calendar_today_rounded,
                                      size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text('Due: $dueDate',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: status.toString().toLowerCase() == 'overdue'
                                              ? AppColors.error
                                              : AppColors.textSecondary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ]),
                              if (total > 0) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: AppColors.surface3,
                                        valueColor: AlwaysStoppedAnimation(color),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('$submitted/$total',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: color)),
                                ]),
                              ],
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
