import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final staffProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/staff', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _dept = 'All';
  Timer? _debounce;

  static const _avatarColors = [
    AppColors.roleAccountant, AppColors.primary, AppColors.accent,
    AppColors.warning, AppColors.roleTeacher, AppColors.success,
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

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  List<dynamic> _filterByDept(List<dynamic> staff) {
    if (_dept == 'All') return staff;
    return staff.where((s) {
      final dept = (s['department'] ?? '').toString();
      return dept.toLowerCase() == _dept.toLowerCase();
    }).toList();
  }

  List<String> _getDepartments(List<dynamic> staff) {
    final depts = staff
        .map((s) => (s['department'] ?? '').toString())
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...depts];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(staffProvider(_query));

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
            final allStaff = List<dynamic>.from(data['data'] ?? data['staff'] ?? []);
            return Row(children: [
              const Text('Staff', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.roleAccountant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${allStaff.length}',
                    style: const TextStyle(color: AppColors.roleAccountant, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
          orElse: () => const Text('Staff', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => _buildShimmer(),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load staff', style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(staffProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (data) {
            final allStaff = List<dynamic>.from(data['data'] ?? data['staff'] ?? []);
            final depts = _getDepartments(allStaff);
            final staff = _filterByDept(allStaff);

            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(children: [
                  AppSearchField(
                    hint: 'Search staff by name or role...',
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ).animate().fadeIn(),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: depts.map((d) {
                        final sel = d == _dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _dept = d),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.roleAccountant : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel ? AppColors.roleAccountant : Colors.white.withOpacity(0.07),
                                ),
                              ),
                              child: Text(d,
                                  style: TextStyle(
                                    color: sel ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                  )),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ]),
              ),
              Expanded(
                child: staff.isEmpty
                    ? const Center(
                        child: Text('No staff found',
                            style: TextStyle(color: AppColors.textSecondary)))
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(staffProvider),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          itemCount: staff.length,
                          itemBuilder: (ctx, i) {
                            final s = staff[i];
                            final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
                            final role = s['role'] ?? s['job_title'] ?? 'Staff';
                            final dept = s['department'] ?? '—';
                            final phone = s['phone'] ?? '—';
                            final status = s['status'] ?? 'active';
                            final statusLabel = status.toString()[0].toUpperCase() +
                                status.toString().substring(1).replaceAll('_', ' ');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  AvatarWidget(
                                    initials: _initials(name),
                                    color: _color(i),
                                    size: 50,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                            child: Text(name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                          ),
                                          StatusBadge(
                                              label: statusLabel,
                                              color: _statusColor(status)),
                                        ]),
                                        const SizedBox(height: 3),
                                        Text(role,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: _color(i),
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 3),
                                        Row(children: [
                                          const Icon(Icons.domain_rounded,
                                              size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(dept,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary)),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.phone_rounded,
                                              size: 11, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(phone,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            ).animate(delay: Duration(milliseconds: i * 50))
                                .fadeIn()
                                .slideX(begin: 0.05, end: 0);
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 80),
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ShimmerBox(height: 72, borderRadius: 14),
      ),
    );
  }
}
