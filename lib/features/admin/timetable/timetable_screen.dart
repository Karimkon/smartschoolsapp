import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

// Re-use classes list if already declared; keep local if not
final _timetableClassesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? data['classes'] ?? []);
  return List<dynamic>.from(data ?? []);
});

final timetableProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, classId) async {
  final params = classId.isNotEmpty ? {'class_id': classId} : <String, dynamic>{};
  final res = await ApiService().get('/timetable', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

const _subjectColors = {
  'mathematics': AppColors.primary,
  'english':     AppColors.roleTeacher,
  'science':     AppColors.success,
  'history':     AppColors.warning,
  'kiswahili':   AppColors.accent,
  'geography':   Color(0xFF06D6A0),
  'art':         Color(0xFFEC4899),
  'chemistry':   Color(0xFFFF6B35),
  'physics':     Color(0xFF7C3AED),
  'biology':     Color(0xFF10B981),
};

Color _subjectColor(String subject) {
  final key = subject.toLowerCase();
  for (final k in _subjectColors.keys) {
    if (key.contains(k)) return _subjectColors[k]!;
  }
  return AppColors.textSecondary;
}

List<dynamic> _slotsForDay(List<dynamic> slots, String day) {
  final filtered = slots.where((s) {
    final d = (s['day'] ?? s['day_of_week'] ?? '').toString().toLowerCase();
    return d.startsWith(day.toLowerCase());
  }).toList();
  filtered.sort((a, b) {
    final ta = (a['start_time'] ?? '00:00').toString();
    final tb = (b['start_time'] ?? '00:00').toString();
    return ta.compareTo(tb);
  });
  return filtered;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  ConsumerState<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _selectedClassId = '';
  String _selectedClassName = 'All';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _days.length, vsync: this, initialIndex: _todayIndex());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int _todayIndex() {
    final d = DateTime.now().weekday;
    return d <= 5 ? d - 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(_timetableClassesProvider);
    final timetableAsync = ref.watch(timetableProvider(_selectedClassId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Timetable',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
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
          // Class filter chips
          classesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(height: 36, child: ShimmerCard(height: 36, radius: 20)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (classes) {
              final items = [
                {'id': '', 'name': 'All'},
                ...classes.map((c) => {'id': c['id'].toString(), 'name': c['name']?.toString() ?? ''})
              ];
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: items.map((c) {
                      final sel = c['id'] == _selectedClassId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedClassId = c['id']!;
                            _selectedClassName = c['name']!;
                          }),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.surface2,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? AppColors.primary : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Text(c['name']!,
                                style: TextStyle(
                                    color: sel ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(),
              );
            },
          ),

          Expanded(
            child: timetableAsync.when(
              loading: () => TabBarView(
                controller: _tabs,
                children: _days.map((_) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: 4,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerCard(height: 80, radius: 14),
                  ),
                )).toList(),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                  const SizedBox(height: 12),
                  const Text('Failed to load timetable',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(timetableProvider),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text('Retry'),
                  ),
                ]),
              ),
              data: (data) {
                final allSlots = List<dynamic>.from(
                    data['data'] ?? data['timetable'] ?? data['slots'] ?? []);

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(timetableProvider),
                  color: AppColors.primary,
                  child: TabBarView(
                    controller: _tabs,
                    children: _days.map((day) {
                      final slots = _slotsForDay(allSlots, day);
                      if (slots.isEmpty) {
                        return Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.event_busy_rounded,
                                color: AppColors.textHint, size: 48),
                            const SizedBox(height: 12),
                            Text('No lessons on $day',
                                style: const TextStyle(color: AppColors.textSecondary)),
                          ]),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: slots.length,
                        itemBuilder: (ctx, i) {
                          final s = slots[i];
                          final subject = s['subject'] ?? s['subject_name'] ?? 'Subject';
                          final teacher = s['teacher'] ?? s['teacher_name'] ?? '';
                          final classGroup = s['class'] ?? s['class_name'] ?? _selectedClassName;
                          final startTime = s['start_time'] ?? '';
                          final endTime = s['end_time'] ?? '';
                          final room = s['room'] ?? s['venue'] ?? '';
                          final color = _subjectColor(subject.toString());

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              padding: EdgeInsets.zero,
                              child: IntrinsicHeight(
                                child: Row(children: [
                                  Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        bottomLeft: Radius.circular(20),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(subject.toString(),
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: color)),
                                              const SizedBox(height: 3),
                                              Text(teacher.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.textPrimary)),
                                              const SizedBox(height: 3),
                                              Row(children: [
                                                const Icon(Icons.class_rounded,
                                                    size: 11, color: AppColors.textHint),
                                                const SizedBox(width: 4),
                                                Text(classGroup.toString(),
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary)),
                                                if (room.toString().isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.room_rounded,
                                                      size: 11, color: AppColors.textHint),
                                                  const SizedBox(width: 4),
                                                  Text(room.toString(),
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary)),
                                                ],
                                              ]),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(children: [
                                                Text(startTime.toString(),
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: color)),
                                                if (endTime.toString().isNotEmpty)
                                                  Text(endTime.toString(),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: color.withOpacity(0.7))),
                                              ]),
                                            ),
                                          ],
                                        ),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ).animate(delay: Duration(milliseconds: i * 50))
                              .fadeIn()
                              .slideX(begin: 0.05, end: 0);
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
