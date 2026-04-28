import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final parentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/parents', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class ParentsScreen extends ConsumerStatefulWidget {
  const ParentsScreen({super.key});
  @override
  ConsumerState<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends ConsumerState<ParentsScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _colors = [AppColors.roleParent, AppColors.primary, AppColors.accent, AppColors.roleTeacher, AppColors.success, AppColors.warning];

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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(parentsProvider(_query));

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
          loading: () => const Text('Parents', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          error: (_, __) => const Text('Parents', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          data: (d) {
            final total = (d['total'] as int?) ?? (d['data'] as List?)?.length ?? 0;
            return Row(children: [
              const Text('Parents', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.roleParent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('$total', style: const TextStyle(color: AppColors.roleParent, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(parentsProvider),
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
                hint: 'Search by name or phone...',
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
                    const Text('Could not load parents', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(parentsProvider),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (d) {
                  final parents = (d['data'] as List?) ?? (d['parents'] as List?) ?? [];
                  if (parents.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.people_outline_rounded, color: AppColors.textHint, size: 64),
                        const SizedBox(height: 16),
                        Text(_query.isEmpty ? 'No parents found' : 'No results for "$_query"',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ]),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.roleParent,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () async => ref.invalidate(parentsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: parents.length,
                      itemBuilder: (context, i) {
                        final p    = parents[i] as Map;
                        final name = '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim();
                        if (name.isEmpty) return const SizedBox();
                        final parts    = name.split(' ').where((s) => s.isNotEmpty).toList();
                        final initials = parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : name[0].toUpperCase();
                        final phone    = p['phone']?.toString() ?? '';
                        final email    = p['email']?.toString() ?? '';
                        final relation = p['relationship']?.toString() ?? p['relation']?.toString() ?? '';
                        final children = (p['children'] as List?) ?? [];
                        final color    = _colors[i % _colors.length];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                AvatarWidget(initials: initials, color: color, size: 48),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                      const SizedBox(height: 3),
                                      if (relation.isNotEmpty)
                                        Text(relation, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                      if (phone.isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.phone_rounded, size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 3),
                                          Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                        ]),
                                      if (email.isNotEmpty)
                                        Row(children: [
                                          const Icon(Icons.email_rounded, size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 3),
                                          Expanded(child: Text(email, style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ]),
                                      if (children.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          const Icon(Icons.child_care_rounded, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              children.map((c) => (c as Map)['name']?.toString() ??
                                                  '${(c)['first_name'] ?? ''} ${(c)['last_name'] ?? ''}'.trim()).join(', '),
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              maxLines: 1, overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ]),
                                      ],
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
