import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

final teacherClassesListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = res.data;
  final list = data is Map ? (data['data'] ?? []) : data;
  return (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
});

class TeacherStudentsScreen extends ConsumerStatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  ConsumerState<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends ConsumerState<TeacherStudentsScreen> {
  final _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _students = [];
  Timer? _debounce;

  int? _classId;
  String _search = '';
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  bool _loading = false;
  bool _firstLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 300 &&
          !_loading && _page < _lastPage) {
        _fetch();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (reset) {
        _page = 1;
        _students.clear();
        _firstLoad = true;
      }
    });
    try {
      final res = await ApiService().get('/students', params: {
        'page': _page,
        'status': 'active',
        if (_classId != null) 'class_id': _classId,
        if (_search.isNotEmpty) 'search': _search,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      final rows = (data['data'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _students.addAll(rows);
        _lastPage = data['last_page'] as int? ?? 1;
        _total    = data['total'] as int? ?? _students.length;
        _page++;
        _loading = false;
        _firstLoad = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _firstLoad = false;
        _error = 'Could not load students';
      });
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search = v.trim();
      _fetch(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(teacherClassesListProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: AppSearchField(hint: 'Search name or admission no...', onChanged: _onSearch),
              ),
              const SizedBox(height: 10),
              classesAsync.maybeWhen(
                data: (classes) => _buildClassChips(classes),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
    child: Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        ),
        const Expanded(
          child: Text('My Students',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ),
        if (!_firstLoad)
          Text('$_total total',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildClassChips(List<Map<String, dynamic>> classes) {
    if (classes.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chip('All', _classId == null, () {
            setState(() => _classId = null);
            _fetch(reset: true);
          }),
          ...classes.map((c) {
            final id = c['id'] as int?;
            return _chip('${c['name']}', _classId == id, () {
              setState(() => _classId = id);
              _fetch(reset: true);
            });
          }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.roleTeacher.withOpacity(0.2) : AppColors.surface1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.roleTeacher : Colors.white.withOpacity(0.08)),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.roleTeacher : AppColors.textSecondary,
          )),
      ),
    ),
  );

  Widget _buildBody() {
    if (_firstLoad && _loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(8, (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: ShimmerCard(height: 72),
        )),
      );
    }
    if (_error != null && _students.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _fetch(reset: true), child: const Text('Retry')),
        ]),
      );
    }
    if (_students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.people_outline_rounded, color: AppColors.textHint, size: 64),
            SizedBox(height: 16),
            Text('No students found',
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            SizedBox(height: 6),
            Text('Students appear here once classes are assigned to you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.roleTeacher,
      backgroundColor: AppColors.surface1,
      onRefresh: () async => _fetch(reset: true),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _students.length + (_page <= _lastPage && _loading ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= _students.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: AppColors.roleTeacher)),
            );
          }
          return _studentTile(_students[i], i);
        },
      ),
    );
  }

  Widget _studentTile(Map<String, dynamic> s, int index) {
    final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    final initials = name.isEmpty
        ? '?'
        : name.split(' ').take(2).map((w) => w.isEmpty ? '' : w[0]).join().toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: () => _showStudentInfo(s),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            AvatarWidget(
              imageUrl: s['photo_url'] as String?,
              initials: initials,
              color: AppColors.roleTeacher,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  [
                    if ((s['admission_number'] ?? '').toString().isNotEmpty) s['admission_number'],
                    if ((s['class_name'] ?? '').toString().isNotEmpty) s['class_name'],
                  ].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ).animate(delay: Duration(milliseconds: (index % 10) * 30)).fadeIn(duration: 250.ms),
    );
  }

  void _showStudentInfo(Map<String, dynamic> s) {
    final name = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              AvatarWidget(
                imageUrl: s['photo_url'] as String?,
                initials: name.isEmpty ? '?' : name[0].toUpperCase(),
                color: AppColors.roleTeacher,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text('${s['class_name'] ?? '—'}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            _infoRow('Admission No.', '${s['admission_number'] ?? '—'}'),
            _infoRow('Gender', '${s['gender'] ?? '—'}'),
            _infoRow('Date of Birth', '${s['date_of_birth'] ?? '—'}'),
            _infoRow('Student Type', '${s['student_type'] ?? '—'}'),
            _infoRow('Guardian', '${s['guardian_name'] ?? '—'}'),
            _infoRow('Guardian Phone', '${s['guardian_phone'] ?? '—'}'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textHint))),
        Expanded(
          child: Text(value.isEmpty ? '—' : value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
