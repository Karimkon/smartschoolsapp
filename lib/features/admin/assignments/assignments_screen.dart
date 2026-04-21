import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Assignment {
  final int id;
  final String title, subject, className, teacher, dueDate, status;
  final int submitted, total;
  const _Assignment({required this.id, required this.title, required this.subject, required this.className,
    required this.teacher, required this.dueDate, required this.status, required this.submitted, required this.total});
}

const _mockAssignments = [
  _Assignment(id:1, title:'Algebra Chapter 3 Exercises',  subject:'Mathematics', className:'Grade 8A', teacher:'Mr. Paul Ochieng',  dueDate:'Apr 25', status:'Active',    submitted:22, total:35),
  _Assignment(id:2, title:'Essay: Climate Change',         subject:'English',     className:'Grade 9B', teacher:'Ms. Grace Wanjiku', dueDate:'Apr 26', status:'Active',    submitted:18, total:32),
  _Assignment(id:3, title:'Photosynthesis Experiment',     subject:'Science',     className:'Grade 7A', teacher:'Mr. James Kariuki', dueDate:'Apr 28', status:'Active',    submitted:30, total:35),
  _Assignment(id:4, title:'World War II Report',           subject:'History',     className:'Grade 10A',teacher:'Ms. Lucy Auma',     dueDate:'Apr 22', status:'Overdue',   submitted:28, total:34),
  _Assignment(id:5, title:'Insha: Mazingira Yetu',         subject:'Kiswahili',   className:'Grade 7B', teacher:'Mr. David Mwangi',  dueDate:'Apr 18', status:'Completed', submitted:33, total:33),
  _Assignment(id:6, title:'Map Reading Skills',            subject:'Geography',   className:'Grade 8B', teacher:'Ms. Agnes Nakato',  dueDate:'Apr 20', status:'Completed', submitted:30, total:30),
];

class AdminAssignmentsScreen extends StatefulWidget {
  const AdminAssignmentsScreen({super.key});
  @override State<AdminAssignmentsScreen> createState() => _AdminAssignmentsScreenState();
}

class _AdminAssignmentsScreenState extends State<AdminAssignmentsScreen> {
  String _filter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Assignment> get _filtered => _mockAssignments.where((a) {
    final mf = _filter == 'All' || a.status == _filter;
    final mq = _query.isEmpty || a.title.toLowerCase().contains(_query.toLowerCase()) || a.className.toLowerCase().contains(_query.toLowerCase());
    return mf && mq;
  }).toList();

  Color _statusColor(String s) => s == 'Active' ? AppColors.primary : s == 'Overdue' ? AppColors.error : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final assignments = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Assignments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search by title or class...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              Row(children: ['All','Active','Overdue','Completed'].map((f) {
                final sel = f == _filter;
                final color = f == 'Active' ? AppColors.primary : f == 'Overdue' ? AppColors.error : f == 'Completed' ? AppColors.success : AppColors.textSecondary;
                return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: sel ? color : AppColors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? color : Colors.white.withOpacity(0.07))),
                    child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ));
              }).toList()).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(child: assignments.isEmpty
            ? const Center(child: Text('No assignments found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,12,16,80),
                itemCount: assignments.length,
                itemBuilder: (ctx, i) {
                  final a = assignments[i];
                  final pct = a.submitted / a.total;
                  final color = _statusColor(a.status);
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.roleTeacher.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.assignment_rounded, color: AppColors.roleTeacher, size: 22)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${a.subject} · ${a.className}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ])),
                          StatusBadge(label: a.status, color: color),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          const Icon(Icons.person_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                          Text(a.teacher, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const Spacer(),
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                          Text('Due: ${a.dueDate}', style: TextStyle(fontSize: 11, color: a.status == 'Overdue' ? AppColors.error : AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: pct, backgroundColor: AppColors.surface3, valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
                          const SizedBox(width: 10),
                          Text('${a.submitted}/${a.total}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                        ]),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05, end: 0);
                },
              ),
          ),
        ]),
      ),
    );
  }
}
