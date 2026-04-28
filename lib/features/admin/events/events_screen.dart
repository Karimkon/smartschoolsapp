import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final eventsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, filter) async {
  final params = filter.isNotEmpty && filter != 'all'
      ? {'status': filter}
      : <String, dynamic>{};
  final res = await ApiService().get('/events', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _eventTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'academic':  return AppColors.primary;
    case 'sports':    return AppColors.accent;
    case 'cultural':  return const Color(0xFFEC4899);
    case 'holiday':   return AppColors.warning;
    case 'meeting':   return const Color(0xFF7C3AED);
    default:          return AppColors.primary;
  }
}

IconData _eventTypeIcon(String type) {
  switch (type.toLowerCase()) {
    case 'academic':  return Icons.school_rounded;
    case 'sports':    return Icons.sports_soccer_rounded;
    case 'cultural':  return Icons.celebration_rounded;
    case 'holiday':   return Icons.beach_access_rounded;
    case 'meeting':   return Icons.groups_rounded;
    default:          return Icons.event_rounded;
  }
}

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dt = DateTime.parse(dateStr);
    return '${dt.day} ${_monthAbbr[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  try { return DateTime.parse(s); } catch (_) { return null; }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  String _statusFilter = 'all';
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'upcoming', 'label': 'Upcoming'},
    {'key': 'ongoing', 'label': 'Ongoing'},
    {'key': 'completed', 'label': 'Completed'},
  ];

  bool _hasEvent(DateTime date, List<dynamic> events) {
    return events.any((e) {
      final start = _parseDate(e['start_date'] ?? e['date']);
      final end = _parseDate(e['end_date'] ?? e['start_date'] ?? e['date']);
      if (start == null) return false;
      final endEff = end ?? start;
      return !date.isBefore(DateTime(start.year, start.month, start.day)) &&
          !date.isAfter(DateTime(endEff.year, endEff.month, endEff.day));
    });
  }

  List<dynamic> _filterByDate(List<dynamic> events) {
    if (_selectedDate == null) return events;
    return events.where((e) {
      final start = _parseDate(e['start_date'] ?? e['date']);
      final end = _parseDate(e['end_date'] ?? e['start_date'] ?? e['date']);
      if (start == null) return false;
      final endEff = end ?? start;
      final d = _selectedDate!;
      return !d.isBefore(DateTime(start.year, start.month, start.day)) &&
          !d.isAfter(DateTime(endEff.year, endEff.month, endEff.day));
    }).toList();
  }

  void _showAddEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEventSheet(onCreated: () => ref.invalidate(eventsProvider)),
    );
  }

  void _showDetail(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(eventsProvider(_statusFilter));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEvent,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textPrimary, size: 20),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text('Events',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  async.maybeWhen(
                    data: (data) {
                      final list = List<dynamic>.from(data['data'] ?? data['events'] ?? []);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${list.length} events',
                            style: const TextStyle(
                                color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ]),
              ),

              // ── Status Filter ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _statusFilter == f['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = f['key']!),
                          child: AnimatedContainer(
                            duration: 220.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accent : AppColors.surface2,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Text(f['label']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              Expanded(
                child: async.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: 4,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ShimmerBox(height: 100, borderRadius: 18),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load events',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(eventsProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                  data: (data) {
                    final allEvents = List<dynamic>.from(data['data'] ?? data['events'] ?? []);
                    final events = _filterByDate(allEvents);

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(eventsProvider),
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Calendar strip
                            _CalendarStrip(
                              focusedMonth: _focusedMonth,
                              selectedDate: _selectedDate,
                              hasEvent: (d) => _hasEvent(d, allEvents),
                              onDateSelected: (d) => setState(() =>
                                  _selectedDate = (_selectedDate?.day == d.day &&
                                          _selectedDate?.month == d.month)
                                      ? null
                                      : d),
                              onMonthChanged: (m) => setState(() => _focusedMonth = m),
                            ),
                            const SizedBox(height: 24),

                            Row(children: [
                              Text(
                                _selectedDate != null
                                    ? 'Events on ${_selectedDate!.day} ${_monthAbbr[_selectedDate!.month - 1]}'
                                    : 'All Events',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              if (_selectedDate != null)
                                GestureDetector(
                                  onTap: () => setState(() => _selectedDate = null),
                                  child: const Text('Clear',
                                      style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                            ]).animate().fadeIn(duration: 300.ms),
                            const SizedBox(height: 12),

                            if (events.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(children: [
                                    Icon(Icons.event_busy_rounded,
                                        size: 48,
                                        color: AppColors.textHint.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    const Text('No events found',
                                        style: TextStyle(color: AppColors.textSecondary)),
                                  ]),
                                ),
                              )
                            else
                              ...List.generate(events.length, (i) {
                                final event = Map<String, dynamic>.from(events[i] as Map);
                                return _EventCard(
                                  event: event,
                                  index: i,
                                  onTap: () => _showDetail(event),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Calendar Strip ─────────────────────────────────────────────────────────────

class _CalendarStrip extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final bool Function(DateTime) hasEvent;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onMonthChanged;

  const _CalendarStrip({
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasEvent,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          GestureDetector(
            onTap: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
          Expanded(
            child: Text(
              '${_monthAbbr[focusedMonth.month - 1]} ${focusedMonth.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            onTap: () => onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 68,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            itemBuilder: (ctx, idx) {
              final day = idx + 1;
              final date = DateTime(focusedMonth.year, focusedMonth.month, day);
              final isSelected = selectedDate?.day == day &&
                  selectedDate?.month == focusedMonth.month;
              final isToday = DateTime.now().day == day &&
                  DateTime.now().month == focusedMonth.month &&
                  DateTime.now().year == focusedMonth.year;
              final hasEv = hasEvent(date);
              const weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
              final wd = weekdays[(date.weekday - 1) % 7];

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: AnimatedContainer(
                  duration: 200.ms,
                  width: 46,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : isToday
                              ? AppColors.primary.withOpacity(0.4)
                              : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(wd,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.textHint,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text('$day',
                          style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasEv
                              ? (isSelected ? Colors.white : AppColors.accent)
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms);
  }
}

// ── Event Card ─────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final int index;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = event['type'] ?? event['event_type'] ?? 'Academic';
    final color = _eventTypeColor(type.toString());
    final title = event['title'] ?? 'Event';
    final location = event['location'] ?? event['venue'] ?? '';
    final startDate = _parseDate(event['start_date'] ?? event['date']);
    final endDate = _parseDate(event['end_date'] ?? event['start_date'] ?? event['date']);
    final startTime = event['start_time'] ?? '';
    final endTime = event['end_time'] ?? '';
    final description = event['description'] ?? '';

    final isSingleDay = startDate != null &&
        endDate != null &&
        startDate.day == endDate.day &&
        startDate.month == endDate.month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left date block
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startDate != null ? '${startDate.day}' : '—',
                    style: TextStyle(
                        color: color, fontSize: 26, fontWeight: FontWeight.w800, height: 1),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    startDate != null
                        ? _monthAbbr[startDate.month - 1].toUpperCase()
                        : '',
                    style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5),
                  ),
                  if (!isSingleDay && endDate != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('—',
                          style: TextStyle(color: color.withOpacity(0.5), fontSize: 12)),
                    ),
                    Text('${endDate.day}',
                        style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1)),
                    Text(_monthAbbr[endDate.month - 1].toUpperCase(),
                        style: TextStyle(
                            color: color.withOpacity(0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title.toString(),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      StatusBadge(
                        label: type.toString()[0].toUpperCase() + type.toString().substring(1),
                        color: color,
                      ),
                    ]),
                    const SizedBox(height: 6),
                    if (startTime.isNotEmpty || endTime.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text('$startTime${endTime.isNotEmpty ? ' – $endTime' : ''}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ]),
                    if (description.toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(description.toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textHint, fontSize: 12, height: 1.4)),
                    ],
                    if (location.toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.location_on_rounded,
                              size: 11, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(location.toString(),
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Event Detail Sheet ────────────────────────────────────────────────────────

class _EventDetailSheet extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final type = event['type'] ?? event['event_type'] ?? 'Academic';
    final color = _eventTypeColor(type.toString());
    final title = event['title'] ?? 'Event';
    final location = event['location'] ?? event['venue'] ?? '';
    final startDate = event['start_date'] ?? event['date'] ?? '';
    final startTime = event['start_time'] ?? '';
    final endTime = event['end_time'] ?? '';
    final description = event['description'] ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(_eventTypeIcon(type.toString()), color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title.toString(),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                StatusBadge(
                  label: type.toString()[0].toUpperCase() + type.toString().substring(1),
                  color: color,
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 20),
          if (startDate.toString().isNotEmpty)
            _DetailRow(Icons.calendar_today_rounded, 'Date', _formatDate(startDate.toString())),
          if (startTime.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(Icons.access_time_rounded, 'Time',
                '$startTime${endTime.toString().isNotEmpty ? ' – $endTime' : ''}'),
          ],
          if (location.toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(Icons.location_on_rounded, 'Location', location.toString()),
          ],
          if (description.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 16),
            const Text('Description',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(description.toString(),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
          ],
          const SizedBox(height: 24),
          GradientButton(
            label: 'Close',
            gradient: const LinearGradient(colors: [AppColors.surface2, AppColors.surface2]),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textHint),
      const SizedBox(width: 10),
      Text('$label: ',
          style: const TextStyle(
              color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

// ── Add Event Sheet ───────────────────────────────────────────────────────────

class _AddEventSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _AddEventSheet({required this.onCreated});

  @override
  ConsumerState<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends ConsumerState<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _type = 'Academic';
  bool _saving = false;

  final List<String> _types = ['Academic', 'Sports', 'Cultural', 'Holiday', 'Meeting'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.surface2),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(picked)) _endDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day} ${_monthAbbr[dt.month - 1]} ${dt.year}';
  }

  void _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ApiService().post('/events', data: {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'type': _type.toLowerCase(),
        'start_date': _startDate.toIso8601String().split('T')[0],
        'end_date': _endDate.toIso8601String().split('T')[0],
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Event added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to add event'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Add Event',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),
              _FieldLabel('Event Title'),
              const SizedBox(height: 8),
              _FieldInput(controller: _titleCtrl, hint: 'Enter event title'),
              const SizedBox(height: 16),
              _FieldLabel('Description'),
              const SizedBox(height: 8),
              _FieldInput(controller: _descCtrl, hint: 'Event description...', maxLines: 3),
              const SizedBox(height: 16),
              _FieldLabel('Location'),
              const SizedBox(height: 8),
              _FieldInput(controller: _locationCtrl, hint: 'e.g. School Hall'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FieldLabel('Start Date'),
                    const SizedBox(height: 8),
                    _DateButton(date: _fmtDate(_startDate), onTap: () => _pickDate(true)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _FieldLabel('End Date'),
                    const SizedBox(height: 8),
                    _DateButton(date: _fmtDate(_endDate), onTap: () => _pickDate(false)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              _FieldLabel('Event Type'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(children: [
                                Icon(_eventTypeIcon(t), size: 16, color: _eventTypeColor(t)),
                                const SizedBox(width: 10),
                                Text(t),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(label: 'Save Event', loading: _saving, onTap: _save),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600));
}

class _FieldInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _FieldInput({required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _DateButton extends StatelessWidget {
  final String date;
  final VoidCallback onTap;

  const _DateButton({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
              color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(date,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),
      );
}
