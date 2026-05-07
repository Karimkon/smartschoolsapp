import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _Req {
  final int id;
  final int? classId;
  final String className;
  final String itemName;
  final String category;
  final double quantity;
  final String unit;
  final bool mandatory;
  final double compliancePct;

  const _Req({
    required this.id,
    required this.classId,
    required this.className,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.mandatory,
    required this.compliancePct,
  });

  factory _Req.fromMap(Map m) => _Req(
    id:            m['id'] as int,
    classId:       m['class_id'] as int?,
    className:     m['class_name']?.toString() ?? 'All Classes',
    itemName:      m['name']?.toString() ?? '',
    category:      m['category']?.toString() ?? 'general',
    quantity:      _n(m['quantity']),
    unit:          m['unit']?.toString() ?? 'piece',
    mandatory:     m['is_mandatory'] == true || m['is_mandatory'] == 1,
    compliancePct: _n(m['compliance_percent']),
  );
}

class _StudentTracker {
  final int id;
  final String name;
  final String className;
  final double compliancePct;

  const _StudentTracker({
    required this.id,
    required this.name,
    required this.className,
    required this.compliancePct,
  });

  factory _StudentTracker.fromMap(Map m) => _StudentTracker(
    id:            m['id'] as int,
    name:          m['name']?.toString() ?? '',
    className:     m['class_name']?.toString() ?? '—',
    compliancePct: _n(m['compliance_percent']),
  );
}

double _n(dynamic v) =>
    v == null ? 0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

// ── Providers ─────────────────────────────────────────────────────────────────

final requirementsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/requirements');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _complianceColor(double pct) {
  if (pct >= 80) return AppColors.success;
  if (pct >= 50) return AppColors.warning;
  return AppColors.error;
}

String _complianceLabel(double pct) {
  if (pct >= 80) return 'Good';
  if (pct >= 50) return 'Average';
  return 'Poor';
}

const List<String> _categories = ['Cleaning & Hygiene', 'Stationery', 'Uniform', 'Other'];
const List<String> _units = ['pieces', 'pairs', 'sets', 'bottles', 'books'];

// ── Screen ────────────────────────────────────────────────────────────────────

class RequirementsScreen extends ConsumerStatefulWidget {
  const RequirementsScreen({super.key});
  @override ConsumerState<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends ConsumerState<RequirementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _studentSearch = '';
  String? _classFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAdd(List<Map> classes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSheet(
        classes: classes,
        onSaved: () => ref.invalidate(requirementsProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(requirementsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text('Requirements', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    async.whenOrNull(data: (d) {
                      final classes = (d['requirements'] as List? ?? [])
                          .map((r) => {'id': (r as Map)['class_id'], 'name': r['class_name']})
                          .where((c) => c['id'] != null)
                          .toSet()
                          .toList()
                          .cast<Map>();
                      return GestureDetector(
                        onTap: () => _showAdd(classes),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                        ),
                      );
                    }) ?? const SizedBox(),
                  ],
                ),
              ),

              // Stats
              async.when(
                loading: () => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(children: List.generate(4, (_) => Expanded(child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: const ShimmerCard(height: 60),
                  )))),
                ),
                error: (_, __) => const SizedBox(),
                data: (d) {
                  final s = d['stats'] as Map? ?? {};
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(children: [
                      _StatMini('Items\nDefined',    '${s['items_defined'] ?? 0}',    AppColors.primary),
                      const SizedBox(width: 10),
                      _StatMini('Records\nAssigned', '${s['records_assigned'] ?? 0}', AppColors.accent),
                      const SizedBox(width: 10),
                      _StatMini('Fully\nCompliant',  '${s['fully_compliant'] ?? 0}',  AppColors.success),
                      const SizedBox(width: 10),
                      _StatMini('Compliance\nRate',  '${s['overall_compliance'] ?? 0}%', AppColors.warning),
                    ]),
                  ).animate().fadeIn(duration: 400.ms);
                },
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
                    indicatorPadding: const EdgeInsets.all(4),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [Tab(text: 'Requirements Setup'), Tab(text: 'Student Tracker')],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: async.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load requirements', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => ref.invalidate(requirementsProvider), child: const Text('Retry')),
                  ])),
                  data: (d) {
                    final reqs = (d['requirements'] as List? ?? []).map((r) => _Req.fromMap(r as Map)).toList();
                    final students = (d['students'] as List? ?? []).map((s) => _StudentTracker.fromMap(s as Map)).toList();

                    // Grouped requirements by class name
                    final grouped = <String, List<_Req>>{};
                    for (final r in reqs) grouped.putIfAbsent(r.className, () => []).add(r);

                    // Filtered students
                    final filtered = students.where((s) {
                      final matchSearch = _studentSearch.isEmpty || s.name.toLowerCase().contains(_studentSearch.toLowerCase());
                      final matchClass  = _classFilter == null || s.className == _classFilter;
                      return matchSearch && matchClass;
                    }).toList();

                    final classNames = students.map((s) => s.className).toSet().toList()..sort();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _SetupTab(grouped: grouped),
                        _TrackerTab(
                          students: filtered,
                          search: _studentSearch,
                          classFilter: _classFilter,
                          classNames: classNames,
                          onSearchChanged: (v) => setState(() => _studentSearch = v),
                          onClassChanged:  (v) => setState(() => _classFilter = v),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────

class _StatMini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatMini(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w500, height: 1.3)),
      ]),
    ),
  );
}

// ── Setup Tab ─────────────────────────────────────────────────────────────────

class _SetupTab extends StatelessWidget {
  final Map<String, List<_Req>> grouped;
  const _SetupTab({required this.grouped});

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return const Center(child: Text('No requirements defined yet.\nTap "Add" to create one.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: grouped.entries.toList().asMap().entries.map((entry) {
        final idx       = entry.key;
        final className = entry.value.key;
        final reqs      = entry.value.value;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (idx > 0) const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.class_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(className, style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${reqs.length} items', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            ]),
          ).animate(delay: Duration(milliseconds: idx * 80)).fadeIn(duration: 350.ms),
          const SizedBox(height: 8),
          ...reqs.asMap().entries.map((re) {
            final ri  = re.key;
            final req = re.value;
            final col = _complianceColor(req.compliancePct);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface1,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                  child: Icon(_categoryIcon(req.category), size: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(req.itemName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    if (req.mandatory) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Mandatory', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 3),
                  Text('${req.quantity.toInt()} ${req.unit} · ${req.category}',
                      style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${req.compliancePct.toStringAsFixed(0)}%',
                      style: TextStyle(color: col, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  SizedBox(width: 50, child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: req.compliancePct / 100,
                      backgroundColor: col.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(col),
                      minHeight: 5,
                    ),
                  )),
                ]),
              ]),
            ).animate(delay: Duration(milliseconds: idx * 80 + ri * 50 + 100)).fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0, duration: 300.ms);
          }),
        ]);
      }).toList(),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'cleaning & hygiene': return Icons.cleaning_services_rounded;
      case 'stationery':         return Icons.edit_rounded;
      case 'uniform':            return Icons.checkroom_rounded;
      default:                   return Icons.checklist_rounded;
    }
  }
}

// ── Tracker Tab ───────────────────────────────────────────────────────────────

class _TrackerTab extends StatelessWidget {
  final List<_StudentTracker> students;
  final String search;
  final String? classFilter;
  final List<String> classNames;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onClassChanged;

  const _TrackerTab({
    required this.students,
    required this.search,
    required this.classFilter,
    required this.classNames,
    required this.onSearchChanged,
    required this.onClassChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(children: [
          Expanded(child: AppSearchField(hint: 'Search students...', onChanged: onSearchChanged)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String?>(
              value: classFilter,
              hint: const Text('Class', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
              dropdownColor: AppColors.surface2,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              iconEnabledColor: AppColors.textSecondary,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('All Classes')),
                ...classNames.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              ],
              onChanged: onClassChanged,
            )),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _Legend(AppColors.success, 'Good (≥80%)'),
          const SizedBox(width: 14),
          _Legend(AppColors.warning, 'Avg (50-79%)'),
          const SizedBox(width: 14),
          _Legend(AppColors.error, 'Poor (<50%)'),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: students.isEmpty
            ? const Center(child: Text('No students found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: students.length,
                itemBuilder: (_, i) {
                  final s   = students[i];
                  final col = _complianceColor(s.compliancePct);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface1,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: col.withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      AvatarWidget(
                        initials: s.name.split(' ').map((w) => w.isEmpty ? '' : w[0]).take(2).join(),
                        color: col, size: 40,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(s.className, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: s.compliancePct / 100,
                            backgroundColor: col.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(col),
                            minHeight: 5,
                          ),
                        ),
                      ])),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('${s.compliancePct.toStringAsFixed(0)}%',
                            style: TextStyle(color: col, fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(_complianceLabel(s.compliancePct),
                            style: TextStyle(color: col.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                    ]),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
                },
              ),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 10, fontWeight: FontWeight.w500)),
  ]);
}

// ── Add Requirement Sheet ─────────────────────────────────────────────────────

class _AddSheet extends ConsumerStatefulWidget {
  final List<Map> classes;
  final VoidCallback onSaved;
  const _AddSheet({required this.classes, required this.onSaved});
  @override ConsumerState<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends ConsumerState<_AddSheet> {
  final _itemCtrl = TextEditingController();
  final _qtyCtrl  = TextEditingController(text: '1');
  int?   _classId;
  String _category  = _categories.first;
  String _unit      = _units.first;
  bool   _mandatory = true;
  bool   _saving    = false;

  @override void dispose() { _itemCtrl.dispose(); _qtyCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_itemCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService().post('/requirements', data: {
        'class_id':     _classId,
        'name':         _itemCtrl.text.trim(),
        'category':     _category,
        'quantity':     double.tryParse(_qtyCtrl.text) ?? 1,
        'unit':         _unit,
        'is_mandatory': _mandatory,
      });
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Requirement added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed: ${e.toString().split(':').last.trim()}'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.checklist_rounded, color: AppColors.warning, size: 22)),
            const SizedBox(width: 12),
            const Text('Add Requirement', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 24),

          // Class
          const Text('Class', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _Dropdown<int?>(
            value: _classId,
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All Classes')),
              ...widget.classes.map((c) => DropdownMenuItem<int?>(value: c['id'] as int?, child: Text(c['name']?.toString() ?? ''))),
            ],
            onChanged: (v) => setState(() => _classId = v),
          ),
          const SizedBox(height: 16),

          // Category
          const Text('Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _Dropdown<String>(
            value: _category,
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 16),

          // Item name
          const Text('Item Name', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _itemCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Exercise Books',
              hintStyle: const TextStyle(color: AppColors.textHint),
              filled: true, fillColor: AppColors.surface2,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Qty + Unit
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Quantity', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '1', hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true, fillColor: AppColors.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Unit', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _Dropdown<String>(
                value: _unit,
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ])),
          ]),
          const SizedBox(height: 16),

          // Mandatory toggle
          GestureDetector(
            onTap: () => setState(() => _mandatory = !_mandatory),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.flag_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                const Expanded(child: Text('Mandatory Requirement', style: TextStyle(color: AppColors.textPrimary, fontSize: 14))),
                Switch(value: _mandatory, onChanged: (v) => setState(() => _mandatory = v),
                    activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ]),
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Add Requirement', loading: _saving, onTap: _save),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
    child: DropdownButtonHideUnderline(child: DropdownButton<T>(
      value: value, isExpanded: true, dropdownColor: AppColors.surface2,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      iconEnabledColor: AppColors.textSecondary,
      items: items, onChanged: onChanged,
    )),
  );
}
