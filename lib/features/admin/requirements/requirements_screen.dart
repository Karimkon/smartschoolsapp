import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Data models ───────────────────────────────────────────────────────────────
class _Requirement {
  final String id;
  final String className;
  final String category;
  final String itemName;
  final int quantity;
  final String unit;
  final bool mandatory;
  final double compliancePercent;

  const _Requirement({
    required this.id,
    required this.className,
    required this.category,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.mandatory,
    required this.compliancePercent,
  });
}

class _StudentTracker {
  final String id;
  final String name;
  final String className;
  final double compliancePercent;

  const _StudentTracker({
    required this.id,
    required this.name,
    required this.className,
    required this.compliancePercent,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────
final List<_Requirement> _mockRequirements = [
  // Grade 1
  const _Requirement(id: 'r1', className: 'Grade 1A', category: 'Stationery',      itemName: 'Exercise Books',   quantity: 5,  unit: 'pieces', mandatory: true,  compliancePercent: 92),
  const _Requirement(id: 'r2', className: 'Grade 1A', category: 'Uniform',         itemName: 'School Shirt',     quantity: 2,  unit: 'pieces', mandatory: true,  compliancePercent: 88),
  // Grade 2
  const _Requirement(id: 'r3', className: 'Grade 2B', category: 'Cleaning & Hygiene', itemName: 'Hand Sanitizer', quantity: 1, unit: 'pieces', mandatory: true,  compliancePercent: 75),
  const _Requirement(id: 'r4', className: 'Grade 2B', category: 'Stationery',      itemName: 'Ruler & Compass',  quantity: 1,  unit: 'sets',   mandatory: false, compliancePercent: 60),
  // Grade 3
  const _Requirement(id: 'r5', className: 'Grade 3C', category: 'Uniform',         itemName: 'PE Kit',           quantity: 1,  unit: 'sets',   mandatory: true,  compliancePercent: 45),
  const _Requirement(id: 'r6', className: 'Grade 3C', category: 'Cleaning & Hygiene', itemName: 'Face Towel',    quantity: 2,  unit: 'pieces', mandatory: false, compliancePercent: 80),
];

final List<_StudentTracker> _mockStudents = [
  const _StudentTracker(id: 's1', name: 'Alice Johnson',    className: 'Grade 1A', compliancePercent: 95),
  const _StudentTracker(id: 's2', name: 'Bob Mutua',        className: 'Grade 1A', compliancePercent: 82),
  const _StudentTracker(id: 's3', name: 'Carol Wambui',     className: 'Grade 2B', compliancePercent: 48),
  const _StudentTracker(id: 's4', name: 'David Ochieng',    className: 'Grade 2B', compliancePercent: 70),
  const _StudentTracker(id: 's5', name: 'Eve Kamau',        className: 'Grade 3C', compliancePercent: 30),
  const _StudentTracker(id: 's6', name: 'Frank Njoroge',    className: 'Grade 3C', compliancePercent: 90),
  const _StudentTracker(id: 's7', name: 'Grace Atieno',     className: 'Grade 1A', compliancePercent: 100),
  const _StudentTracker(id: 's8', name: 'Henry Mwangi',     className: 'Grade 2B', compliancePercent: 55),
];

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

const List<String> _classes = ['Grade 1A', 'Grade 2B', 'Grade 3C'];
const List<String> _categories = [
  'Cleaning & Hygiene', 'Stationery', 'Uniform', 'Other'
];
const List<String> _units = ['pieces', 'pairs', 'sets'];
const List<String> _sessions = ['2025/2026 Term 2', '2025/2026 Term 3', '2026/2027 Term 1'];

// ── Screen ────────────────────────────────────────────────────────────────────
class RequirementsScreen extends StatefulWidget {
  const RequirementsScreen({super.key});

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen>
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

  // ── Computed stats ────────────────────────────────────────────────────────
  int get _itemsDefined => _mockRequirements.length;

  int get _recordsAssigned => _mockStudents.length * _mockRequirements.length ~/ 3;

  int get _fullyCompliant =>
      _mockStudents.where((s) => s.compliancePercent >= 80).length;

  double get _overallCompliance {
    if (_mockStudents.isEmpty) return 0;
    return _mockStudents
            .map((s) => s.compliancePercent)
            .reduce((a, b) => a + b) /
        _mockStudents.length;
  }

  // ── Filtered students ─────────────────────────────────────────────────────
  List<_StudentTracker> get _filteredStudents {
    var list = _mockStudents.where((s) {
      final matchSearch = _studentSearch.isEmpty ||
          s.name.toLowerCase().contains(_studentSearch.toLowerCase());
      final matchClass =
          _classFilter == null || s.className == _classFilter;
      return matchSearch && matchClass;
    }).toList();
    return list;
  }

  // ── Grouped requirements ──────────────────────────────────────────────────
  Map<String, List<_Requirement>> get _grouped {
    final map = <String, List<_Requirement>>{};
    for (final r in _mockRequirements) {
      map.putIfAbsent(r.className, () => []).add(r);
    }
    return map;
  }

  void _showAddRequirement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddRequirementSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Requirements',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _showAddRequirement,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Add',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats row ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _StatMini(
                      label: 'Items\nDefined',
                      value: '$_itemsDefined',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    _StatMini(
                      label: 'Records\nAssigned',
                      value: '$_recordsAssigned',
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    _StatMini(
                      label: 'Fully\nCompliant',
                      value: '$_fullyCompliant',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _StatMini(
                      label: 'Compliance\nRate',
                      value: '${_overallCompliance.toStringAsFixed(0)}%',
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              // ── Tabs ─────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Requirements Setup'),
                      Tab(text: 'Student Tracker'),
                    ],
                  ),
                ),
              ),

              // ── Tab content ──────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _SetupTab(
                      grouped: _grouped,
                      onAdd: _showAddRequirement,
                    ),
                    _TrackerTab(
                      students: _filteredStudents,
                      search: _studentSearch,
                      classFilter: _classFilter,
                      onSearchChanged: (v) =>
                          setState(() => _studentSearch = v),
                      onClassChanged: (v) =>
                          setState(() => _classFilter = v),
                    ),
                  ],
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
  final String label;
  final String value;
  final Color color;

  const _StatMini(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Setup Tab ─────────────────────────────────────────────────────────────────
class _SetupTab extends StatelessWidget {
  final Map<String, List<_Requirement>> grouped;
  final VoidCallback onAdd;

  const _SetupTab({required this.grouped, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        ...grouped.entries.toList().asMap().entries.map((entry) {
          final idx = entry.key;
          final className = entry.value.key;
          final reqs = entry.value.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (idx > 0) const SizedBox(height: 20),
              // Class header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      className,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reqs.length} items',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 12),
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: idx * 80))
                  .fadeIn(duration: 350.ms),
              const SizedBox(height: 8),

              // Requirements list
              ...reqs.asMap().entries.map((re) {
                final ri = re.key;
                final req = re.value;
                final color = _complianceColor(req.compliancePercent);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _categoryIcon(req.category),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  req.itemName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (req.mandatory)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withOpacity(0.12),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Text('Mandatory',
                                        style: TextStyle(
                                            color: AppColors.error,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${req.quantity} ${req.unit} · ${req.category}',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${req.compliancePercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: req.compliancePercent / 100,
                                backgroundColor:
                                    color.withOpacity(0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                                minHeight: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate(
                        delay: Duration(
                            milliseconds: idx * 80 + ri * 50 + 100))
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.1, end: 0, duration: 300.ms);
              }),
            ],
          );
        }),

        const SizedBox(height: 20),
        GradientButton(
          label: '+ Add Requirement',
          onTap: onAdd,
        ),
      ],
    );
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Cleaning & Hygiene':
        return Icons.cleaning_services_rounded;
      case 'Stationery':
        return Icons.edit_rounded;
      case 'Uniform':
        return Icons.checkroom_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }
}

// ── Tracker Tab ───────────────────────────────────────────────────────────────
class _TrackerTab extends StatelessWidget {
  final List<_StudentTracker> students;
  final String search;
  final String? classFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onClassChanged;

  const _TrackerTab({
    required this.students,
    required this.search,
    required this.classFilter,
    required this.onSearchChanged,
    required this.onClassChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  hint: 'Search students...',
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: classFilter,
                    hint: const Text('Class',
                        style: TextStyle(
                            color: AppColors.textHint, fontSize: 13)),
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    iconEnabledColor: AppColors.textSecondary,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All Classes')),
                      ..._classes.map((c) =>
                          DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: onClassChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _Legend(AppColors.success, 'Good (≥80%)'),
              const SizedBox(width: 14),
              _Legend(AppColors.warning, 'Avg (50-79%)'),
              const SizedBox(width: 14),
              _Legend(AppColors.error, 'Poor (<50%)'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: students.isEmpty
              ? const Center(
                  child: Text('No students found',
                      style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) {
                    final s = students[i];
                    final color =
                        _complianceColor(s.compliancePercent);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface1,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: color.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          AvatarWidget(
                            initials: s.name
                                .split(' ')
                                .map((w) => w[0])
                                .take(2)
                                .join(),
                            color: color,
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    )),
                                const SizedBox(height: 2),
                                Text(s.className,
                                    style: const TextStyle(
                                        color: AppColors.textHint,
                                        fontSize: 11)),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        s.compliancePercent / 100,
                                    backgroundColor:
                                        color.withOpacity(0.12),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            color),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${s.compliancePercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                _complianceLabel(
                                    s.compliancePercent),
                                style: TextStyle(
                                  color: color.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                        .animate(delay: Duration(milliseconds: i * 50))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0, duration: 300.ms);
                  },
                ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

// ── Add Requirement Sheet ─────────────────────────────────────────────────────
class _AddRequirementSheet extends StatefulWidget {
  const _AddRequirementSheet();

  @override
  State<_AddRequirementSheet> createState() => _AddRequirementSheetState();
}

class _AddRequirementSheetState extends State<_AddRequirementSheet> {
  final _itemCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  String _selectedClass = _classes.first;
  String _category = _categories.first;
  String _unit = _units.first;
  String _session = _sessions.first;
  bool _mandatory = true;
  bool _saving = false;

  @override
  void dispose() {
    _itemCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_itemCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Requirement added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.checklist_rounded,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Requirement',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Class dropdown
              _FieldLabel('Class'),
              const SizedBox(height: 8),
              _DropdownField<String>(
                value: _selectedClass,
                items: _classes
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedClass = v!),
              ),
              const SizedBox(height: 16),

              // Category
              _FieldLabel('Category'),
              const SizedBox(height: 8),
              _DropdownField<String>(
                value: _category,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),

              // Item name
              _FieldLabel('Item Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _itemCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Exercise Books',
                  hintStyle:
                      const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Qty + Unit
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Quantity'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '1',
                            hintStyle: const TextStyle(
                                color: AppColors.textHint),
                            filled: true,
                            fillColor: AppColors.surface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Unit'),
                        const SizedBox(height: 8),
                        _DropdownField<String>(
                          value: _unit,
                          items: _units
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _unit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Session
              _FieldLabel('Session'),
              const SizedBox(height: 8),
              _DropdownField<String>(
                value: _session,
                items: _sessions
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _session = v!),
              ),
              const SizedBox(height: 16),

              // Mandatory toggle
              GestureDetector(
                onTap: () => setState(() => _mandatory = !_mandatory),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          color: AppColors.textSecondary, size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Mandatory Requirement',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14)),
                      ),
                      Switch(
                        value: _mandatory,
                        onChanged: (v) =>
                            setState(() => _mandatory = v),
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Add Requirement',
                loading: _saving,
                onTap: _save,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );
}

class _DropdownField<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.surface2,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            iconEnabledColor: AppColors.textSecondary,
            items: items,
            onChanged: onChanged,
          ),
        ),
      );
}
