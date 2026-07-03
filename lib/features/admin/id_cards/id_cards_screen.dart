import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _idCardStudentsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/students');
  final data = res.data as Map?;
  return (data?['data'] as List?) ?? (res.data as List? ?? []);
});

final _idCardTeachersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/teachers');
  final data = res.data as Map?;
  return (data?['data'] as List?) ?? (res.data as List? ?? []);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class IDCardsScreen extends ConsumerStatefulWidget {
  const IDCardsScreen({super.key});
  @override
  ConsumerState<IDCardsScreen> createState() => _IDCardsScreenState();
}

class _IDCardsScreenState extends ConsumerState<IDCardsScreen> {
  String _type  = 'Student';
  String _query = '';
  final Set<int> _selected   = {};
  final _searchCtrl          = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _filter(List<dynamic> items) {
    if (_query.isEmpty) return items;
    final q = _query.toLowerCase();
    return items.where((p) {
      final m = p as Map;
      final name = '${m['first_name'] ?? ''} ${m['last_name'] ?? m['name'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void _selectAll(List<dynamic> items) {
    setState(() {
      for (final p in items) {
        _selected.add((p as Map)['id'] as int);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(_idCardStudentsProvider);
    final teachersAsync = ref.watch(_idCardTeachersProvider);
    final isStudent     = _type == 'Student';
    final async         = isStudent ? studentsAsync : teachersAsync;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('ID Cards',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Generating ${_selected.length} ID card(s)...'),
                  backgroundColor: AppColors.primary,
                ));
                setState(() => _selected.clear());
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text('Print (${_selected.length})'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: List.generate(5, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerCard(height: 68),
            )),
          ),
          error: (e, _) => Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
              const SizedBox(height: 12),
              const Text('Could not load data', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(_idCardStudentsProvider);
                  ref.refresh(_idCardTeachersProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          )),
          data: (raw) {
            final items    = _filter(raw);
            final allCount = raw.length;

            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(children: [
                  // Type toggle
                  Row(children: ['Student', 'Teacher'].map((t) {
                    final sel = t == _type;
                    return Expanded(child: Padding(
                      padding: EdgeInsets.only(right: t == 'Student' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() { _type = t; _selected.clear(); _query = ''; _searchCtrl.clear(); }),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.surface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(t,
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            ),
                          )),
                        ),
                      ),
                    ));
                  }).toList()).animate().fadeIn(),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: AppSearchField(
                      hint: 'Search by name...',
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v),
                    )),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded, color: AppColors.textSecondary),
                      tooltip: 'Select all',
                      onPressed: () => _selectAll(items),
                    ),
                  ]).animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 8),
                  // Count banner
                  Row(children: [
                    Text('$allCount ${_type.toLowerCase()}s total',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                    const Spacer(),
                    if (_selected.isNotEmpty)
                      Text('${_selected.length} selected',
                          style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_rounded, color: AppColors.textHint, size: 52),
                          SizedBox(height: 12),
                          Text('No results', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ))
                    : RefreshIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface1,
                        onRefresh: () async {
                          ref.refresh(_idCardStudentsProvider);
                          ref.refresh(_idCardTeachersProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) {
                            final p        = items[i] as Map;
                            final id       = toI(p['id']);
                            final selected = _selected.contains(id);

                            final name = isStudent
                                ? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'.trim()
                                : '${p['first_name'] ?? p['name'] ?? ''} ${p['last_name'] ?? ''}'.trim();

                            final sub1 = isStudent
                                ? p['admission_number']?.toString() ?? '—'
                                : p['employee_id']?.toString() ?? p['admission_number']?.toString() ?? '—';
                            final sub2 = isStudent
                                ? p['class_name']?.toString() ?? p['class']?.toString() ?? '—'
                                : p['department']?.toString() ?? p['designation']?.toString() ?? '—';

                            final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
                            final colors   = [
                              AppColors.primary,
                              AppColors.roleTeacher,
                              AppColors.accent,
                              AppColors.success,
                              AppColors.roleParent,
                            ];
                            final avatarColor = colors[i % colors.length];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  selected ? _selected.remove(id) : _selected.add(id);
                                }),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(12),
                                  color: selected ? AppColors.primary.withOpacity(0.12) : null,
                                  child: Row(children: [
                                    // Checkbox
                                    AnimatedContainer(
                                      duration: 200.ms,
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: selected ? AppColors.primary : Colors.transparent,
                                        border: Border.all(
                                          color: selected ? AppColors.primary : AppColors.textHint,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: selected
                                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    AvatarWidget(initials: initials, color: avatarColor, size: 42),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          Text(sub1, style: const TextStyle(
                                              fontSize: 11, color: AppColors.textSecondary)),
                                          if (sub2.isNotEmpty && sub2 != '—') ...[
                                            const SizedBox(width: 8),
                                            const Text('·', style: TextStyle(color: AppColors.textHint)),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text(sub2, style: const TextStyle(
                                                fontSize: 11, color: AppColors.textSecondary),
                                              overflow: TextOverflow.ellipsis,
                                            )),
                                          ],
                                        ]),
                                      ],
                                    )),
                                    const Icon(Icons.badge_rounded,
                                        color: AppColors.textHint, size: 18),
                                  ]),
                                ),
                              ),
                            ).animate(delay: Duration(milliseconds: i * 30)).fadeIn().slideX(begin: 0.04, end: 0);
                          },
                        ),
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
