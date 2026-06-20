import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final teachersProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/teachers', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _teacherTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'theology': return const Color(0xFF7C3AED);
    case 'both':     return const Color(0xFF2563EB);
    default:         return AppColors.success;
  }
}

String _teacherTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'theology': return 'Theology';
    case 'both':     return 'Both';
    default:         return 'Secular';
  }
}

IconData _teacherTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'theology': return Icons.mosque_rounded;
    case 'both':     return Icons.auto_awesome_rounded;
    default:         return Icons.school_rounded;
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _typeFilter = 'all'; // all / secular / theology / both
  Timer? _debounce;

  static const _avatarColors = [
    AppColors.roleTeacher, AppColors.primary, AppColors.accent,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ];

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

  Color _color(int i) => _avatarColors[i % _avatarColors.length];

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':              return AppColors.success;
      case 'on_leave':
      case 'on leave':            return AppColors.warning;
      default:                    return AppColors.error;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'active':   return 'Active';
      case 'on_leave': return 'On Leave';
      case 'inactive': return 'Inactive';
      default:         return s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teachersProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: async.when(
          loading: () => const Text('Employees',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          error: (_, __) => const Text('Employees',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          data: (d) {
            final total = (d['total'] as int?) ?? (d['data'] as List?)?.length ?? 0;
            return Row(children: [
              const Text('Employees',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.roleTeacher.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total',
                    style: const TextStyle(
                        color: AppColors.roleTeacher, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(teachersProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: AppSearchField(
                hint: 'Search by name or subject...',
                controller: _searchCtrl,
                onChanged: _onSearch,
              ).animate().fadeIn(duration: 300.ms),
            ),

            // Teacher type filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'secular', 'theology', 'both'].map((t) {
                    final sel = _typeFilter == t;
                    final col = t == 'all'
                        ? AppColors.textSecondary
                        : _teacherTypeColor(t);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _typeFilter = t),
                        child: AnimatedContainer(
                          duration: 180.ms,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? col.withOpacity(0.18) : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? col : Colors.white.withOpacity(0.07),
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (t != 'all') ...[
                              Icon(_teacherTypeIcon(t), size: 13, color: sel ? col : AppColors.textHint),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              t == 'all' ? 'All Types' : _teacherTypeLabel(t),
                              style: TextStyle(
                                color: sel ? col : AppColors.textSecondary,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(duration: 350.ms),
            ),

            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: List.generate(6, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerCard(height: 90),
                  )),
                ),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load employees',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(teachersProvider),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (d) {
                  var teachers = (d['data'] as List?) ?? (d['teachers'] as List?) ?? [];

                  // Client-side filter by teacher_type
                  if (_typeFilter != 'all') {
                    teachers = teachers.where((t) {
                      final tt = (t['teacher_type'] ?? 'secular').toString().toLowerCase();
                      return tt == _typeFilter;
                    }).toList();
                  }

                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.person_off_rounded, color: AppColors.textHint, size: 52),
                        const SizedBox(height: 12),
                        Text(_query.isEmpty ? 'No employees found' : 'No results for "$_query"',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ]),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.roleTeacher,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () async => ref.invalidate(teachersProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: teachers.length,
                      itemBuilder: (context, i) {
                        final t        = teachers[i] as Map;
                        final first    = t['first_name']?.toString() ?? '';
                        final last     = t['last_name']?.toString() ?? '';
                        final name     = '$first $last'.trim();
                        final parts    = name.split(' ').where((p) => p.isNotEmpty).toList();
                        final initials = parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : name.isNotEmpty ? name[0].toUpperCase() : 'E';
                        final subject      = t['subject_name']?.toString() ?? t['subject']?.toString() ?? '';
                        final dept         = t['department']?.toString() ?? '';
                        final phone        = t['phone']?.toString() ?? '';
                        final status       = t['status']?.toString() ?? 'active';
                        final photo        = t['photo']?.toString() ?? t['avatar']?.toString();
                        final teacherType  = t['teacher_type']?.toString() ?? 'secular';
                        final hasLogin     = t['user_id'] != null;
                        final accountStatus = t['account_status']?.toString() ?? '';
                        final isAccountActive = hasLogin &&
                            (accountStatus.isEmpty || accountStatus == 'active');

                        final photoUrl = photo != null && photo.isNotEmpty
                            ? (photo.startsWith('http')
                                ? photo
                                : 'https://smartschoolshub.com/storage/$photo')
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                AvatarWidget(
                                    imageUrl: photoUrl,
                                    initials: initials,
                                    color: _color(i),
                                    size: 50),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Name + status
                                      Row(children: [
                                        Expanded(
                                          child: Text(
                                            name.isNotEmpty ? name : 'Employee',
                                            style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary),
                                          ),
                                        ),
                                        StatusBadge(
                                          label: _statusLabel(status),
                                          color: _statusColor(status),
                                        ),
                                      ]),
                                      const SizedBox(height: 4),

                                      // Subject
                                      if (subject.isNotEmpty)
                                        Text(subject,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.roleTeacher,
                                                fontWeight: FontWeight.w600)),
                                      if (dept.isNotEmpty)
                                        Text(dept,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary)),
                                      const SizedBox(height: 6),

                                      // Teacher type + login badges row
                                      Row(children: [
                                        // Teacher type badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _teacherTypeColor(teacherType)
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            Icon(_teacherTypeIcon(teacherType),
                                                size: 10,
                                                color: _teacherTypeColor(teacherType)),
                                            const SizedBox(width: 3),
                                            Text(_teacherTypeLabel(teacherType),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: _teacherTypeColor(teacherType))),
                                          ]),
                                        ),
                                        const SizedBox(width: 6),

                                        // Login account badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isAccountActive
                                                ? AppColors.success.withOpacity(0.15)
                                                : AppColors.textHint.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                                            Icon(
                                              isAccountActive
                                                  ? Icons.verified_user_rounded
                                                  : Icons.no_accounts_rounded,
                                              size: 10,
                                              color: isAccountActive
                                                  ? AppColors.success
                                                  : AppColors.textHint,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              isAccountActive ? 'Login: Active' : 'No Login',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isAccountActive
                                                      ? AppColors.success
                                                      : AppColors.textHint),
                                            ),
                                          ]),
                                        ),

                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.phone_rounded,
                                              size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 3),
                                          Text(phone,
                                              style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: AppColors.textHint)),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40))
                            .fadeIn()
                            .slideY(begin: 0.05, end: 0);
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
