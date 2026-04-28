import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final teacherAssignmentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, status) async {
  final params = status == 'All'
      ? <String, dynamic>{}
      : {'status': status.toLowerCase()};
  final res = await ApiService().get('/assignments', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherAssignmentsScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends ConsumerState<TeacherAssignmentsScreen> {
  String _filter = 'All';

  static const _filters = ['All', 'Active', 'Overdue', 'Completed'];

  static const _colors = [
    AppColors.primary, AppColors.roleTeacher, AppColors.accent,
    AppColors.warning, AppColors.success, AppColors.roleAccountant,
  ];

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':    return AppColors.success;
      case 'overdue':   return AppColors.error;
      case 'completed': return AppColors.primary;
      default:          return AppColors.textSecondary;
    }
  }

  String _fmtDate(String d) {
    try {
      final dt   = DateTime.parse(d);
      final now  = DateTime.now();
      final diff = dt.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff == 0)  return 'Today';
      if (diff == 1)  return 'Tomorrow';
      if (diff == -1) return 'Yesterday';
      if (diff < 0)   return '${-diff} days ago';
      if (diff < 7)   return 'In $diff days';
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month-1]}, ${dt.year}';
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherAssignmentsProvider(_filter));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assignments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(teacherAssignmentsProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final f   = _filters[i];
                    final sel = f == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.roleTeacher : AppColors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? AppColors.roleTeacher : Colors.white.withOpacity(0.07)),
                        ),
                        child: Text(f, style: TextStyle(
                            fontSize: 12, color: sel ? Colors.white : AppColors.textSecondary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: List.generate(5, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerCard(height: 100),
                  )),
                ),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load assignments', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(teacherAssignmentsProvider),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (d) {
                  final assignments = (d['data'] as List?) ?? [];
                  if (assignments.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.assignment_outlined, color: AppColors.textHint, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'All' ? 'No assignments yet' : 'No $_filter assignments',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ]),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.roleTeacher,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () async => ref.invalidate(teacherAssignmentsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: assignments.length,
                      itemBuilder: (_, i) {
                        final a       = assignments[i] as Map;
                        final title   = a['title']?.toString() ?? 'Assignment';
                        final subject = a['subject_name']?.toString() ?? a['subject']?.toString() ?? '';
                        final cls     = a['class_name']?.toString() ?? a['class']?.toString() ?? '';
                        final due     = a['due_date']?.toString() ?? '';
                        final status  = a['status']?.toString() ?? 'active';
                        final color   = _colors[i % _colors.length];
                        final sColor  = _statusColor(status);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(width: 4, height: 80,
                                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(title,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                                        StatusBadge(label: status[0].toUpperCase() + status.substring(1), color: sColor),
                                      ]),
                                      const SizedBox(height: 6),
                                      if (subject.isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.book_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(subject, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                                        ]),
                                      if (cls.isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(cls, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ]),
                                      if (due.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.schedule_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text('Due: ${_fmtDate(due)}',
                                              style: TextStyle(fontSize: 11,
                                                  color: status.toLowerCase() == 'overdue' ? AppColors.error : AppColors.textHint)),
                                        ]),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05, end: 0);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
