import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Period {
  final String time, subject, className, room;
  final Color color;
  const _Period({required this.time, required this.subject, required this.className, required this.room, required this.color});
}

const _subjectColors = {
  'Mathematics': AppColors.primary,
  'English':     AppColors.roleTeacher,
  'Science':     AppColors.accent,
  'History':     AppColors.warning,
  'Kiswahili':   AppColors.roleAccountant,
  'Geography':   AppColors.success,
  'Free':        AppColors.textHint,
};

final _timetableData = {
  'Mon': [
    _Period(time: '07:00', subject: 'Mathematics', className: 'Grade 8A', room: 'Room 12', color: AppColors.primary),
    _Period(time: '07:45', subject: 'Mathematics', className: 'Grade 9B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '08:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '09:15', subject: 'Mathematics', className: 'Grade 7A', room: 'Room 05', color: AppColors.primary),
    _Period(time: '10:00', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '10:45', subject: 'Mathematics', className: 'Grade 10A',room: 'Room 14', color: AppColors.primary),
    _Period(time: '11:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '13:00', subject: 'Mathematics', className: 'Grade 8B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '13:45', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '14:30', subject: 'Mathematics', className: 'Grade 9A', room: 'Room 08', color: AppColors.primary),
  ],
  'Tue': [
    _Period(time: '07:00', subject: 'Mathematics', className: 'Grade 9A', room: 'Room 08', color: AppColors.primary),
    _Period(time: '07:45', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '08:30', subject: 'Mathematics', className: 'Grade 10A',room: 'Room 14', color: AppColors.primary),
    _Period(time: '09:15', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '10:00', subject: 'Mathematics', className: 'Grade 7A', room: 'Room 05', color: AppColors.primary),
    _Period(time: '10:45', subject: 'Mathematics', className: 'Grade 8A', room: 'Room 12', color: AppColors.primary),
    _Period(time: '11:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '13:00', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '13:45', subject: 'Mathematics', className: 'Grade 9B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '14:30', subject: 'Mathematics', className: 'Grade 8B', room: 'Room 12', color: AppColors.primary),
  ],
  'Wed': [
    _Period(time: '07:00', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '07:45', subject: 'Mathematics', className: 'Grade 8A', room: 'Room 12', color: AppColors.primary),
    _Period(time: '08:30', subject: 'Mathematics', className: 'Grade 7A', room: 'Room 05', color: AppColors.primary),
    _Period(time: '09:15', subject: 'Mathematics', className: 'Grade 9A', room: 'Room 08', color: AppColors.primary),
    _Period(time: '10:00', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '10:45', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '11:30', subject: 'Mathematics', className: 'Grade 10A',room: 'Room 14', color: AppColors.primary),
    _Period(time: '13:00', subject: 'Mathematics', className: 'Grade 8B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '13:45', subject: 'Mathematics', className: 'Grade 9B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '14:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
  ],
  'Thu': [
    _Period(time: '07:00', subject: 'Mathematics', className: 'Grade 7A', room: 'Room 05', color: AppColors.primary),
    _Period(time: '07:45', subject: 'Mathematics', className: 'Grade 9B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '08:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '09:15', subject: 'Mathematics', className: 'Grade 8B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '10:00', subject: 'Mathematics', className: 'Grade 10A',room: 'Room 14', color: AppColors.primary),
    _Period(time: '10:45', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '11:30', subject: 'Mathematics', className: 'Grade 8A', room: 'Room 12', color: AppColors.primary),
    _Period(time: '13:00', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '13:45', subject: 'Mathematics', className: 'Grade 9A', room: 'Room 08', color: AppColors.primary),
    _Period(time: '14:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
  ],
  'Fri': [
    _Period(time: '07:00', subject: 'Mathematics', className: 'Grade 8A', room: 'Room 12', color: AppColors.primary),
    _Period(time: '07:45', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '08:30', subject: 'Mathematics', className: 'Grade 9B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '09:15', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '10:00', subject: 'Mathematics', className: 'Grade 7A', room: 'Room 05', color: AppColors.primary),
    _Period(time: '10:45', subject: 'Mathematics', className: 'Grade 8B', room: 'Room 12', color: AppColors.primary),
    _Period(time: '11:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
    _Period(time: '13:00', subject: 'Mathematics', className: 'Grade 9A', room: 'Room 08', color: AppColors.primary),
    _Period(time: '13:45', subject: 'Mathematics', className: 'Grade 10A',room: 'Room 14', color: AppColors.primary),
    _Period(time: '14:30', subject: 'Free',         className: '—',        room: '—',       color: AppColors.textHint),
  ],
};

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherTimetableScreen extends StatefulWidget {
  const TeacherTimetableScreen({super.key});

  @override
  State<TeacherTimetableScreen> createState() => _TeacherTimetableScreenState();
}

class _TeacherTimetableScreenState extends State<TeacherTimetableScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Default to today's weekday (Mon=0 ... Fri=4)
    final todayIdx = (_now.weekday - 1).clamp(0, 4);
    _tabs = TabController(length: 5, vsync: this, initialIndex: todayIdx);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isToday(int tabIndex) => tabIndex == (_now.weekday - 1).clamp(0, 4);

  String _currentTimeStr() {
    return '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
  }

  bool _isCurrentPeriod(_Period p) {
    final pHour   = int.parse(p.time.split(':')[0]);
    final pMinute = int.parse(p.time.split(':')[1]);
    final pStart  = pHour * 60 + pMinute;
    final pEnd    = pStart + 45;
    final nowMin  = _now.hour * 60 + _now.minute;
    return nowMin >= pStart && nowMin < pEnd;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_currentTimeStr(), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: List.generate(5, (i) => Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_days[i]),
                if (_isToday(i)) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
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
            final dayKey  = _days[dayIdx];
            final periods = _timetableData[dayKey] ?? [];
            final isToday = _isToday(dayIdx);

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: periods.length,
              itemBuilder: (_, i) {
                final p       = periods[i];
                final current = isToday && _isCurrentPeriod(p);
                final isFree  = p.subject == 'Free';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Time column
                      SizedBox(
                        width: 48,
                        child: Text(
                          p.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: current ? AppColors.error : AppColors.textHint,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Period card
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isFree
                                ? AppColors.surface1.withOpacity(0.4)
                                : AppColors.surface1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: current
                                  ? AppColors.error
                                  : isFree
                                      ? Colors.white.withOpacity(0.04)
                                      : p.color.withOpacity(0.3),
                              width: current ? 1.5 : 1,
                            ),
                          ),
                          child: isFree
                              ? Row(
                                  children: [
                                    Container(
                                      width: 4, height: 36,
                                      decoration: BoxDecoration(color: AppColors.textHint.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Free Period', style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic)),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 4, height: 44,
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
                                              if (current)
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
                                              const Icon(Icons.people_rounded, size: 11, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(p.className, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
