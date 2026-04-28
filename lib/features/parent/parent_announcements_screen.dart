import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final parentAnnouncementsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/parent/announcements');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ParentAnnouncementsScreen extends ConsumerWidget {
  const ParentAnnouncementsScreen({super.key});

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'exam':    return Icons.assignment_rounded;
      case 'event':   return Icons.event_rounded;
      case 'fee':     return Icons.account_balance_wallet_rounded;
      case 'holiday': return Icons.beach_access_rounded;
      default:        return Icons.campaign_rounded;
    }
  }

  Color _typeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'exam':    return AppColors.roleTeacher;
      case 'event':   return AppColors.success;
      case 'fee':     return AppColors.warning;
      case 'holiday': return AppColors.accent;
      default:        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentAnnouncementsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
                const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () => ref.refresh(parentAnnouncementsProvider),
                ),
              ]),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(5, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerCard(height: 90),
                  )),
                ),
                error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                  const SizedBox(height: 12),
                  const Text('Could not load announcements', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => ref.refresh(parentAnnouncementsProvider), child: const Text('Retry')),
                ])),
                data: (data) {
                  final items = (data['data'] as List?) ?? [];
                  if (items.isEmpty) {
                    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.campaign_rounded, color: AppColors.textHint, size: 52),
                      SizedBox(height: 12),
                      Text('No announcements', style: TextStyle(color: AppColors.textSecondary)),
                    ]));
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () => ref.refresh(parentAnnouncementsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final a     = items[i] as Map;
                        final type  = a['type']?.toString();
                        final color = _typeColor(type);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_typeIcon(type), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a['title']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const SizedBox(height: 5),
                                Text(a['message']?.toString() ?? '',
                                    maxLines: 3, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                                const SizedBox(height: 6),
                                Row(children: [
                                  const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textHint),
                                  const SizedBox(width: 3),
                                  Text(_timeAgo(a['created_at']?.toString()),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                ]),
                              ])),
                            ]),
                          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _timeAgo(String? ts) {
    if (ts == null) return '';
    try {
      final dt   = DateTime.parse(ts);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts;
    }
  }
}
