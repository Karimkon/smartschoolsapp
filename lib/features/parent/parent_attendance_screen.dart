import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import 'parent_fees_screen.dart' show parentChildrenProvider;
import 'package:smartschools/core/utils/safe_num.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final parentAttendanceProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, childId) async {
  final res = await ApiService().get('/parent/children/$childId/attendance');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ParentAttendanceScreen extends ConsumerStatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  ConsumerState<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends ConsumerState<ParentAttendanceScreen> {
  int? _selectedChildId;

  Color _attColor(int pct) {
    if (pct >= 85) return AppColors.success;
    if (pct >= 70) return AppColors.warning;
    return AppColors.error;
  }

  String _attLabel(int pct) {
    if (pct >= 90) return 'Excellent';
    if (pct >= 75) return 'Good';
    if (pct >= 60) return 'Below Average';
    return 'Critical';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'present': return AppColors.success;
      case 'absent':  return AppColors.error;
      case 'late':    return AppColors.warning;
      default:        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(parentChildrenProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Text('Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              ]),
            ),
            childrenAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(16), child: ShimmerCard(height: 48)),
              error: (_, __) => const SizedBox(),
              data: (children) {
                if (_selectedChildId == null && children.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedChildId = children.first['id'] as int);
                  });
                }
                if (children.length <= 1) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: children.map((c) {
                        final cid  = c['id'] as int;
                        final name = '${c['first_name']} ${c['last_name']}'.trim();
                        final sel  = _selectedChildId == cid;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedChildId = cid),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(name, style: TextStyle(
                                color: sel ? Colors.white : AppColors.textSecondary,
                                fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: _selectedChildId == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _buildContent(_selectedChildId!),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildContent(int childId) {
    final attAsync = ref.watch(parentAttendanceProvider(childId));

    return attAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load attendance', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => ref.refresh(parentAttendanceProvider(childId)), child: const Text('Retry')),
      ])),
      data: (data) {
        final summary = data['summary'] as Map? ?? {};
        final monthly = (data['monthly'] as List?) ?? [];
        final recent  = (data['recent']  as List?) ?? [];
        final pct     = toI(summary['pct'], 0);

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface1,
          onRefresh: () => ref.refresh(parentAttendanceProvider(childId).future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Overall card
              GlassCard(
                child: Row(children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _attColor(pct).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('$pct%',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _attColor(pct)))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Overall Attendance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_attLabel(pct), style: TextStyle(fontSize: 13, color: _attColor(pct), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${summary['present'] ?? 0} present / ${summary['total'] ?? 0} days',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                ]),
              ).animate().fadeIn(),

              const SizedBox(height: 16),
              const Text('Monthly Breakdown', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
              const SizedBox(height: 10),

              // Monthly breakdown
              ...monthly.asMap().entries.map((e) {
                final m       = e.value as Map;
                final i       = e.key;
                final present = toI(m['present'], 0);
                final absent  = toI(m['absent'] , 0);
                final late    = toI(m['late']   , 0);
                final total   = present + absent + late;
                final mpct    = total > 0 ? ((present / total) * 100).round() : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(m['month']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        StatusBadge(label: '$mpct%', color: _attColor(mpct)),
                      ]),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: mpct / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.surface3,
                          valueColor: AlwaysStoppedAnimation<Color>(_attColor(mpct)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        _Dot('Present', present, AppColors.success),
                        const SizedBox(width: 12),
                        _Dot('Absent', absent, AppColors.error),
                        const SizedBox(width: 12),
                        _Dot('Late', late, AppColors.warning),
                      ]),
                    ]),
                  ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(),
                );
              }),

              if (recent.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Recent Records', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                ...recent.take(10).toList().asMap().entries.map((e) {
                  final rec  = e.value as Map;
                  final i    = e.key;
                  final stat = rec['status']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: _statusColor(stat), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(rec['date']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                        StatusBadge(
                          label: stat[0].toUpperCase() + stat.substring(1),
                          color: _statusColor(stat),
                        ),
                      ]),
                    ).animate(delay: Duration(milliseconds: i * 30)).fadeIn(),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _Dot(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text('$count $label', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
  ]);
}
