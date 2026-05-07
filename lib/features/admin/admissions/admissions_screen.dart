import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final admissionsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/admissions$query');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const _filters = ['All', 'new', 'contacted', 'admitted', 'rejected'];
const _filterLabels = ['All', 'New', 'Contacted', 'Admitted', 'Rejected'];

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'admitted':  return AppColors.success;
    case 'contacted': return AppColors.primary;
    case 'rejected':  return AppColors.error;
    default:          return AppColors.warning; // new / pending
  }
}

const _palette = [
  AppColors.primary, AppColors.accent, AppColors.roleTeacher,
  AppColors.roleParent, AppColors.warning, AppColors.roleAccountant,
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAdmissionsScreen extends ConsumerStatefulWidget {
  const AdminAdmissionsScreen({super.key});
  @override ConsumerState<AdminAdmissionsScreen> createState() => _AdminAdmissionsScreenState();
}

class _AdminAdmissionsScreenState extends ConsumerState<AdminAdmissionsScreen> {
  int _filterIndex = 0;

  String get _query =>
      _filterIndex == 0 ? '' : '?status=${_filters[_filterIndex]}';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(admissionsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Admissions',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(admissionsProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Counts
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final counts = data['counts'] as Map? ?? {};
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Expanded(child: _CountTile('New', (counts['new'] ?? 0).toString(), AppColors.warning, 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountTile('Contacted', (counts['contacted'] ?? 0).toString(), AppColors.primary, 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountTile('Admitted', (counts['admitted'] ?? 0).toString(), AppColors.success, 2)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountTile('Rejected', (counts['rejected'] ?? 0).toString(), AppColors.error, 3)),
                ]),
              );
            },
          ),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final sel = _filterIndex == i;
                  final color = i == 0 ? AppColors.primary : _statusColor(_filters[i]);
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? color : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? color : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(_filterLabels[i], style: TextStyle(
                          color: sel ? Colors.white : AppColors.textSecondary,
                          fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: async.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: 5,
                itemBuilder: (_, __) =>
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 100)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load admissions', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(admissionsProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (data) {
                final raw      = data['data'];
                final enquiries = (raw is Map ? raw['data'] : raw) as List? ?? [];
                if (enquiries.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.school_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No admission enquiries', style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () => ref.refresh(admissionsProvider(_query).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: enquiries.length,
                    itemBuilder: (_, i) {
                      final e          = enquiries[i] as Map;
                      final name       = e['student_name']?.toString() ?? '';
                      final parent     = e['parent_name']?.toString() ?? '';
                      final phone      = e['phone']?.toString() ?? '';
                      final classApply = e['class_applying']?.toString() ?? '';
                      final source     = e['source']?.toString() ?? '';
                      final status     = e['status']?.toString() ?? 'new';
                      final notes      = e['notes']?.toString() ?? '';
                      final created    = e['created_at']?.toString() ?? '';
                      final color      = _palette[i % _palette.length];
                      final statColor  = _statusColor(status);

                      final initials = name.trim().split(' ')
                          .where((x) => x.isNotEmpty)
                          .take(2)
                          .map((x) => x[0].toUpperCase())
                          .join();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              AvatarWidget(initials: initials.isEmpty ? '?' : initials, color: color, size: 44),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                if (classApply.isNotEmpty)
                                  Text('Applying for: $classApply',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  if (source.isNotEmpty)
                                    StatusBadge(label: source.replaceAll('_', ' ').toUpperCase(), color: color),
                                  const SizedBox(width: 6),
                                  Text(created.length > 10 ? created.substring(0, 10) : created,
                                      style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ]),
                              ])),
                              StatusBadge(label: status[0].toUpperCase() + status.substring(1), color: statColor),
                            ]),
                            if (parent.isNotEmpty || phone.isNotEmpty) ...[
                              const Divider(color: Colors.white12, height: 20),
                              Row(children: [
                                if (parent.isNotEmpty) ...[
                                  const Icon(Icons.person_rounded, size: 13, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(parent,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                                ],
                                if (phone.isNotEmpty) ...[
                                  const Icon(Icons.phone_rounded, size: 13, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ]),
                            ],
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(notes,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ]),
                        ),
                      ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05);
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

class _CountTile extends StatelessWidget {
  final String label, value;
  final Color color;
  final int index;
  const _CountTile(this.label, this.value, this.color, this.index);

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  ).animate(delay: Duration(milliseconds: index * 80)).fadeIn();
}
