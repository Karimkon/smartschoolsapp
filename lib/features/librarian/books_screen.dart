import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Book {
  final int id;
  final String title, author, category, isbn, status, borrowedBy;
  final Color color;
  final int copies, available;

  const _Book({
    required this.id, required this.title, required this.author,
    required this.category, required this.isbn, required this.status,
    required this.color, required this.copies, required this.available,
    this.borrowedBy = '',
  });
}

const _categories = ['All', 'Mathematics', 'Science', 'Language', 'History', 'Literature', 'Reference'];

const _mockBooks = [
  _Book(id: 1,  title: 'Advanced Mathematics',     author: 'Prof. J. Kimani',    category: 'Mathematics', isbn: '978-0-12-345678-9', status: 'Available', color: AppColors.primary,       copies: 5, available: 3),
  _Book(id: 2,  title: 'Biology Fundamentals',     author: 'Dr. M. Ochieng',    category: 'Science',     isbn: '978-1-23-456789-0', status: 'Borrowed',  color: AppColors.accent,        copies: 4, available: 0, borrowedBy: 'Amara Osei'),
  _Book(id: 3,  title: 'A Tale of Two Cities',     author: 'Charles Dickens',    category: 'Literature',  isbn: '978-2-34-567890-1', status: 'Available', color: AppColors.roleTeacher,   copies: 6, available: 5),
  _Book(id: 4,  title: 'World History Vol. 2',     author: 'Dr. S. Mwangi',     category: 'History',     isbn: '978-3-45-678901-2', status: 'Overdue',   color: AppColors.warning,       copies: 3, available: 0, borrowedBy: 'Brian Mwangi'),
  _Book(id: 5,  title: 'English Grammar Guide',    author: 'L. Nakato',         category: 'Language',    isbn: '978-4-56-789012-3', status: 'Available', color: AppColors.roleTeacher,   copies: 8, available: 6),
  _Book(id: 6,  title: 'Chemistry Practicals',     author: 'Dr. R. Otieno',     category: 'Science',     isbn: '978-5-67-890123-4', status: 'Available', color: AppColors.success,       copies: 4, available: 2),
  _Book(id: 7,  title: 'Oxford Dictionary',        author: 'Oxford Press',       category: 'Reference',   isbn: '978-6-78-901234-5', status: 'Available', color: AppColors.primary,       copies: 10, available: 8),
  _Book(id: 8,  title: 'Geography of Africa',      author: 'P. Ssali',          category: 'History',     isbn: '978-7-89-012345-6', status: 'Borrowed',  color: AppColors.warning,       copies: 3, available: 0, borrowedBy: 'Chidi Okonkwo'),
  _Book(id: 9,  title: 'Physics Principles',       author: 'Dr. A. Kamau',      category: 'Science',     isbn: '978-8-90-123456-7', status: 'Available', color: AppColors.roleAccountant, copies: 5, available: 3),
  _Book(id: 10, title: 'Mathematics Olympiad',     author: 'Prof. E. Weru',     category: 'Mathematics', isbn: '978-9-01-234567-8', status: 'Available', color: AppColors.primary,       copies: 2, available: 2),
  _Book(id: 11, title: 'Pride and Prejudice',      author: 'Jane Austen',        category: 'Literature',  isbn: '978-0-11-234567-9', status: 'Overdue',   color: AppColors.roleTeacher,   copies: 4, available: 0, borrowedBy: 'Diana Kamau'),
  _Book(id: 12, title: 'Kiswahili Grammar',        author: 'Dr. J. Auma',       category: 'Language',    isbn: '978-1-12-345670-0', status: 'Available', color: AppColors.roleAccountant, copies: 6, available: 5),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _searchCtrl = TextEditingController();
  String _query    = '';
  String _category = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Book> get _filtered => _mockBooks.where((b) {
    final matchCat   = _category == 'All' || b.category == _category;
    final matchQuery = _query.isEmpty ||
        b.title.toLowerCase().contains(_query.toLowerCase()) ||
        b.author.toLowerCase().contains(_query.toLowerCase());
    return matchCat && matchQuery;
  }).toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'Available': return AppColors.success;
      case 'Borrowed':  return AppColors.warning;
      case 'Overdue':   return AppColors.error;
      default:          return AppColors.textSecondary;
    }
  }

  void _showBookDetail(_Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookDetailSheet(book: book, statusColor: _statusColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text('Books', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.roleLibrarian.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('${_mockBooks.length}', style: const TextStyle(color: AppColors.roleLibrarian, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search title or author...',
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final c = _categories[i];
                        final sel = c == _category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = c),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.roleLibrarian : AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? AppColors.roleLibrarian : Colors.white.withOpacity(0.07)),
                            ),
                            child: Text(c, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppColors.textSecondary, fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
                          ),
                        );
                      },
                    ),
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Text('${books.length} book${books.length != 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            Expanded(
              child: books.isEmpty
                  ? const Center(child: Text('No books found', style: TextStyle(color: AppColors.textSecondary)))
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: books.length,
                      itemBuilder: (_, i) {
                        final b = books[i];
                        return GestureDetector(
                          onTap: () => _showBookDetail(b),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cover placeholder
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [b.color, b.color.withOpacity(0.6)],
                                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.menu_book_rounded, color: Colors.white.withOpacity(0.8), size: 36),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            b.category,
                                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.title,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(b.author, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(child: StatusBadge(label: b.status, color: _statusColor(b.status))),
                                          Text('${b.available}/${b.copies}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideY(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Book Detail Bottom Sheet ──────────────────────────────────────────────────

class _BookDetailSheet extends StatelessWidget {
  final _Book book;
  final Color Function(String) statusColor;
  const _BookDetailSheet({required this.book, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final isAvailable = book.status == 'Available';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 70, height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [book.color, book.color.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(book.author, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    StatusBadge(label: book.status, color: statusColor(book.status)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailRow('Category', book.category),
          _DetailRow('ISBN', book.isbn),
          _DetailRow('Total Copies', '${book.copies}'),
          _DetailRow('Available', '${book.available}'),
          if (book.borrowedBy.isNotEmpty) _DetailRow('Borrowed By', book.borrowedBy),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  label: isAvailable ? 'Issue Book' : 'Return Book',
                  gradient: isAvailable
                      ? AppColors.primaryGradient
                      : const LinearGradient(colors: [AppColors.warning, AppColors.error]),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAvailable ? '"${book.title}" issued' : '"${book.title}" returned'),
                        backgroundColor: isAvailable ? AppColors.success : AppColors.warning,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ],
    ),
  );
}
