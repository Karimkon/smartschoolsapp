import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final branchesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/branches');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  static const _palette = [
    AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.textHint,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Branches / Campuses',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(branchesProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (_, __) =>
                const Padding(padding: EdgeInsets.only(bottom: 14), child: ShimmerCard(height: 160)),
          ),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load branches', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => ref.invalidate(branchesProvider),
                  child: const Text('Retry')),
            ]),
          ),
          data: (data) {
            final branches = (data['data'] as List?) ?? [];
            if (branches.isEmpty) {
              return const Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.business_rounded, color: AppColors.textHint, size: 48),
                  SizedBox(height: 12),
                  Text('No branches found', style: TextStyle(color: AppColors.textHint)),
                ]),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface1,
              onRefresh: () => ref.refresh(branchesProvider.future),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: branches.length,
                itemBuilder: (ctx, i) {
                  final b       = branches[i] as Map;
                  final name    = b['name']?.toString() ?? '';
                  final address = b['address']?.toString() ?? '';
                  final phone   = b['phone']?.toString() ?? '';
                  final status  = b['status']?.toString() ?? 'active';
                  final isMain  = b['is_main'] == true || b['is_main'] == 1;
                  final students = (b['student_count'] as num?)?.toInt() ?? 0;
                  final teachers = (b['teacher_count'] as num?)?.toInt() ?? 0;
                  final color   = _palette[i % _palette.length];
                  final isActive = status.toLowerCase() == 'active';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(isMain ? Icons.account_balance_rounded : Icons.business_rounded,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary))),
                              if (isMain)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: const Text('Main', style: TextStyle(color: AppColors.primary,
                                      fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                            ]),
                            if (address.isNotEmpty)
                              Text(address,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ])),
                          StatusBadge(
                              label: isActive ? 'Active' : 'Inactive',
                              color: isActive ? AppColors.success : AppColors.textHint),
                        ]),
                        const SizedBox(height: 12),
                        if (phone.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.phone_rounded, size: 14, color: AppColors.success),
                              const SizedBox(width: 8),
                              Text(phone,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            ]),
                          ),
                        if (phone.isNotEmpty) const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [
                                Text('$students',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                        color: AppColors.primary)),
                                const Text('Students',
                                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                              ]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                  color: AppColors.roleTeacher.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Column(children: [
                                Text('$teachers',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                                        color: AppColors.roleTeacher)),
                                const Text('Teachers',
                                    style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                              ]),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
