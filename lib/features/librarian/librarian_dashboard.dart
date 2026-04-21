import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class LibrarianDashboardData {
  final int totalBooks;
  final int borrowedBooks;
  final int overdueBooks;
  final int availableBooks;
  final List<BookCategory> bookCategories;
  final List<OverdueBorrowing> overdueBorrowings;

  const LibrarianDashboardData({
    required this.totalBooks,
    required this.borrowedBooks,
    required this.overdueBooks,
    required this.availableBooks,
    required this.bookCategories,
    required this.overdueBorrowings,
  });
}

class BookCategory {
  final String name;
  final double percent;
  final Color color;
  const BookCategory(this.name, this.percent, this.color);
}

class OverdueBorrowing {
  final String studentName;
  final String bookTitle;
  final int daysOverdue;
  final String dueDate;
  const OverdueBorrowing(this.studentName, this.bookTitle, this.daysOverdue, this.dueDate);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final librarianDashboardProvider = FutureProvider<LibrarianDashboardData>((ref) async {
  try {
    await Future.delayed(const Duration(milliseconds: 600));
    throw Exception('Using mock data');
  } catch (_) {
    return const LibrarianDashboardData(
      totalBooks: 3842,
      borrowedBooks: 318,
      overdueBooks: 43,
      availableBooks: 3481,
      bookCategories: [
        BookCategory('Fiction', 30.0, AppColors.roleTeacher),
        BookCategory('Science', 25.0, AppColors.primary),
        BookCategory('History', 20.0, AppColors.warning),
        BookCategory('Math', 25.0, AppColors.roleLibrarian),
      ],
      overdueBorrowings: [
        OverdueBorrowing('Kevin Mburu', 'A Brief History of Time', 14, '07 Apr 2025'),
        OverdueBorrowing('Amina Hassan', 'Things Fall Apart', 11, '10 Apr 2025'),
        OverdueBorrowing('Samuel Odhiambo', 'Calculus: Early Transcendentals', 9, '12 Apr 2025'),
        OverdueBorrowing('Lucy Njeri', 'The Great Gatsby', 7, '14 Apr 2025'),
        OverdueBorrowing('James Maina', 'Sapiens: A Brief History', 5, '16 Apr 2025'),
        OverdueBorrowing('Fatuma Ali', 'Pride and Prejudice', 3, '18 Apr 2025'),
      ],
    );
  }
});

// ── Dashboard Screen ──────────────────────────────────────────────────────────

class LibrarianDashboard extends ConsumerStatefulWidget {
  const LibrarianDashboard({super.key});

  @override
  ConsumerState<LibrarianDashboard> createState() => _LibrarianDashboardState();
}

class _LibrarianDashboardState extends ConsumerState<LibrarianDashboard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
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
                          error: (_, __) => _statsShimmer(),
                          data: (d) => _buildStats(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Collection by Category',
                          action: 'Catalogue',
                          onAction: () => context.push('/librarian/catalogue'),
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        dashAsync.when(
                          loading: () => const ShimmerCard(height: 240),
                          error: (_, __) => const ShimmerCard(height: 240),
                          data: (d) => _buildPieChart(d),
                        ),
                        const SizedBox(height: 24),
                        SectionHeader(title: 'Quick Actions')
                            .animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        _buildQuickActions(context)
                            .animate(delay: 350.ms).fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        SectionHeader(
                          title: 'Overdue Borrowings',
                          action: 'View All',
                          onAction: () => context.push('/librarian/overdue'),
                        ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
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
    final name = user?.name ?? 'Librarian';
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

  Widget _buildStats(LibrarianDashboardData d) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        StatCard(label: 'Total Books', value: '${d.totalBooks}', icon: Icons.auto_stories_rounded, color: AppColors.roleLibrarian, index: 0),
        StatCard(label: 'Borrowed', value: '${d.borrowedBooks}', icon: Icons.import_contacts_rounded, color: AppColors.primary, index: 1),
        StatCard(label: 'Overdue', value: '${d.overdueBooks}', icon: Icons.schedule_rounded, color: AppColors.error, subtitle: 'Overdue', index: 2),
        StatCard(label: 'Available', value: '${d.availableBooks}', icon: Icons.library_books_rounded, color: AppColors.success, index: 3),
      ],
    );
  }

  Widget _buildPieChart(LibrarianDashboardData d) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions && response?.touchedSection != null) {
                        setState(() {
                          _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                        });
                      } else {
                        setState(() => _touchedIndex = -1);
                      }
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: d.bookCategories.asMap().entries.map((e) {
                    final isTouched = e.key == _touchedIndex;
                    return PieChartSectionData(
                      color: e.value.color,
                      value: e.value.percent,
                      title: '${e.value.percent.toStringAsFixed(0)}%',
                      radius: isTouched ? 62 : 50,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: d.bookCategories.map((cat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          Text('${cat.percent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction('Issue\nBook', Icons.outbound_rounded, AppColors.primary, '/librarian/issue'),
      _QuickAction('Return\nBook', Icons.assignment_return_rounded, AppColors.success, '/librarian/return'),
      _QuickAction('Add\nBook', Icons.add_box_rounded, AppColors.roleLibrarian, '/librarian/books/add'),
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

  Widget _buildOverdueList(LibrarianDashboardData d) {
    return Column(
      children: d.overdueBorrowings.asMap().entries.map((e) {
        final b = e.value;
        final idx = e.key;
        final urgencyColor = b.daysOverdue >= 10
            ? AppColors.error
            : b.daysOverdue >= 7
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
                    color: urgencyColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.menu_book_rounded, color: urgencyColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.bookTitle,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(b.studentName, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(label: '${b.daysOverdue}d overdue', color: urgencyColor),
                    const SizedBox(height: 4),
                    Text('Due: ${b.dueDate}', style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 400 + idx * 60)).fadeIn().slideY(begin: 0.1, end: 0);
      }).toList(),
    );
  }
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  final Color color;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}
