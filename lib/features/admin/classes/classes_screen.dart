import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _ClassItem {
  final int id;
  final String name, teacher, section, stream;
  final int students, capacity;
  const _ClassItem({required this.id, required this.name, required this.teacher,
    required this.section, required this.stream, required this.students, required this.capacity});
}

const _mockClasses = [
  _ClassItem(id:1, name:'Grade 7A', teacher:'Mr. Paul Ochieng',  section:'Primary',   stream:'Science', students:35, capacity:40),
  _ClassItem(id:2, name:'Grade 7B', teacher:'Ms. Grace Wanjiku', section:'Primary',   stream:'Arts',    students:33, capacity:40),
  _ClassItem(id:3, name:'Grade 8A', teacher:'Mr. James Kariuki', section:'Secondary', stream:'Science', students:38, capacity:40),
  _ClassItem(id:4, name:'Grade 8B', teacher:'Ms. Lucy Auma',     section:'Secondary', stream:'Arts',    students:30, capacity:40),
  _ClassItem(id:5, name:'Grade 9A', teacher:'Mr. David Mwangi',  section:'Secondary', stream:'Science', students:36, capacity:40),
  _ClassItem(id:6, name:'Grade 9B', teacher:'Ms. Agnes Nakato',  section:'Secondary', stream:'Arts',    students:32, capacity:40),
  _ClassItem(id:7, name:'Grade 10A',teacher:'Mr. Peter Ssali',   section:'Secondary', stream:'Science', students:34, capacity:40),
  _ClassItem(id:8, name:'Grade 10B',teacher:'Ms. Ruth Otieno',   section:'Secondary', stream:'Arts',    students:29, capacity:40),
];

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});
  @override State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _searchCtrl = TextEditingController();
  String _section = 'All';
  String _query = '';

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_ClassItem> get _filtered => _mockClasses.where((c) {
    final ms = _section == 'All' || c.section == _section;
    final mq = _query.isEmpty || c.name.toLowerCase().contains(_query.toLowerCase()) || c.teacher.toLowerCase().contains(_query.toLowerCase());
    return ms && mq;
  }).toList();

  @override
  Widget build(BuildContext context) {
    final classes = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Row(children: [
          const Text('Classes', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${_mockClasses.length}', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search class or teacher...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              Row(children: ['All','Primary','Secondary'].map((s) {
                final sel = s == _section;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(onTap: () => setState(() => _section = s),
                    child: AnimatedContainer(duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(s, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList()).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16,10,16,4),
            child: Row(children: [Text('${classes.length} class${classes.length != 1 ? "es" : ""}', style: const TextStyle(fontSize: 12, color: AppColors.textHint))]),
          ),
          Expanded(child: classes.isEmpty
            ? const Center(child: Text('No classes found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,0,16,80),
                itemCount: classes.length,
                itemBuilder: (ctx, i) {
                  final c = classes[i];
                  final pct = (c.students / c.capacity * 100).round();
                  final color = [AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.success][i % 4];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Container(width: 52, height: 52,
                          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(c.name.split(' ').last, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Text(c.teacher, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.people_rounded, size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text('${c.students}/${c.capacity} students', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 10),
                            StatusBadge(label: c.stream, color: AppColors.accent),
                          ]),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.students / c.capacity,
                              backgroundColor: AppColors.surface3,
                              valueColor: AlwaysStoppedAnimation(pct > 90 ? AppColors.warning : AppColors.success),
                              minHeight: 4,
                            ),
                          ),
                        ])),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                          child: Text('$pct%', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
          ),
        ]),
      ),
    );
  }
}
