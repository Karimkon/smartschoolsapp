import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Model ──────────────────────────────────────────────────────────────────────
class StudentModel {
  final int    id;
  final String firstName, lastName;
  final String admissionNumber, status;
  final String? className, sectionName, photo, studentType, guardianName, guardianPhone, gender;

  StudentModel.fromJson(Map<String, dynamic> j)
      : id              = j['id'] as int,
        firstName       = (j['first_name']       ?? '').toString(),
        lastName        = (j['last_name']        ?? '').toString(),
        admissionNumber = (j['admission_number'] ?? '').toString(),
        status          = (j['status']           ?? 'active').toString(),
        className       = j['class_name']?.toString(),
        sectionName     = j['section_name']?.toString(),
        photo           = j['photo']?.toString(),
        studentType     = j['student_type']?.toString(),
        guardianName    = j['guardian_name']?.toString(),
        guardianPhone   = j['guardian_phone']?.toString(),
        gender          = j['gender']?.toString();

  String get name => '$firstName $lastName'.trim();
  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final studentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, queryString) async {
  final res = await ApiService().get('/students$queryString');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});
  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _search = '';
  Timer? _debounce;

  String get _queryString {
    final params = <String>[];
    if (_search.isNotEmpty) params.add('search=${Uri.encodeComponent(_search)}');
    if (_filter != 'all')   params.add('status=$_filter');
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _search = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Color _avatarColor(int i) => const [
    AppColors.primary, AppColors.accent, AppColors.roleTeacher,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ][i % 6];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentsProvider(_queryString));

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
          data: (data) {
            final total = (data['total'] ?? (data['data'] as List?)?.length ?? 0) as num;
            return Row(children: [
              const Text('Students',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${total.toInt()}',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
          orElse: () => const Text('Students',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.refresh(studentsProvider(_queryString)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Search + Filter ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search by name, admission no...',
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final item in [('All', 'all'), ('Active', 'active'), ('Inactive', 'inactive')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = item.$2),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == item.$2 ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _filter == item.$2
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.07)),
                              ),
                              child: Text(
                                item.$1,
                                style: TextStyle(
                                  color: _filter == item.$2 ? Colors.white : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: _filter == item.$2 ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),
            ),

            // ── Results ──────────────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                      const SizedBox(height: 12),
                      Text('Could not load students',
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => ref.refresh(studentsProvider(_queryString)),
                          child: const Text('Retry')),
                    ]),
                  ),
                ),
                data: (data) {
                  final students = (data['data'] as List)
                      .map((j) => StudentModel.fromJson(j as Map<String, dynamic>))
                      .toList();
                  final total = (data['total'] ?? students.length) as num;

                  if (students.isEmpty) {
                    return const Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off_rounded, color: AppColors.textHint, size: 52),
                        SizedBox(height: 12),
                        Text('No students found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ]),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${total.toInt()} student${total != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface1,
                          onRefresh: () =>
                              ref.refresh(studentsProvider(_queryString).future),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final s = students[i];
                              final isActive = s.status.toLowerCase() == 'active';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  onTap: () => context.push('/admin/students/${s.id}'),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      AvatarWidget(
                                          initials: s.initials,
                                          color: _avatarColor(i),
                                          size: 48),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                            const SizedBox(height: 3),
                                            Row(children: [
                                                const Icon(Icons.badge_rounded, size: 12, color: AppColors.textHint),
                                                const SizedBox(width: 4),
                                                Text(s.admissionNumber, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                if (s.className != null && s.className!.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint),
                                                  const SizedBox(width: 4),
                                                  Flexible(child: Text(s.className!, overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                                                ],
                                            ]),
                                            if (s.sectionName != null && s.sectionName!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(children: [
                                                const Icon(Icons.groups_rounded, size: 12, color: AppColors.textHint),
                                                const SizedBox(width: 4),
                                                Text(s.sectionName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ]),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        StatusBadge(
                                          label: isActive ? 'Active' : 'Inactive',
                                          color: isActive ? AppColors.success : AppColors.error,
                                        ),
                                        if (s.studentType != null && s.studentType!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          StatusBadge(
                                            label: s.studentType![0].toUpperCase() + s.studentType!.substring(1),
                                            color: s.studentType!.toLowerCase() == 'boarding' ? AppColors.accent : AppColors.roleTeacher,
                                          ),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                              ).animate(delay: Duration(milliseconds: i * 30))
                                  .fadeIn()
                                  .slideX(begin: 0.05, end: 0);
                            },
                          ),
                        ),
                      ),
                    ],
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
