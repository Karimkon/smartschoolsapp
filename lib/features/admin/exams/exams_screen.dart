import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Exam {
  final int id;
  final String title, subject, className, date, startTime, endTime, room, status;
  const _Exam({required this.id, required this.title, required this.subject,
    required this.className, required this.date, required this.startTime,
    required this.endTime, required this.room, required this.status});
}

const _mockExams = [
  _Exam(id:1, title:'Mid-Term Mathematics', subject:'Mathematics', className:'Grade 8A', date:'2026-04-25', startTime:'08:00', endTime:'10:00', room:'Hall A', status:'Upcoming'),
  _Exam(id:2, title:'End of Term Science',  subject:'Science',     className:'Grade 7A', date:'2026-04-26', startTime:'10:30', endTime:'12:30', room:'Hall B', status:'Upcoming'),
  _Exam(id:3, title:'English Literature',   subject:'English',     className:'Grade 9A', date:'2026-04-27', startTime:'08:00', endTime:'10:00', room:'Hall A', status:'Upcoming'),
  _Exam(id:4, title:'History CAT',          subject:'History',     className:'Grade 10A',date:'2026-04-28', startTime:'14:00', endTime:'15:30', room:'Class 3B',status:'Upcoming'),
  _Exam(id:5, title:'Mid-Term Science',     subject:'Science',     className:'Grade 9B', date:'2026-04-14', startTime:'08:00', endTime:'10:00', room:'Hall A', status:'Completed'),
  _Exam(id:6, title:'Maths CAT 1',          subject:'Mathematics', className:'Grade 7B', date:'2026-04-10', startTime:'10:00', endTime:'11:00', room:'Class 2A',status:'Completed'),
];

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});
  @override State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String _filter = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Exam> get _filtered => _mockExams.where((e) {
    final mf = _filter == 'All' || e.status == _filter;
    final mq = _query.isEmpty || e.title.toLowerCase().contains(_query.toLowerCase()) ||
        e.subject.toLowerCase().contains(_query.toLowerCase()) || e.className.toLowerCase().contains(_query.toLowerCase());
    return mf && mq;
  }).toList();

  Color _statusColor(String s) => s == 'Upcoming' ? AppColors.warning : s == 'Ongoing' ? AppColors.success : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    final exams = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Exam Schedules', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
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
              AppSearchField(hint: 'Search exam, subject, class...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              Row(children: ['All','Upcoming','Ongoing','Completed'].map((f) {
                final sel = f == _filter;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.warning : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.warning : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList()).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(child: exams.isEmpty
            ? const Center(child: Text('No exams found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,12,16,80),
                itemCount: exams.length,
                itemBuilder: (ctx, i) {
                  final e = exams[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(width: 44, height: 44,
                            decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.quiz_rounded, color: AppColors.warning, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(e.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('${e.subject} · ${e.className}', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                          ])),
                          StatusBadge(label: e.status, color: _statusColor(e.status)),
                        ]),
                        const SizedBox(height: 12),
                        Container(padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            _InfoChip(Icons.calendar_today_rounded, e.date),
                            const SizedBox(width: 16),
                            _InfoChip(Icons.access_time_rounded, '${e.startTime} – ${e.endTime}'),
                            const SizedBox(width: 16),
                            _InfoChip(Icons.room_rounded, e.room),
                          ]),
                        ),
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

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label;
  const _InfoChip(this.icon, this.label);
  @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.textHint),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}
