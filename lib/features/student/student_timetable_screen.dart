import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final studentTimetableProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/timetable');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentTimetableScreen extends ConsumerStatefulWidget {
  const StudentTimetableScreen({super.key});

  @override
  ConsumerState<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends ConsumerState<StudentTimetableScreen> {
  String _selectedDay = '';

  static const _days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  static const _subjectColors = [
    AppColors.primary, AppColors.roleTeacher, AppColors.accent,
    AppColors.warning, AppColors.roleAccountant, AppColors.success,
    AppColors.error, AppColors.roleParent,
  ];

  Color _colorForSubject(String subject, Map<String, Color> cache) {
    if (!cache.containsKey(subject)) {
      cache[subject] = _subjectColors[cache.length % _subjectColors.length];
    }
    return cache[subject]!;
  }

  String _todayKey() {
    final names = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return names[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentTimetableProvider);

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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(studentTimetableProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ShimmerCard(height: 48),
              const SizedBox(height: 16),
              ...List.generate(6, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ShimmerCard(height: 72),
              )),
            ],
          ),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
              const SizedBox(height: 12),
              const Text('Could not load timetable', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(studentTimetableProvider),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (d) {
            final timetable = d['timetable'] as Map? ?? {};

            // Find available days
            final available = _days.where((day) {
              final slots = timetable[day];
              return slots is List && slots.isNotEmpty;
            }).toList();

            if (available.isEmpty) {
              return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_today_outlined, color: AppColors.textHint, size: 64),
                  const SizedBox(height: 16),
                  const Text('No timetable available', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Timetable will appear here once set up', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                ]),
              );
            }

            // Set default selected day
            if (_selectedDay.isEmpty) {
              final today = _todayKey();
              _selectedDay = available.contains(today) ? today : available.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }

            final slots = (timetable[_selectedDay] as List?) ?? [];
            final colorCache = <String, Color>{};

            return RefreshIndicator(
              color: AppColors.roleStudent,
              backgroundColor: AppColors.surface1,
              onRefresh: () async => ref.invalidate(studentTimetableProvider),
              child: Column(
                children: [
                  // Day selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: available.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final day  = available[i];
                          final idx  = _days.indexOf(day);
                          final label = idx >= 0 ? _dayLabels[idx] : day.substring(0, 3).toUpperCase();
                          final sel  = day == _selectedDay;
                          final isToday = day == _todayKey();
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.roleStudent : AppColors.surface2,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isToday && !sel
                                      ? AppColors.roleStudent.withOpacity(0.5)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(label, style: TextStyle(
                                      fontSize: 13, fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                      color: sel ? Colors.white : AppColors.textSecondary)),
                                  if (isToday) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: sel ? Colors.white : AppColors.roleStudent,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('${slots.length} period${slots.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ),

                  Expanded(
                    child: slots.isEmpty
                        ? Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.event_available_rounded, color: AppColors.textHint, size: 48),
                              const SizedBox(height: 12),
                              const Text('No classes scheduled', style: TextStyle(color: AppColors.textSecondary)),
                            ]),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: slots.length,
                            itemBuilder: (_, i) {
                              final slot    = slots[i] as Map;
                              final subject = slot['subject_name']?.toString() ?? 'Unknown';
                              final teacher = slot['teacher_name']?.toString() ?? '';
                              final start   = slot['start_time']?.toString() ?? '';
                              final end     = slot['end_time']?.toString() ?? '';
                              final room    = slot['room']?.toString() ?? '';
                              final color   = _colorForSubject(subject, colorCache);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(width: 4, height: 60,
                                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                            const SizedBox(height: 3),
                                            if (teacher.isNotEmpty && teacher.trim() != ' ')
                                              Text(teacher, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            if (room.isNotEmpty)
                                              Row(children: [
                                                const Icon(Icons.room_rounded, size: 11, color: AppColors.textHint),
                                                const SizedBox(width: 3),
                                                Text(room, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                              ]),
                                          ],
                                        ),
                                      ),
                                      if (start.isNotEmpty)
                                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                          Text(_fmtTime(start), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                                          if (end.isNotEmpty)
                                            Text(_fmtTime(end), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                        ]),
                                    ],
                                  ),
                                ),
                              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05, end: 0);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _fmtTime(String t) {
    try {
      final parts = t.split(':');
      int h = int.parse(parts[0]);
      final m = parts.length > 1 ? parts[1] : '00';
      final suffix = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '$h:$m $suffix';
    } catch (_) { return t; }
  }
}
