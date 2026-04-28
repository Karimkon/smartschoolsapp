import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final librarianDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class LibrarianDashboard extends ConsumerWidget {
  const LibrarianDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(librarianDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.roleLibrarian,
            backgroundColor: AppColors.surface1,
            onRefresh: () async => ref.invalidate(librarianDashboardProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(user).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
                        const SizedBox(height: 24),
                        dashAsync.when(
                          loading: () => _statsShimmer(),
                          error: (e, _) => _buildError(ref, e),
                          data: (d) => _buildStats(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context)
                            .animate(delay: 250.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Overdue Borrowings',
                          action: 'View All',
                          onAction: () => context.push('/librarian/books'),
                        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => _listShimmer(),
                          error: (_, __) => _listShimmer(),
                          data: (d) => _buildOverdueList(d),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(user) {
    final name     = user?.name ?? 'Librarian';
    final initials = user?.initials ?? 'L';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              StatusBadge(label: 'Librarian', color: AppColors.roleLibrarian),
            ],
          ),
        ),
        AvatarWidget(initials: initials, color: AppColors.roleLibrarian, size: 52),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _statsShimmer() => GridView.count(
    shrinkWrap: true,
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.4,
    physics: const NeverScrollableScrollPhysics(),
    children: List.generate(4, (_) => const ShimmerCard()),
  );

  Widget _listShimmer() => Column(
    children: List.generate(4, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ShimmerCard(height: 72),
    )),
  );

  Widget _buildError(WidgetRef ref, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(children: [
        const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
        const SizedBox(height: 12),
        const Text('Could not load dashboard', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.invalidate(librarianDashboardProvider),
          child: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildStats(Map<String, dynamic> d) {
    final stats     = d['stats'] as Map? ?? {};
    final total     = stats['total']     as int? ?? 0;
    final borrowed  = stats['borrowed']  as int? ?? 0;
    final overdue   = stats['overdue']   as int? ?? 0;
    final available = stats['available'] as int? ?? 0;

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Total Books', value: '$total', icon: Icons.auto_stories_rounded, color: AppColors.roleLibrarian, index: 0),
        StatCard(label: 'Borrowed', value: '$borrowed', icon: Icons.import_contacts_rounded, color: AppColors.primary, index: 1),
        StatCard(label: 'Overdue', value: '$overdue', icon: Icons.schedule_rounded, color: AppColors.error, subtitle: overdue > 0 ? 'Overdue' : null, index: 2),
        StatCard(label: 'Available', value: '$available', icon: Icons.library_books_rounded, color: AppColors.success, index: 3),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Issue\nBook', Icons.outbound_rounded, AppColors.primary, '/librarian/books'),
      _QuickAction('Return\nBook', Icons.assignment_return_rounded, AppColors.success, '/librarian/books'),
      _QuickAction('Catalogue', Icons.menu_book_rounded, AppColors.roleLibrarian, '/librarian/books'),
    ];
    return Row(
      children: actions.map((a) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
          child: GlassCard(
            onTap: () => context.push(a.route),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(a.icon, color: a.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(a.label, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildOverdueList(Map<String, dynamic> d) {
    final list = (d['overdue_list'] as List?) ?? [];
    if (list.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Column(children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 36),
            SizedBox(height: 8),
            Text('No overdue borrowings', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      ).animate(delay: 300.ms).fadeIn();
    }

    return Column(
      children: list.asMap().entries.map((e) {
        final b         = e.value as Map;
        final idx       = e.key;
        final title     = b['title']?.toString() ?? 'Unknown Book';
        final student   = b['student_name']?.toString() ?? 'Unknown';
        final dueDate   = b['due_date']?.toString() ?? '';
        final daysOver  = _daysOverdue(dueDate);
        final urgency   = daysOver >= 10
            ? AppColors.error
            : daysOver >= 7
                ? AppColors.warning
                : AppColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: urgency.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: urgency, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(student, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(label: '${daysOver}d overdue', color: urgency),
                    const SizedBox(height: 4),
                    Text('Due: ${_fmtDate(dueDate)}', style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 300 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }

  int _daysOverdue(String dueDate) {
    if (dueDate.isEmpty) return 0;
    try {
      final due  = DateTime.parse(dueDate);
      final now  = DateTime.now();
      final diff = now.difference(due).inDays;
      return diff > 0 ? diff : 0;
    } catch (_) { return 0; }
  }

  String _fmtDate(String d) {
    if (d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
  }

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
