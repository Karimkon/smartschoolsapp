import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Model ──────────────────────────────────────────────────────────────────────
class StudentModel {
  final int    id;
  final String firstName, lastName;
  final String admissionNumber, status;
  final String? className, sectionName, photo, photoUrl, studentType, guardianName, guardianPhone, gender;

  StudentModel.fromJson(Map<String, dynamic> j)
      : id              = j['id'] as int,
        firstName       = (j['first_name']       ?? '').toString(),
        lastName        = (j['last_name']        ?? '').toString(),
        admissionNumber = (j['admission_number'] ?? '').toString(),
        status          = (j['status']           ?? 'active').toString(),
        className       = j['class_name']?.toString(),
        sectionName     = j['section_name']?.toString(),
        photo           = j['photo']?.toString(),
        photoUrl        = j['photo_url']?.toString(),
        studentType     = j['student_type']?.toString(),
        guardianName    = j['guardian_name']?.toString(),
        guardianPhone   = j['guardian_phone']?.toString(),
        gender          = j['gender']?.toString();

  String get name => '$firstName $lastName'.trim();
  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }
}

// ── Providers ──────────────────────────────────────────────────────────────────
final studentsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, queryString) async {
  final res = await ApiService().get('/students$queryString');
  return Map<String, dynamic>.from(res.data as Map);
});

final classesListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = Map<String, dynamic>.from(res.data as Map);
  return List<Map<String, dynamic>>.from(
      (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});
  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _search = '';
  Timer? _debounce;

  String get _queryString {
    final params = <String>[];
    if (_search.isNotEmpty) params.add('search=${Uri.encodeComponent(_search)}');
    if (_filter != 'all')   params.add('status=$_filter');
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _search = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Color _avatarColor(int i) => const [
    AppColors.primary, AppColors.accent, AppColors.roleTeacher,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
  ][i % 6];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentsProvider(_queryString));

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
            final total = toI(data['total'] ?? (data['data'] as List?)?.length ?? 0);
            return Row(children: [
              const Text('Students',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${total.toInt()}',
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]);
          },
          orElse: () => const Text('Students',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.refresh(studentsProvider(_queryString)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _AddStudentSheet(),
          );
          if (added == true && mounted) {
            ref.invalidate(studentsProvider);
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // ── Search + Filter ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  AppSearchField(
                    hint: 'Search by name, admission no...',
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final item in [('All', 'all'), ('Active', 'active'), ('Inactive', 'inactive')])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _filter = item.$2),
                            child: AnimatedContainer(
                              duration: 200.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _filter == item.$2 ? AppColors.primary : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _filter == item.$2
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.07)),
                              ),
                              child: Text(
                                item.$1,
                                style: TextStyle(
                                  color: _filter == item.$2 ? Colors.white : AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: _filter == item.$2 ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ).animate(delay: 100.ms).fadeIn(),
                ],
              ),
            ),

            // ── Results ──────────────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                      const SizedBox(height: 12),
                      Text('Could not load students',
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => ref.refresh(studentsProvider(_queryString)),
                          child: const Text('Retry')),
                    ]),
                  ),
                ),
                data: (data) {
                  final students = (data['data'] as List)
                      .map((j) => StudentModel.fromJson(j as Map<String, dynamic>))
                      .toList();
                  final total = toI(data['total'] ?? students.length);

                  if (students.isEmpty) {
                    return const Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.search_off_rounded, color: AppColors.textHint, size: 52),
                        SizedBox(height: 12),
                        Text('No students found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ]),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${total.toInt()} student${total != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppColors.primary,
                          backgroundColor: AppColors.surface1,
                          onRefresh: () =>
                              ref.refresh(studentsProvider(_queryString).future),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final s = students[i];
                              final isActive = s.status.toLowerCase() == 'active';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  onTap: () => context.push('/admin/students/${s.id}'),
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      AvatarWidget(
                                          imageUrl: s.photoUrl,
                                          initials: s.initials,
                                          color: _avatarColor(i),
                                          size: 48),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.textPrimary)),
                                            const SizedBox(height: 3),
                                            Row(children: [
                                                const Icon(Icons.badge_rounded, size: 12, color: AppColors.textHint),
                                                const SizedBox(width: 4),
                                                Text(s.admissionNumber, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                if (s.className != null && s.className!.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint),
                                                  const SizedBox(width: 4),
                                                  Flexible(child: Text(s.className!, overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
                                                ],
                                            ]),
                                            if (s.sectionName != null && s.sectionName!.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Row(children: [
                                                const Icon(Icons.groups_rounded, size: 12, color: AppColors.textHint),
                                                const SizedBox(width: 4),
                                                Text(s.sectionName!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              ]),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        StatusBadge(
                                          label: isActive ? 'Active' : 'Inactive',
                                          color: isActive ? AppColors.success : AppColors.error,
                                        ),
                                        if (s.studentType != null && s.studentType!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          StatusBadge(
                                            label: s.studentType![0].toUpperCase() + s.studentType!.substring(1),
                                            color: s.studentType!.toLowerCase() == 'boarding' ? AppColors.accent : AppColors.roleTeacher,
                                          ),
                                        ],
                                      ]),
                                    ],
                                  ),
                                ),
                              ).animate(delay: Duration(milliseconds: i * 30))
                                  .fadeIn()
                                  .slideX(begin: 0.05, end: 0);
                            },
                          ),
                        ),
                      ),
                    ],
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

// ── Add Student Sheet ─────────────────────────────────────────────────────────

class _AddStudentSheet extends ConsumerStatefulWidget {
  const _AddStudentSheet();

  @override
  ConsumerState<_AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<_AddStudentSheet> {
  final _formKey       = GlobalKey<FormState>();
  final _firstCtrl     = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _guardNameCtrl = TextEditingController();
  final _guardPhoneCtrl = TextEditingController();
  String? _selectedGender;
  int?    _selectedClassId;
  bool    _saving = false;

  final _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _guardNameCtrl.dispose();
    _guardPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a class'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiService().post('/students', data: {
        'first_name':    _firstCtrl.text.trim(),
        'last_name':     _lastCtrl.text.trim(),
        'class_id':      _selectedClassId,
        if (_selectedGender != null) 'gender': _selectedGender!.toLowerCase(),
        if (_guardNameCtrl.text.trim().isNotEmpty) 'guardian_name': _guardNameCtrl.text.trim(),
        if (_guardPhoneCtrl.text.trim().isNotEmpty) 'guardian_phone': _guardPhoneCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()} added'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${e.toString().replaceAll('DioException', '').trim()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesListProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('New Student',
                      style: TextStyle(
                          color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 24),

                // First + Last Name
                Row(children: [
                  Expanded(child: _field('First Name', _firstCtrl, required: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('Last Name', _lastCtrl, required: true)),
                ]),
                const SizedBox(height: 14),

                // Class dropdown
                const Text('Class *',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                classesAsync.when(
                  loading: () => const SizedBox(
                    height: 52,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                  ),
                  error: (_, __) => const Text('Failed to load classes',
                      style: TextStyle(color: AppColors.error, fontSize: 13)),
                  data: (classes) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedClassId,
                        hint: const Text('Select class',
                            style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                        isExpanded: true,
                        dropdownColor: AppColors.surface2,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        iconEnabledColor: AppColors.textSecondary,
                        items: classes.map((c) => DropdownMenuItem<int>(
                          value: c['id'] as int,
                          child: Text(c['name']?.toString() ?? ''),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedClassId = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Gender
                const Text('Gender',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                      color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      hint: const Text('Select (optional)',
                          style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                      isExpanded: true,
                      dropdownColor: AppColors.surface2,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      iconEnabledColor: AppColors.textSecondary,
                      items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Guardian
                _field('Guardian Name', _guardNameCtrl),
                const SizedBox(height: 14),
                _field('Guardian Phone', _guardPhoneCtrl,
                    inputType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                const SizedBox(height: 28),

                GradientButton(label: 'Add Student', loading: _saving, onTap: _save),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label${required ? ' *' : ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ]);
  }
}
