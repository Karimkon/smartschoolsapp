import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _DisciplinaryCase {
  final int id;
  final String studentName, className, offence, reportedBy, date, status, action;
  const _DisciplinaryCase({required this.id, required this.studentName, required this.className,
    required this.offence, required this.reportedBy, required this.date, required this.status, required this.action});
}

const _mockCases = [
  _DisciplinaryCase(id:1, studentName:'George Weru',    className:'Grade 11B', offence:'Truancy',          reportedBy:'Mr. Paul Ochieng',  date:'Apr 18', status:'Resolved',   action:'Parents called'),
  _DisciplinaryCase(id:2, studentName:'Diana Kamau',    className:'Grade 7B',  offence:'Bullying',         reportedBy:'Ms. Grace Wanjiku', date:'Apr 19', status:'Pending',    action:'Under review'),
  _DisciplinaryCase(id:3, studentName:'Brian Mwangi',   className:'Grade 8B',  offence:'Damage to property',reportedBy:'Mr. James Kariuki',date:'Apr 20', status:'Pending',    action:'Parent meeting scheduled'),
  _DisciplinaryCase(id:4, studentName:'Chloe Wanjiru',  className:'Grade 8A',  offence:'Cheating in exam', reportedBy:'Ms. Lucy Auma',     date:'Apr 15', status:'Resolved',   action:'Marks deducted'),
  _DisciplinaryCase(id:5, studentName:'Emmanuel Ssali', className:'Grade 10A', offence:'Fighting',         reportedBy:'Mr. David Mwangi',  date:'Apr 12', status:'Escalated',  action:'Suspended 3 days'),
  _DisciplinaryCase(id:6, studentName:'Fatima Hassan',  className:'Grade 8A',  offence:'Uniform violation',reportedBy:'Ms. Agnes Nakato',  date:'Apr 21', status:'Pending',    action:'Warning issued'),
];

class DisciplinaryScreen extends StatefulWidget {
  const DisciplinaryScreen({super.key});
  @override State<DisciplinaryScreen> createState() => _DisciplinaryScreenState();
}

class _DisciplinaryScreenState extends State<DisciplinaryScreen> {
  String _filter = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_DisciplinaryCase> get _filtered => _mockCases.where((c) {
    final mf = _filter == 'All' || c.status == _filter;
    final mq = _query.isEmpty || c.studentName.toLowerCase().contains(_query.toLowerCase()) || c.offence.toLowerCase().contains(_query.toLowerCase());
    return mf && mq;
  }).toList();

  Color _statusColor(String s) => s == 'Resolved' ? AppColors.success : s == 'Pending' ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final cases = _filtered;
    final pending   = _mockCases.where((c) => c.status == 'Pending').length;
    final escalated = _mockCases.where((c) => c.status == 'Escalated').length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Disciplinary', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            // Stats
            Row(children: [
              Expanded(child: _QuickStat('Total Cases', '${_mockCases.length}', AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _QuickStat('Pending', '$pending', AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _QuickStat('Escalated', '$escalated', AppColors.error)),
            ]).animate().fadeIn(),
            const SizedBox(height: 12),
            AppSearchField(hint: 'Search student or offence...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 12),
            Row(children: ['All','Pending','Resolved','Escalated'].map((f) {
              final sel = f == _filter;
              final color = _statusColor(f == 'All' ? 'Resolved' : f);
              return Padding(padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(onTap: () => setState(() => _filter = f),
                  child: AnimatedContainer(duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: sel ? color : AppColors.surface2, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? color : Colors.white.withOpacity(0.07))),
                    child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              );
            }).toList()).animate(delay: 150.ms).fadeIn(),
          ])),
          Expanded(child: cases.isEmpty
            ? const Center(child: Text('No cases found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,0,16,80),
                itemCount: cases.length,
                itemBuilder: (ctx, i) {
                  final c = cases[i];
                  final color = _statusColor(c.status);
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: EdgeInsets.zero,
                      child: IntrinsicHeight(child: Row(children: [
                        Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
                        Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.studentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              Text(c.className, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ])),
                            StatusBadge(label: c.status, color: color),
                          ]),
                          const SizedBox(height: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Icon(Icons.gavel_rounded, size: 14, color: color),
                              const SizedBox(width: 6),
                              Expanded(child: Text(c.offence, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
                            ])),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.person_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(c.reportedBy, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const Spacer(),
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(c.date, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                          ]),
                          if (c.action.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(children: [
                              const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                              Expanded(child: Text(c.action, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                            ]),
                          ],
                        ]))),
                      ])),
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

class _QuickStat extends StatelessWidget {
  final String label, value; final Color color;
  const _QuickStat(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => GlassCard(padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  );
}
