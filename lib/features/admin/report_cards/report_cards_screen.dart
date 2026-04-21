import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _ReportCard {
  final int id;
  final String studentName, className, term, year, status;
  final double average;
  const _ReportCard({required this.id, required this.studentName, required this.className,
    required this.term, required this.year, required this.status, required this.average});
  String get grade {
    if (average >= 80) return 'A'; if (average >= 65) return 'B';
    if (average >= 50) return 'C'; if (average >= 35) return 'D'; return 'F';
  }
  Color get gradeColor {
    if (average >= 80) return AppColors.success; if (average >= 65) return AppColors.primary;
    if (average >= 50) return AppColors.warning; return AppColors.error;
  }
}

const _mockReports = [
  _ReportCard(id:1, studentName:'Amara Osei',     className:'Grade 7A',  term:'Term 1', year:'2026', status:'Published', average:82.5),
  _ReportCard(id:2, studentName:'Brian Mwangi',   className:'Grade 8B',  term:'Term 1', year:'2026', status:'Published', average:67.3),
  _ReportCard(id:3, studentName:'Chloe Wanjiru',  className:'Grade 8A',  term:'Term 1', year:'2026', status:'Draft',     average:91.0),
  _ReportCard(id:4, studentName:'Diana Kamau',    className:'Grade 7B',  term:'Term 1', year:'2026', status:'Published', average:55.8),
  _ReportCard(id:5, studentName:'Emmanuel Ssali', className:'Grade 10A', term:'Term 1', year:'2026', status:'Published', average:78.2),
  _ReportCard(id:6, studentName:'Fatima Hassan',  className:'Grade 8A',  term:'Term 1', year:'2026', status:'Draft',     average:85.6),
  _ReportCard(id:7, studentName:'George Weru',    className:'Grade 11B', term:'Term 1', year:'2026', status:'Pending',   average:42.1),
];

const _terms = ['All','Term 1','Term 2','Term 3'];
const _classes = ['All','Grade 7A','Grade 7B','Grade 8A','Grade 8B','Grade 9A','Grade 10A','Grade 11B'];

class ReportCardsScreen extends StatefulWidget {
  const ReportCardsScreen({super.key});
  @override State<ReportCardsScreen> createState() => _ReportCardsScreenState();
}

class _ReportCardsScreenState extends State<ReportCardsScreen> {
  String _term = 'All';
  String _class = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_ReportCard> get _filtered => _mockReports.where((r) {
    final mt = _term == 'All' || r.term == _term;
    final mc = _class == 'All' || r.className == _class;
    final mq = _query.isEmpty || r.studentName.toLowerCase().contains(_query.toLowerCase());
    return mt && mc && mq;
  }).toList();

  Color _statusColor(String s) => s == 'Published' ? AppColors.success : s == 'Draft' ? AppColors.warning : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    final reports = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Report Cards', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.publish_rounded, size: 18), label: const Text('Publish All'), style: TextButton.styleFrom(foregroundColor: AppColors.success)),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search student...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _DropSelector('Term', _terms, _term, (v) => setState(() => _term = v))),
                const SizedBox(width: 10),
                Expanded(child: _DropSelector('Class', _classes, _class, (v) => setState(() => _class = v))),
              ]).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16,10,16,4),
            child: Row(children: [
              _ReportStat('Total', '${reports.length}', AppColors.primary),
              const SizedBox(width: 12),
              _ReportStat('Published', '${reports.where((r) => r.status == "Published").length}', AppColors.success),
              const SizedBox(width: 12),
              _ReportStat('Draft', '${reports.where((r) => r.status == "Draft").length}', AppColors.warning),
            ]),
          ),
          Expanded(child: reports.isEmpty
            ? const Center(child: Text('No report cards found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,0,16,80),
                itemCount: reports.length,
                itemBuilder: (ctx, i) {
                  final r = reports[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Container(width: 50, height: 50,
                          decoration: BoxDecoration(color: r.gradeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: r.gradeColor.withOpacity(0.3))),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(r.grade, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: r.gradeColor)),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.studentName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.class_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(r.className, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                            Text('${r.term} ${r.year}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text('Average: ', style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                            Text('${r.average.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: r.gradeColor)),
                          ]),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          StatusBadge(label: r.status, color: _statusColor(r.status)),
                          const SizedBox(height: 8),
                          Row(children: [
                            _IBtn(Icons.remove_red_eye_rounded, AppColors.primary, () {}),
                            const SizedBox(width: 6),
                            _IBtn(Icons.download_rounded, AppColors.success, () {}),
                          ]),
                        ]),
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

class _DropSelector extends StatelessWidget {
  final String label; final List<String> items; final String value; final ValueChanged<String> onChanged;
  const _DropSelector(this.label, this.items, this.value, this.onChanged);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: value, isExpanded: true, dropdownColor: AppColors.surface1,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    )),
  );
}

class _ReportStat extends StatelessWidget {
  final String label, value; final Color color;
  const _ReportStat(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]),
  );
}

class _IBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IBtn(this.icon, this.color, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 15)));
}
