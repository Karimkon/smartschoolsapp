import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final leaveProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, queryString) async {
  final res = await ApiService().get('/leave$queryString');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

Color _leaveTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'sick':      return AppColors.error;
    case 'annual':    return AppColors.primary;
    case 'emergency': return AppColors.warning;
    case 'maternity':
    case 'paternity': return AppColors.accent;
    default:          return AppColors.textSecondary;
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved': return AppColors.success;
    case 'rejected': return AppColors.error;
    default:         return AppColors.warning;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminLeaveScreen extends ConsumerStatefulWidget {
  const AdminLeaveScreen({super.key});
  @override ConsumerState<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends ConsumerState<AdminLeaveScreen> {
  String _filter = 'All';

  String get _query =>
      _filter == 'All' ? '' : '?status=${_filter.toLowerCase()}';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaveProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Leave Management',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(leaveProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Summary counts
          async.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (data) {
              final counts = data['counts'] as Map? ?? {};
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Expanded(child: _CountCard('Pending',  (counts['pending'] ?? 0).toString(), AppColors.warning, 0)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountCard('Approved', (counts['approved'] ?? 0).toString(), AppColors.success, 1)),
                  const SizedBox(width: 8),
                  Expanded(child: _CountCard('Rejected', (counts['rejected'] ?? 0).toString(), AppColors.error, 2)),
                ]),
              );
            },
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 34,
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
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(f, style: TextStyle(
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
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 90)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load leave requests',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(leaveProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (data) {
                final requests = (data['data'] as Map?)?['data'] as List? ?? (data['data'] as List? ?? []);
                if (requests.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.event_available_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No leave requests', style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface1,
                  onRefresh: () => ref.refresh(leaveProvider(_query).future),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: requests.length,
                    itemBuilder: (_, i) {
                      final r         = requests[i] as Map;
                      final staffName = r['staff_name']?.toString() ?? '';
                      final leaveType = r['leave_type']?.toString() ?? 'Personal';
                      final category  = r['leave_category_name']?.toString() ?? leaveType;
                      final startDate = r['start_date']?.toString() ?? '';
                      final endDate   = r['end_date']?.toString() ?? '';
                      final reason    = r['reason']?.toString() ?? '';
                      final status    = r['status']?.toString() ?? 'pending';
                      final typeColor = _leaveTypeColor(leaveType);
                      final statColor = _statusColor(status);

                      final initials = staffName.trim().split(' ')
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
                              AvatarWidget(initials: initials.isEmpty ? '?' : initials,
                                  color: typeColor, size: 40),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(staffName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  StatusBadge(label: category, color: typeColor),
                                  const SizedBox(width: 6),
                                  Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text('$startDate – $endDate',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ]),
                              ])),
                              StatusBadge(
                                  label: status[0].toUpperCase() + status.substring(1),
                                  color: statColor),
                            ]),
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: AppColors.surface2,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Text(reason,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            if (status.toLowerCase() == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10)),
                                      child: const Center(child: Text('Approve',
                                          style: TextStyle(color: AppColors.success,
                                              fontSize: 12, fontWeight: FontWeight.w700))),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                          color: AppColors.error.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(10)),
                                      child: const Center(child: Text('Reject',
                                          style: TextStyle(color: AppColors.error,
                                              fontSize: 12, fontWeight: FontWeight.w700))),
                                    ),
                                  ),
                                ),
                              ]),
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

// ── Count Card ────────────────────────────────────────────────────────────────

class _CountCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final int index;
  const _CountCard(this.label, this.value, this.color, this.index);

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  ).animate(delay: Duration(milliseconds: index * 80)).fadeIn();
}
