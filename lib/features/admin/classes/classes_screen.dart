import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Model ──────────────────────────────────────────────────────────────────────

class ClassModel {
  final int    id;
  final String name;
  final String? teacherName, room, section;
  final int    studentCount, capacity;

  ClassModel.fromJson(Map<String, dynamic> j)
      : id           = j['id'] as int,
        name         = (j['name'] ?? '').toString(),
        teacherName  = j['teacher_name']?.toString()?.trim().isEmpty == true
            ? null
            : j['teacher_name']?.toString().trim(),
        room         = j['room']?.toString(),
        section      = j['section']?.toString(),
        studentCount = toI(j['student_count'], 0),
        capacity     = toI(j['capacity'], 40);
}

// ── Provider ───────────────────────────────────────────────────────────────────

final classesProvider = FutureProvider.autoDispose<List<ClassModel>>((ref) async {
  final res = await ApiService().get('/classes');
  final list = res.data as List;
  return list.map((j) => ClassModel.fromJson(j as Map<String, dynamic>)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class ClassesScreen extends ConsumerStatefulWidget {
  const ClassesScreen({super.key});
  @override
  ConsumerState<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends ConsumerState<ClassesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClassModel> _filtered(List<ClassModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((c) =>
        c.name.toLowerCase().contains(q) ||
        (c.teacherName?.toLowerCase().contains(q) ?? false)).toList();
  }

  Color _cardColor(int i) => const [
    AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.success,
    AppColors.warning, AppColors.roleParent,
  ][i % 6];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(classesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: async.maybeWhen(
          data: (classes) => Row(children: [
            const Text('Classes',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('${classes.length}',
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          orElse: () => const Text('Classes',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(classesProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: AppSearchField(
              hint: 'Search class or teacher...',
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Content
          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 90)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load classes',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => ref.invalidate(classesProvider),
                        child: const Text('Retry')),
                  ]),
                ),
              ),
              data: (all) {
                final classes = _filtered(all);
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () => ref.refresh(classesProvider.future),
                  child: classes.isEmpty
                      ? const Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.search_off_rounded, color: AppColors.textHint, size: 52),
                            SizedBox(height: 12),
                            Text('No classes found',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ]),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: classes.length,
                          itemBuilder: (ctx, i) {
                            final c     = classes[i];
                            final color = _cardColor(i);
                            final pct   = c.capacity > 0
                                ? (c.studentCount / c.capacity).clamp(0.0, 1.0)
                                : 0.0;
                            final pctInt = (pct * 100).round();

                            // Abbreviate class name for the icon box
                            final abbrev = c.name.length > 5
                                ? c.name.substring(0, 4)
                                : c.name;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(14)),
                                    child: Center(
                                      child: Text(abbrev,
                                          style: TextStyle(
                                              color: color,
                                              fontSize: abbrev.length > 3 ? 11 : 14,
                                              fontWeight: FontWeight.w800),
                                          textAlign: TextAlign.center),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(c.name,
                                          style: const TextStyle(
                                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                      const SizedBox(height: 3),
                                      if (c.teacherName != null)
                                        Text(c.teacherName!,
                                            style: TextStyle(
                                                fontSize: 12, color: color, fontWeight: FontWeight.w600),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)
                                      else
                                        const Text('No teacher assigned',
                                            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.people_rounded, size: 12, color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text('${c.studentCount}/${c.capacity} students',
                                            style: const TextStyle(
                                                fontSize: 11, color: AppColors.textSecondary)),
                                        if (c.room != null && c.room!.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          const Icon(Icons.room_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 3),
                                          Text(c.room!,
                                              style: const TextStyle(
                                                  fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ]),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: pct,
                                          backgroundColor: AppColors.surface3,
                                          valueColor: AlwaysStoppedAnimation(
                                              pctInt > 90 ? AppColors.warning : AppColors.success),
                                          minHeight: 4,
                                        ),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Text('$pctInt%',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12, fontWeight: FontWeight.w700)),
                                  ),
                                ]),
                              ),
                            ).animate(delay: Duration(milliseconds: i * 50))
                                .fadeIn().slideX(begin: 0.05, end: 0);
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
