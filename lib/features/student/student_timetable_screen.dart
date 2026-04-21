import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Period {
  final String startTime, endTime, subject, teacher, room;
  final Color color;

  const _Period({
    required this.startTime, required this.endTime, required this.subject,
    required this.teacher, required this.room, required this.color,
  });
}

final _timetableData = {
  'Mon': [
    _Period(startTime: '07:00', endTime: '07:45', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '07:45', endTime: '08:30', subject: 'English',      teacher: 'Ms. Wanjiku',  room: 'Room 05', color: AppColors.roleTeacher),
    _Period(startTime: '08:30', endTime: '09:15', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
    _Period(startTime: '09:15', endTime: '09:30', subject: 'Break',        teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '09:30', endTime: '10:15', subject: 'History',      teacher: 'Ms. Auma',     room: 'Room 08', color: AppColors.warning),
    _Period(startTime: '10:15', endTime: '11:00', subject: 'Kiswahili',    teacher: 'Mr. Mwangi',   room: 'Room 03', color: AppColors.roleAccountant),
    _Period(startTime: '11:00', endTime: '13:00', subject: 'Lunch Break',  teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '13:00', endTime: '13:45', subject: 'Geography',    teacher: 'Ms. Nakato',   room: 'Room 10', color: AppColors.success),
    _Period(startTime: '13:45', endTime: '14:30', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
  ],
  'Tue': [
    _Period(startTime: '07:00', endTime: '07:45', subject: 'English',      teacher: 'Ms. Wanjiku',  room: 'Room 05', color: AppColors.roleTeacher),
    _Period(startTime: '07:45', endTime: '08:30', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
    _Period(startTime: '08:30', endTime: '09:15', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '09:15', endTime: '09:30', subject: 'Break',        teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '09:30', endTime: '10:15', subject: 'Kiswahili',    teacher: 'Mr. Mwangi',   room: 'Room 03', color: AppColors.roleAccountant),
    _Period(startTime: '10:15', endTime: '11:00', subject: 'Geography',    teacher: 'Ms. Nakato',   room: 'Room 10', color: AppColors.success),
    _Period(startTime: '11:00', endTime: '13:00', subject: 'Lunch Break',  teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '13:00', endTime: '13:45', subject: 'History',      teacher: 'Ms. Auma',     room: 'Room 08', color: AppColors.warning),
    _Period(startTime: '13:45', endTime: '14:30', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
  ],
  'Wed': [
    _Period(startTime: '07:00', endTime: '07:45', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
    _Period(startTime: '07:45', endTime: '08:30', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '08:30', endTime: '09:15', subject: 'English',      teacher: 'Ms. Wanjiku',  room: 'Room 05', color: AppColors.roleTeacher),
    _Period(startTime: '09:15', endTime: '09:30', subject: 'Break',        teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '09:30', endTime: '10:15', subject: 'Geography',    teacher: 'Ms. Nakato',   room: 'Room 10', color: AppColors.success),
    _Period(startTime: '10:15', endTime: '11:00', subject: 'History',      teacher: 'Ms. Auma',     room: 'Room 08', color: AppColors.warning),
    _Period(startTime: '11:00', endTime: '13:00', subject: 'Lunch Break',  teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '13:00', endTime: '13:45', subject: 'Kiswahili',    teacher: 'Mr. Mwangi',   room: 'Room 03', color: AppColors.roleAccountant),
    _Period(startTime: '13:45', endTime: '14:30', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
  ],
  'Thu': [
    _Period(startTime: '07:00', endTime: '07:45', subject: 'Kiswahili',    teacher: 'Mr. Mwangi',   room: 'Room 03', color: AppColors.roleAccountant),
    _Period(startTime: '07:45', endTime: '08:30', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '08:30', endTime: '09:15', subject: 'History',      teacher: 'Ms. Auma',     room: 'Room 08', color: AppColors.warning),
    _Period(startTime: '09:15', endTime: '09:30', subject: 'Break',        teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '09:30', endTime: '10:15', subject: 'English',      teacher: 'Ms. Wanjiku',  room: 'Room 05', color: AppColors.roleTeacher),
    _Period(startTime: '10:15', endTime: '11:00', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
    _Period(startTime: '11:00', endTime: '13:00', subject: 'Lunch Break',  teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '13:00', endTime: '13:45', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '13:45', endTime: '14:30', subject: 'Geography',    teacher: 'Ms. Nakato',   room: 'Room 10', color: AppColors.success),
  ],
  'Fri': [
    _Period(startTime: '07:00', endTime: '07:45', subject: 'Geography',    teacher: 'Ms. Nakato',   room: 'Room 10', color: AppColors.success),
    _Period(startTime: '07:45', endTime: '08:30', subject: 'History',      teacher: 'Ms. Auma',     room: 'Room 08', color: AppColors.warning),
    _Period(startTime: '08:30', endTime: '09:15', subject: 'Kiswahili',    teacher: 'Mr. Mwangi',   room: 'Room 03', color: AppColors.roleAccountant),
    _Period(startTime: '09:15', endTime: '09:30', subject: 'Break',        teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '09:30', endTime: '10:15', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
    _Period(startTime: '10:15', endTime: '11:00', subject: 'English',      teacher: 'Ms. Wanjiku',  room: 'Room 05', color: AppColors.roleTeacher),
    _Period(startTime: '11:00', endTime: '13:00', subject: 'Lunch Break',  teacher: '—',            room: '—',       color: AppColors.textHint),
    _Period(startTime: '13:00', endTime: '13:45', subject: 'Mathematics',  teacher: 'Mr. Ochieng',  room: 'Room 12', color: AppColors.primary),
    _Period(startTime: '13:45', endTime: '14:30', subject: 'Science',      teacher: 'Mr. Kariuki',  room: 'Lab 2',   color: AppColors.accent),
  ],
};

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    final todayIdx = (_now.weekday - 1).clamp(0, 4);
    _tabs = TabController(length: 5, vsync: this, initialIndex: todayIdx);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isToday(int i) => i == (_now.weekday - 1).clamp(0, 4);

  bool _isNow(_Period p) {
    final parts = p.startTime.split(':');
    final eParts = p.endTime.split(':');
    final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final end   = int.parse(eParts[0]) * 60 + int.parse(eParts[1]);
    final now   = _now.hour * 60 + _now.minute;
    return now >= start && now < end;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Timetable', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.roleStudent,
          labelColor: AppColors.roleStudent,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: List.generate(5, (i) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_days[i]),
                if (_isToday(i)) ...[
                  const SizedBox(width: 4),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                ],
              ],
            ),
          )),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: TabBarView(
          controller: _tabs,
          children: List.generate(5, (dayIdx) {
            final day     = _days[dayIdx];
            final periods = _timetableData[day] ?? [];
            final isToday = _isToday(dayIdx);

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: periods.length,
              itemBuilder: (_, i) {
                final p       = periods[i];
                final now     = isToday && _isNow(p);
                final isBreak = p.subject == 'Break' || p.subject == 'Lunch Break';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: isBreak
                      ? Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Text(p.startTime, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                            ),
                            Expanded(
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.surface1.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                                ),
                                child: Center(
                                  child: Text(
                                    p.subject,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 52,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.startTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: now ? AppColors.error : AppColors.textHint)),
                                  Text(p.endTime,   style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface1,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: now ? AppColors.error : p.color.withOpacity(0.3),
                                    width: now ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4, height: 48,
                                      decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(p.subject, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.color)),
                                              ),
                                              if (now)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text('NOW', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.w700)),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              const Icon(Icons.person_rounded, size: 11, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(p.teacher, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                              const SizedBox(width: 10),
                                              const Icon(Icons.meeting_room_rounded, size: 11, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(p.room, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.04, end: 0);
              },
            );
          }),
        ),
      ),
    );
  }
}
