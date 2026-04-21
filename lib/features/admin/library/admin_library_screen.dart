import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Book {
  final int id;
  final String title, author, category, isbn;
  final int total, available;
  const _Book({required this.id, required this.title, required this.author, required this.category, required this.isbn, required this.total, required this.available});
  bool get isAvailable => available > 0;
}

class _Borrowing {
  final String studentName, bookTitle, issueDate, dueDate;
  final bool isOverdue;
  const _Borrowing({required this.studentName, required this.bookTitle, required this.issueDate, required this.dueDate, required this.isOverdue});
}

const _mockBooks = [
  _Book(id:1, title:'New General Mathematics',  author:'J.B. Channon',    category:'Textbook', isbn:'978-001', total:15, available:8),
  _Book(id:2, title:'English Grammar in Use',   author:'Raymond Murphy',  category:'Language',  isbn:'978-002', total:10, available:0),
  _Book(id:3, title:'Living in Science Form 3', author:'T. K. Ng',        category:'Textbook', isbn:'978-003', total:20, available:12),
  _Book(id:4, title:'Things Fall Apart',        author:'Chinua Achebe',   category:'Fiction',  isbn:'978-004', total:8,  available:3),
  _Book(id:5, title:'African Geography',        author:'S. H. Ominde',    category:'Textbook', isbn:'978-005', total:12, available:7),
  _Book(id:6, title:'Kenya History & Civics',   author:'H. Mwaniki',      category:'Textbook', isbn:'978-006', total:18, available:15),
  _Book(id:7, title:'Weep Not, Child',          author:'Ngugi wa Thiong\'o',category:'Fiction', isbn:'978-007', total:6,  available:1),
];

const _mockBorrowings = [
  _Borrowing(studentName:'Amara Osei',    bookTitle:'English Grammar in Use', issueDate:'Apr 5', dueDate:'Apr 19', isOverdue:true),
  _Borrowing(studentName:'Brian Mwangi',  bookTitle:'Things Fall Apart',      issueDate:'Apr 10',dueDate:'Apr 24', isOverdue:false),
  _Borrowing(studentName:'Chloe Wanjiru', bookTitle:'Weep Not, Child',        issueDate:'Apr 12',dueDate:'Apr 26', isOverdue:false),
  _Borrowing(studentName:'Diana Kamau',   bookTitle:'New General Mathematics',issueDate:'Apr 3', dueDate:'Apr 17', isOverdue:true),
];

class AdminLibraryScreen extends StatefulWidget {
  const AdminLibraryScreen({super.key});
  @override State<AdminLibraryScreen> createState() => _AdminLibraryScreenState();
}

class _AdminLibraryScreenState extends State<AdminLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void initState() { super.initState(); _tabs = TabController(length: 2, vsync: this); }
  @override void dispose() { _tabs.dispose(); _searchCtrl.dispose(); super.dispose(); }

  List<_Book> get _filteredBooks => _mockBooks.where((b) =>
    _query.isEmpty || b.title.toLowerCase().contains(_query.toLowerCase()) || b.author.toLowerCase().contains(_query.toLowerCase())
  ).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Library', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {})],
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
        child: TabBarView(controller: _tabs, children: [
          // Books tab
          Column(children: [
            Padding(padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _MiniStat('Total Books', '${_mockBooks.length}', AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat('Borrowed', '${_mockBooks.fold(0, (s, b) => s + b.total - b.available)}', const Color(0xFFEF4444))),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat('Overdue', '${_mockBorrowings.where((bor) => bor.isOverdue).length}', AppColors.warning)),
                ]).animate().fadeIn(),
                const SizedBox(height: 12),
                AppSearchField(hint: 'Search books...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate(delay: 100.ms).fadeIn(),
              ]),
            ),
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16,0,16,80),
              itemCount: _filteredBooks.length,
              itemBuilder: (ctx, i) {
                final b = _filteredBooks[i];
                final color = b.isAvailable ? AppColors.success : AppColors.error;
                return Padding(padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 48, height: 58, decoration: BoxDecoration(
                        color: [AppColors.primary, AppColors.roleTeacher, const Color(0xFFEF4444), AppColors.warning, AppColors.success, AppColors.accent][i % 6].withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.menu_book_rounded, color: [AppColors.primary, AppColors.roleTeacher, const Color(0xFFEF4444), AppColors.warning, AppColors.success, AppColors.accent][i % 6], size: 22),
                        ]),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(b.author, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 3),
                        Row(children: [
                          StatusBadge(label: b.category, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('ISBN: ${b.isbn}', style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ]),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${b.available}/${b.total}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                        Text('available', style: TextStyle(fontSize: 9, color: color)),
                        const SizedBox(height: 4),
                        StatusBadge(label: b.isAvailable ? 'Available' : 'All Issued', color: color),
                      ]),
                    ]),
                  ),
                ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
              },
            )),
          ]),

          // Borrowings tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _mockBorrowings.length,
            itemBuilder: (ctx, i) {
              final bor = _mockBorrowings[i];
              final color = bor.isOverdue ? AppColors.error : AppColors.success;
              return Padding(padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(bor.isOverdue ? Icons.warning_rounded : Icons.library_books_rounded, color: color, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(bor.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text(bor.bookTitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                        Text('Issued: ${bor.issueDate}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        Icon(Icons.event_rounded, size: 11, color: color), const SizedBox(width: 4),
                        Text('Due: ${bor.dueDate}', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ]),
                    ])),
                    GestureDetector(onTap: () {},
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Return', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)))),
                  ]),
                ),
              ).animate(delay: Duration(milliseconds: i * 60)).fadeIn();
            },
          ),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value; final Color color;
  const _MiniStat(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => GlassCard(padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  );
}
