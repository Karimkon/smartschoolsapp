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

// ── Screen ─────────────────────────────────────────────────────────────────────

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
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
      case 'active':    return AppColors.success;
      case 'on_leave':
      case 'on leave':  return AppColors.warning;
      default:          return AppColors.error;
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
          loading: () => const Text('Teachers', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          error: (_, __) => const Text('Teachers', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          data: (d) {
            final total = (d['total'] as int?) ?? (d['data'] as List?)?.length ?? 0;
            return Row(children: [
              const Text('Teachers', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.roleTeacher.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total', style: const TextStyle(color: AppColors.roleTeacher, fontSize: 12, fontWeight: FontWeight.w700)),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AppSearchField(
                hint: 'Search by name or subject...',
                controller: _searchCtrl,
                onChanged: _onSearch,
              ).animate().fadeIn(duration: 300.ms),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: List.generate(6, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerCard(height: 82),
                  )),
                ),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load teachers', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(teachersProvider),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (d) {
                  final teachers = (d['data'] as List?) ?? (d['teachers'] as List?) ?? [];
                  if (teachers.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.person_off_rounded, color: AppColors.textHint, size: 52),
                        const SizedBox(height: 12),
                        Text(_query.isEmpty ? 'No teachers found' : 'No results for "$_query"',
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
                            : name.isNotEmpty ? name[0].toUpperCase() : 'T';
                        final subject  = t['subject_name']?.toString() ?? t['subject']?.toString() ?? '';
                        final dept     = t['department']?.toString() ?? '';
                        final phone    = t['phone']?.toString() ?? '';
                        final email    = t['email']?.toString() ?? '';
                        final status   = t['status']?.toString() ?? 'active';
                        final photo    = t['photo']?.toString() ?? t['avatar']?.toString();
                        final photoUrl = photo != null && photo.isNotEmpty
                            ? (photo.startsWith('http') ? photo : 'https://smartschoolshub.com/storage/$photo')
                            : null;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                AvatarWidget(imageUrl: photoUrl, initials: initials, color: _color(i), size: 52),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(child: Text(name.isNotEmpty ? name : 'Teacher',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                                        StatusBadge(label: _statusLabel(status), color: _statusColor(status)),
                                      ]),
                                      const SizedBox(height: 4),
                                      if (subject.isNotEmpty)
                                        Text(subject, style: const TextStyle(fontSize: 12, color: AppColors.roleTeacher, fontWeight: FontWeight.w600)),
                                      if (dept.isNotEmpty)
                                        Text(dept, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 6),
                                      if (phone.isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.phone_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                        ]),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideY(begin: 0.05, end: 0);
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
