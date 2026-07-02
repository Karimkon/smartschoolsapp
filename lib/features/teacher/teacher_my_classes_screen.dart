import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

final teacherAssignmentsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/teacher/assignments');
  return Map<String, dynamic>.from(res.data as Map);
});

class TeacherMyClassesScreen extends ConsumerWidget {
  const TeacherMyClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.roleTeacher,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () async => ref.invalidate(teacherAssignmentsProvider),
                  child: async.when(
                    loading: () => _loading(),
                    error:   (e, _) => _error(ref, e),
                    data:    (d) => _buildContent(d),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        const Expanded(
          child: Text('My Classes & Subjects',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
      ],
    ),
  );

  Widget _loading() => ListView(
    padding: const EdgeInsets.all(20),
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ShimmerCard(height: 90),
    )),
  );

  Widget _error(WidgetRef ref, Object e) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load assignments', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(teacherAssignmentsProvider),
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildContent(Map<String, dynamic> d) {
    final isClassTeacher = d['is_class_teacher'] == true;
    final assignments    = (d['assignments'] as List?) ?? [];
    final ctAssignments  = (d['class_teacher_assignments'] as List?) ?? [];

    if (assignments.isEmpty && ctAssignments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined, color: AppColors.textHint, size: 64),
              const SizedBox(height: 16),
              const Text('No Subject Assignments Yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Ask your admin to assign you to classes and subjects from your teacher profile.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    // Group subject assignments by class_name
    final byClass = <String, List<Map>>{};
    for (final a in assignments) {
      final map = Map<String, dynamic>.from(a as Map);
      final cls = map['class_name']?.toString() ?? 'Unknown';
      byClass.putIfAbsent(cls, () => []).add(map);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Class teacher badge
        if (isClassTeacher) ...[
          _ClassTeacherBanner(ctAssignments: ctAssignments)
              .animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          const SizedBox(height: 16),
        ],

        // Subject assignments grouped by class
        if (byClass.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Subject Assignments',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 0.5)),
          ),
          ...byClass.entries.toList().asMap().entries.map((e) {
            final idx   = e.key;
            final entry = e.value;
            return _ClassCard(className: entry.key, subjects: entry.value)
                .animate(delay: Duration(milliseconds: 100 + idx * 60))
                .fadeIn().slideY(begin: 0.1, end: 0);
          }),
        ],
      ],
    );
  }
}

class _ClassTeacherBanner extends StatelessWidget {
  final List ctAssignments;
  const _ClassTeacherBanner({required this.ctAssignments});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success.withOpacity(0.2), AppColors.primary.withOpacity(0.15)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class Teacher', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text('You can generate report cards for your class',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          if (ctAssignments.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...ctAssignments.take(3).map((a) {
              final map = Map<String, dynamic>.from(a as Map);
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.class_rounded, color: AppColors.success, size: 14),
                    const SizedBox(width: 8),
                    Text(map['class_name']?.toString() ?? '',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Text(map['session_year_name']?.toString() ?? '',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String className;
  final List<Map> subjects;
  const _ClassCard({required this.className, required this.subjects});

  static const _roleColors = {
    'main_teacher': Color(0xFF2FA876),
    'co_teacher':   Color(0xFF6366F1),
    'assistant':    Color(0xFFF59E0B),
    'substitute':   Color(0xFF9BA8B5),
  };

  static const _roleLabels = {
    'main_teacher': 'Main',
    'co_teacher':   'Co-Teacher',
    'assistant':    'Assistant',
    'substitute':   'Substitute',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface3),
      ),
      child: Column(
        children: [
          // Class header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.roleTeacher.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.roleTeacher.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.class_rounded, color: AppColors.roleTeacher, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(className,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                StatusBadge(
                  label: '${subjects.length} subject${subjects.length != 1 ? "s" : ""}',
                  color: AppColors.roleTeacher,
                ),
              ],
            ),
          ),
          // Subjects list
          ...subjects.asMap().entries.map((e) {
            final sub   = e.value;
            final role  = sub['role_type']?.toString() ?? 'main_teacher';
            final color = _roleColors[role] ?? AppColors.textHint;
            final label = _roleLabels[role] ?? role;
            final topic = sub['topic_coverage']?.toString() ?? '';
            final isLast = e.key == subjects.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: AppColors.surface3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4, height: topic.isNotEmpty ? 42 : 32,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sub['subject_name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        if (topic.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('Topic: $topic',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(label: label, color: color),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
