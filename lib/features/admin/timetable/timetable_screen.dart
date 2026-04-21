import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Slot {
  final String day, subject, teacher, classGroup, startTime, endTime, room;
  const _Slot({required this.day, required this.subject, required this.teacher, required this.classGroup, required this.startTime, required this.endTime, required this.room});
}

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
const _mockSlots = [
  _Slot(day:'Mon', subject:'Mathematics',  teacher:'Mr. Paul Ochieng',  classGroup:'Grade 8A', startTime:'08:00', endTime:'09:00', room:'Room 3'),
  _Slot(day:'Mon', subject:'English',      teacher:'Ms. Grace Wanjiku', classGroup:'Grade 7B', startTime:'09:00', endTime:'10:00', room:'Room 1'),
  _Slot(day:'Mon', subject:'Science',      teacher:'Mr. James Kariuki', classGroup:'Grade 9A', startTime:'10:30', endTime:'11:30', room:'Lab 1'),
  _Slot(day:'Tue', subject:'History',      teacher:'Ms. Lucy Auma',     classGroup:'Grade 10A',startTime:'08:00', endTime:'09:00', room:'Room 5'),
  _Slot(day:'Tue', subject:'Mathematics',  teacher:'Mr. Paul Ochieng',  classGroup:'Grade 9B', startTime:'09:00', endTime:'10:00', room:'Room 3'),
  _Slot(day:'Tue', subject:'Kiswahili',    teacher:'Mr. David Mwangi',  classGroup:'Grade 7A', startTime:'10:30', endTime:'11:30', room:'Room 2'),
  _Slot(day:'Wed', subject:'Geography',    teacher:'Ms. Agnes Nakato',  classGroup:'Grade 8B', startTime:'08:00', endTime:'09:00', room:'Room 4'),
  _Slot(day:'Wed', subject:'Art & Design', teacher:'Mr. Peter Ssali',   classGroup:'Grade 7A', startTime:'09:00', endTime:'10:00', room:'Art Room'),
  _Slot(day:'Thu', subject:'Chemistry',    teacher:'Ms. Ruth Otieno',   classGroup:'Grade 10A',startTime:'08:00', endTime:'09:00', room:'Lab 2'),
  _Slot(day:'Thu', subject:'English',      teacher:'Ms. Grace Wanjiku', classGroup:'Grade 9A', startTime:'09:00', endTime:'10:00', room:'Room 1'),
  _Slot(day:'Fri', subject:'Mathematics',  teacher:'Mr. Paul Ochieng',  classGroup:'Grade 7B', startTime:'08:00', endTime:'09:00', room:'Room 3'),
  _Slot(day:'Fri', subject:'Science',      teacher:'Mr. James Kariuki', classGroup:'Grade 8A', startTime:'09:00', endTime:'10:00', room:'Lab 1'),
];

class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});
  @override State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _classFilter = 'All';

  final _classes = ['All', 'Grade 7A', 'Grade 7B', 'Grade 8A', 'Grade 8B', 'Grade 9A', 'Grade 9B', 'Grade 10A'];

  @override void initState() { super.initState(); _tabs = TabController(length: _days.length, vsync: this, initialIndex: _todayIndex()); }
  @override void dispose() { _tabs.dispose(); super.dispose(); }

  int _todayIndex() {
    final d = DateTime.now().weekday;
    return d <= 5 ? d - 1 : 0;
  }

  List<_Slot> _slotsForDay(String day) => _mockSlots.where((s) {
    final md = s.day == day;
    final mc = _classFilter == 'All' || s.classGroup == _classFilter;
    return md && mc;
  }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));

  static const _subjectColors = {
    'Mathematics': AppColors.primary,
    'English': AppColors.roleTeacher,
    'Science': AppColors.success,
    'History': AppColors.warning,
    'Kiswahili': AppColors.accent,
    'Geography': Color(0xFF06D6A0),
    'Art & Design': Color(0xFFEC4899),
    'Chemistry': Color(0xFFFF6B35),
  };

  Color _subjectColor(String subject) => _subjectColors[subject] ?? AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Timetable', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () {})],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Class filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,0),
            child: SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: _classes.map((c) {
              final sel = c == _classFilter;
              return Padding(padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(onTap: () => setState(() => _classFilter = c),
                  child: AnimatedContainer(duration: 200.ms,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AppColors.primary : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(c, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ),
                ),
              );
            }).toList())).animate().fadeIn(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _days.map((day) {
                final slots = _slotsForDay(day);
                if (slots.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.event_busy_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  Text('No lessons on $day', style: const TextStyle(color: AppColors.textSecondary)),
                ]));
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16,12,16,80),
                  itemCount: slots.length,
                  itemBuilder: (ctx, i) {
                    final s = slots[i];
                    final color = _subjectColor(s.subject);
                    return Padding(padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(padding: EdgeInsets.zero,
                        child: IntrinsicHeight(child: Row(children: [
                          Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
                          Expanded(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(s.subject, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
                              const SizedBox(height: 3),
                              Text(s.teacher, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.class_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                                Text(s.classGroup, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                const Icon(Icons.room_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                                Text(s.room, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ]),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                child: Column(children: [
                                  Text(s.startTime, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                                  Text(s.endTime, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7))),
                                ]),
                              ),
                            ]),
                          ]))),
                        ])),
                      ),
                    ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                  },
                );
              }).toList(),
            ),
          ),
        ]),
      ),
    );
  }
}
