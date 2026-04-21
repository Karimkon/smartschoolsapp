import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class IDCardsScreen extends StatefulWidget {
  const IDCardsScreen({super.key});
  @override State<IDCardsScreen> createState() => _IDCardsScreenState();
}

class _IDCardsScreenState extends State<IDCardsScreen> {
  String _type = 'Student';
  String _class = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  final _students = [
    {'id': 1, 'name': 'Amara Osei',      'admNo': 'ADM-001', 'class': 'Grade 7A', 'printed': true},
    {'id': 2, 'name': 'Brian Mwangi',    'admNo': 'ADM-002', 'class': 'Grade 8B', 'printed': true},
    {'id': 3, 'name': 'Chloe Wanjiru',   'admNo': 'ADM-003', 'class': 'Grade 8A', 'printed': false},
    {'id': 4, 'name': 'Diana Kamau',     'admNo': 'ADM-004', 'class': 'Grade 7B', 'printed': false},
    {'id': 5, 'name': 'Emmanuel Ssali',  'admNo': 'ADM-005', 'class': 'Grade 10A','printed': true},
    {'id': 6, 'name': 'Fatima Hassan',   'admNo': 'ADM-006', 'class': 'Grade 8A', 'printed': false},
    {'id': 7, 'name': 'George Weru',     'admNo': 'ADM-007', 'class': 'Grade 11B','printed': false},
  ];

  final _teachers = [
    {'id': 1, 'name': 'Mr. Paul Ochieng',   'empNo': 'EMP-001', 'dept': 'Sciences',   'printed': true},
    {'id': 2, 'name': 'Ms. Grace Wanjiku',  'empNo': 'EMP-002', 'dept': 'Languages',  'printed': false},
    {'id': 3, 'name': 'Mr. James Kariuki',  'empNo': 'EMP-003', 'dept': 'Sciences',   'printed': true},
    {'id': 4, 'name': 'Ms. Lucy Auma',      'empNo': 'EMP-004', 'dept': 'Humanities', 'printed': false},
  ];

  List<Map<String, dynamic>> get _data => _type == 'Student' ? _students : _teachers;

  List<Map<String, dynamic>> get _filtered => _data.where((p) {
    final mq = _query.isEmpty || (p['name'] as String).toLowerCase().contains(_query.toLowerCase());
    return mq;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final people = _filtered;
    final unprintedCount = _data.where((p) => !(p['printed'] as bool)).length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('ID Cards', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generating ${_selected.length} ID cards...'), backgroundColor: AppColors.primary));
                setState(() => _selected.clear());
              },
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text('Print (${_selected.length})'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              // Type toggle
              Row(children: ['Student', 'Teacher'].map((t) {
                final sel = t == _type;
                return Expanded(child: Padding(padding: EdgeInsets.only(right: t == 'Student' ? 8 : 0),
                  child: GestureDetector(onTap: () => setState(() { _type = t; _selected.clear(); }),
                    child: AnimatedContainer(duration: 200.ms,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: sel ? AppColors.primary : AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(t, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w400))),
                    ),
                  ),
                ));
              }).toList()).animate().fadeIn(),
              const SizedBox(height: 12),
              AppSearchField(hint: 'Search...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate(delay: 100.ms).fadeIn(),
              if (unprintedCount > 0) ...[
                const SizedBox(height: 10),
                GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.info_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('$unprintedCount ID cards not yet printed', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                    GestureDetector(onTap: () => setState(() { for (final p in _data.where((x) => !(x['printed'] as bool))) _selected.add(p['id'] as int); }),
                      child: const Text('Select All', style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                ).animate(delay: 150.ms).fadeIn(),
              ],
            ]),
          ),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16,12,16,80),
            itemCount: people.length,
            itemBuilder: (ctx, i) {
              final p = people[i];
              final id = p['id'] as int;
              final printed = p['printed'] as bool;
              final selected = _selected.contains(id);
              final color = printed ? AppColors.success : AppColors.warning;
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() { selected ? _selected.remove(id) : _selected.add(id); }),
                  child: GlassCard(padding: const EdgeInsets.all(12),
                    color: selected ? AppColors.primary.withOpacity(0.15) : null,
                    child: Row(children: [
                      AnimatedContainer(duration: 200.ms,
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : Colors.transparent,
                          border: Border.all(color: selected ? AppColors.primary : AppColors.textHint, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                      ),
                      const SizedBox(width: 12),
                      AvatarWidget(initials: (p['name'] as String)[0], color: [AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.success][i % 4], size: 42),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Text(p.containsKey('admNo') ? p['admNo'] as String : p['empNo'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(width: 8),
                          Text(p.containsKey('class') ? p['class'] as String : p['dept'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ]),
                      ])),
                      StatusBadge(label: printed ? 'Printed' : 'Pending', color: color),
                    ]),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
            },
          )),
        ]),
      ),
    );
  }
}
