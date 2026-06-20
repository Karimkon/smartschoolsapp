import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _timetableClassesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/classes-list');
  final data = res.data;
  if (data is Map) return List<dynamic>.from(data['data'] ?? data['classes'] ?? []);
  return List<dynamic>.from(data ?? []);
});

// Family key: "classId|timetableType" e.g. "5|theology" or "|secular"
final timetableProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, key) async {
  final parts    = key.split('|');
  final classId  = parts[0];
  final ttType   = parts.length > 1 ? parts[1] : 'secular';
  final params   = <String, dynamic>{'timetable_type': ttType};
  if (classId.isNotEmpty) params['class_id'] = classId;
  final res = await ApiService().get('/timetable', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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
  'cre':         Color(0xFF8B5CF6),
  'ire':         Color(0xFF8B5CF6),
  'islamic':     Color(0xFF7C3AED),
  'quran':       Color(0xFF6D28D9),
  'arabic':      Color(0xFF5B21B6),
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

/// Extract teacher display string from a slot — supports single or multiple teachers
String _teacherDisplay(Map slot) {
  // Try multi-teacher array first
  final teachersArr = slot['teachers'] as List?;
  if (teachersArr != null && teachersArr.isNotEmpty) {
    final names = teachersArr.map((t) {
      if (t is Map) {
        return ('${t['first_name'] ?? ''} ${t['last_name'] ?? ''}').trim();
      }
      return t.toString();
    }).where((n) => n.isNotEmpty).toList();
    if (names.isNotEmpty) return names.join(', ');
  }
  // Fallback to single teacher fields
  return (slot['teacher'] ?? slot['teacher_name'] ?? '').toString();
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
  String _selectedClassId   = '';
  String _selectedClassName = 'All';
  String _timetableType     = 'secular'; // secular | theology

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
    return d <= 6 ? d - 1 : 0;
  }

  String get _providerKey => '$_selectedClassId|$_timetableType';

  @override
  Widget build(BuildContext context) {
    final classesAsync   = ref.watch(_timetableClassesProvider);
    final timetableAsync = ref.watch(timetableProvider(_providerKey));

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
          // Timetable type toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _TypeToggleBtn(
                label: 'Secular',
                icon: Icons.school_rounded,
                color: AppColors.primary,
                selected: _timetableType == 'secular',
                onTap: () => setState(() => _timetableType = 'secular'),
              ),
              const SizedBox(width: 6),
              _TypeToggleBtn(
                label: 'Theology',
                icon: Icons.mosque_rounded,
                color: const Color(0xFF7C3AED),
                selected: _timetableType == 'theology',
                onTap: () => setState(() => _timetableType = 'theology'),
              ),
            ]),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          isScrollable: true,
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // ── Class filter chips ────────────────────────────────────────────
          classesAsync.when(
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(height: 36, child: ShimmerCard(height: 36, radius: 20)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (classes) {
              final items = [
                {'id': '', 'name': 'All'},
                ...classes.map((c) =>
                    {'id': c['id'].toString(), 'name': c['name']?.toString() ?? ''}),
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
                            _selectedClassId   = c['id']!;
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

          // ── Timetable type indicator ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: _timetableType == 'theology'
                      ? const Color(0xFF7C3AED)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _timetableType == 'theology'
                    ? 'Showing Theology Timetable'
                    : 'Showing Secular Timetable',
                style: TextStyle(
                  color: _timetableType == 'theology'
                      ? const Color(0xFF7C3AED)
                      : AppColors.textHint,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
          ),

          // ── Timetable body ────────────────────────────────────────────────
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
                          final s          = Map<String, dynamic>.from(slots[i] as Map);
                          final subject    = (s['subject'] ?? s['subject_name'] ?? 'Subject').toString();
                          final teacherStr = _teacherDisplay(s);
                          final classGroup = (s['class'] ?? s['class_name'] ?? _selectedClassName).toString();
                          final startTime  = (s['start_time'] ?? '').toString();
                          final endTime    = (s['end_time'] ?? '').toString();
                          final room       = (s['room'] ?? s['venue'] ?? '').toString();
                          final color      = _subjectColor(subject);

                          // Multi-teacher count
                          final teachersArr   = s['teachers'] as List?;
                          final multiTeacher  = teachersArr != null && teachersArr.length > 1;

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
                                      padding: const EdgeInsets.all(13),
                                      child: Row(children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(subject,
                                                  style: TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: color)),
                                              const SizedBox(height: 3),
                                              if (teacherStr.isNotEmpty)
                                                Row(children: [
                                                  if (multiTeacher) ...[
                                                    const Icon(Icons.group_rounded,
                                                        size: 11, color: AppColors.textHint),
                                                    const SizedBox(width: 3),
                                                  ],
                                                  Expanded(
                                                    child: Text(
                                                      teacherStr,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 11.5,
                                                          color: AppColors.textPrimary),
                                                    ),
                                                  ),
                                                ]),
                                              const SizedBox(height: 4),
                                              Row(children: [
                                                const Icon(Icons.class_rounded,
                                                    size: 11, color: AppColors.textHint),
                                                const SizedBox(width: 3),
                                                Text(classGroup,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.textSecondary)),
                                                if (room.isNotEmpty) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(Icons.room_rounded,
                                                      size: 11, color: AppColors.textHint),
                                                  const SizedBox(width: 3),
                                                  Text(room,
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary)),
                                                ],
                                              ]),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: color.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Column(children: [
                                                Text(startTime,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                        color: color)),
                                                if (endTime.isNotEmpty)
                                                  Text(endTime,
                                                      style: TextStyle(
                                                          fontSize: 10.5,
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

// ── Toggle button for Secular / Theology ──────────────────────────────────────

class _TypeToggleBtn extends StatelessWidget {
  final String  label;
  final IconData icon;
  final Color   color;
  final bool    selected;
  final VoidCallback onTap;

  const _TypeToggleBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 180.ms,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: selected ? color : AppColors.textHint),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? color : AppColors.textHint)),
        ]),
      ),
    );
  }
}
