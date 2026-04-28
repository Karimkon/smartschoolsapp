import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final booksProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, query) async {
  final params = query.isNotEmpty ? {'search': query} : <String, dynamic>{};
  final res = await ApiService().get('/library/books', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class BooksScreen extends ConsumerStatefulWidget {
  const BooksScreen({super.key});

  @override
  ConsumerState<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends ConsumerState<BooksScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  static const _colors = [
    AppColors.primary, AppColors.roleTeacher, AppColors.accent,
    AppColors.warning, AppColors.success, AppColors.roleLibrarian,
    AppColors.roleAccountant, AppColors.error,
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

  Color _availabilityColor(int available, int total) {
    if (available == 0) return AppColors.error;
    if (available < total / 2) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(booksProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: async.when(
          loading: () => const Text('Books', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          error: (_, __) => const Text('Books', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          data: (d) {
            final total = (d['total'] as int?) ?? (d['data'] as List?)?.length ?? 0;
            return Row(children: [
              const Text('Books', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.roleLibrarian.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total', style: const TextStyle(color: AppColors.roleLibrarian, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(booksProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: AppSearchField(
                hint: 'Search by title or author...',
                controller: _searchCtrl,
                onChanged: _onSearch,
              ).animate().fadeIn(duration: 300.ms),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: List.generate(8, (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerCard(height: 90),
                  )),
                ),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load books', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(booksProvider),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (d) {
                  final books = (d['data'] as List?) ?? (d['books'] as List?) ?? [];
                  if (books.isEmpty) {
                    return Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.menu_book_outlined, color: AppColors.textHint, size: 64),
                        const SizedBox(height: 16),
                        Text(_query.isEmpty ? 'No books in catalogue' : 'No results for "$_query"',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ]),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.roleLibrarian,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () async => ref.invalidate(booksProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b         = books[i] as Map;
                        final title     = b['title']?.toString() ?? 'Unknown';
                        final author    = b['author']?.toString() ?? '';
                        final category  = b['category']?.toString() ?? '';
                        final isbn      = b['isbn']?.toString() ?? '';
                        final copies    = (b['copies'] as int?) ?? (b['total_copies'] as int?) ?? 1;
                        final available = (b['available'] as int?) ?? (b['available_copies'] as int?) ?? copies;
                        final color     = _colors[i % _colors.length];
                        final avColor   = _availabilityColor(available, copies);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.menu_book_rounded, color: color, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      if (author.isNotEmpty)
                                        Text(author, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        if (category.isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(category, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text('$available/$copies available',
                                            style: TextStyle(fontSize: 11, color: avColor, fontWeight: FontWeight.w600)),
                                      ]),
                                      if (isbn.isNotEmpty)
                                        Text('ISBN: $isbn', style: const TextStyle(fontSize: 9, color: AppColors.textHint)),
                                    ],
                                  ),
                                ),
                                if (available == 0)
                                  const StatusBadge(label: 'Out', color: AppColors.error)
                                else
                                  StatusBadge(label: 'In Stock', color: AppColors.success),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideY(begin: 0.05, end: 0);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
