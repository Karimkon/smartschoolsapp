import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final libraryBooksProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/library/books$query');
  return Map<String, dynamic>.from(res.data as Map);
});

final libraryBorrowingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/library/borrowings');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminLibraryScreen extends ConsumerStatefulWidget {
  const AdminLibraryScreen({super.key});
  @override ConsumerState<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends ConsumerState<AdminLibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _bookQuery =>
      _query.isEmpty ? '' : '?search=${Uri.encodeComponent(_query)}';

  @override
  Widget build(BuildContext context) {
    final borrowingsAsync = ref.watch(libraryBorrowingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Library',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(libraryBooksProvider);
              ref.invalidate(libraryBorrowingsProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFEF4444),
          labelColor: const Color(0xFFEF4444),
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Books'), Tab(text: 'Borrowings')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: TabBarView(
          controller: _tabs,
          children: [
            // ── Books Tab ──────────────────────────────────────────────────
            Column(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppSearchField(
                  hint: 'Search books...',
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ).animate(delay: 100.ms).fadeIn(),
              ),
              Expanded(child: _BooksTab(queryString: _bookQuery)),
            ]),

            // ── Borrowings Tab ─────────────────────────────────────────────
            borrowingsAsync.when(
              loading: () => _shimmerList(),
              error: (e, _) => _errorWidget(
                  'Could not load borrowings', () => ref.invalidate(libraryBorrowingsProvider)),
              data: (data) => _BorrowingsList(
                borrowings: (data['data'] as List?) ?? [],
                onReturn: () => ref.invalidate(libraryBorrowingsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, __) =>
        const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 80)),
  );

  Widget _errorWidget(String msg, VoidCallback onRetry) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
      const SizedBox(height: 12),
      Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}

// ── Books Tab ─────────────────────────────────────────────────────────────────

class _BooksTab extends ConsumerWidget {
  final String queryString;
  const _BooksTab({required this.queryString});

  static const _palette = [
    AppColors.primary, AppColors.roleTeacher, Color(0xFFEF4444),
    AppColors.warning, AppColors.success, AppColors.accent,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(libraryBooksProvider(queryString));

    return async.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: 5,
        itemBuilder: (_, __) =>
            const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 90)),
      ),
      error: (e, _) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load books', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => ref.invalidate(libraryBooksProvider),
              child: const Text('Retry')),
        ]),
      ),
      data: (data) {
        final books = (data['data'] as List?) ?? [];
        if (books.isEmpty) {
          return const Center(child: Text('No books found', style: TextStyle(color: AppColors.textHint)));
        }
        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface1,
          onRefresh: () => ref.refresh(libraryBooksProvider(queryString).future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: books.length,
            itemBuilder: (ctx, i) {
              final b      = books[i] as Map;
              final total  = (b['quantity'] as num?)?.toInt() ?? 0;
              final issued = (b['issued_count'] as num?)?.toInt() ?? 0;
              final avail  = total - issued;
              final color  = avail > 0 ? AppColors.success : AppColors.error;
              final accent = _palette[i % _palette.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      width: 48, height: 58,
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.menu_book_rounded, color: accent, size: 22),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b['title']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(b['author']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(height: 3),
                      Row(children: [
                        if ((b['category'] ?? '').toString().isNotEmpty)
                          StatusBadge(label: b['category'].toString(), color: AppColors.primary),
                        if ((b['isbn'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text('ISBN: ${b['isbn']}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ],
                      ]),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('$avail/$total',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                      Text('available', style: TextStyle(fontSize: 9, color: color)),
                      const SizedBox(height: 4),
                      StatusBadge(
                          label: avail > 0 ? 'Available' : 'All Issued',
                          color: color),
                    ]),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
            },
          ),
        );
      },
    );
  }
}

// ── Borrowings List ───────────────────────────────────────────────────────────

class _BorrowingsList extends StatelessWidget {
  final List borrowings;
  final VoidCallback onReturn;
  const _BorrowingsList({required this.borrowings, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    if (borrowings.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.library_books_rounded, color: AppColors.textHint, size: 48),
          SizedBox(height: 12),
          Text('No active borrowings', style: TextStyle(color: AppColors.textHint)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      onRefresh: () async => onReturn(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: borrowings.length,
        itemBuilder: (ctx, i) {
          final bor      = borrowings[i] as Map;
          final isOverdue = bor['is_overdue'] == true || bor['is_overdue'] == 1;
          final color    = isOverdue ? AppColors.error : AppColors.success;
          final dueDate  = bor['due_date']?.toString() ?? '';
          final issueDate = bor['issue_date']?.toString() ?? '';
          final student  = bor['student_name']?.toString() ?? '';
          final title    = bor['book_title']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    isOverdue ? Icons.warning_rounded : Icons.library_books_rounded,
                    color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(title,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text('Issued: $issueDate',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Icon(Icons.event_rounded, size: 11, color: color),
                    const SizedBox(width: 4),
                    Text('Due: $dueDate',
                        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ]),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text('Return',
                      style: TextStyle(color: AppColors.primary, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: i * 60)).fadeIn();
        },
      ),
    );
  }
}
