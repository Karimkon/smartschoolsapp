import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _SchoolEvent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final String description;
  final String location;
  final String type; // Academic | Sports | Cultural | Holiday | Meeting

  const _SchoolEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.description,
    required this.location,
    required this.type,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────
final List<_SchoolEvent> _mockEvents = [
  _SchoolEvent(
    id: '1',
    title: 'End of Term Examinations',
    startDate: DateTime(2026, 4, 28),
    endDate: DateTime(2026, 5, 8),
    startTime: '07:30 AM',
    endTime: '03:00 PM',
    description: 'End of second term examinations for all classes. Students must carry their ID cards and follow the exam timetable strictly.',
    location: 'All Classrooms',
    type: 'Academic',
  ),
  _SchoolEvent(
    id: '2',
    title: 'Inter-House Sports Day',
    startDate: DateTime(2026, 4, 25),
    endDate: DateTime(2026, 4, 25),
    startTime: '08:00 AM',
    endTime: '05:00 PM',
    description: 'Annual inter-house sports competition. All students are expected to participate. Parents are welcome to attend and cheer their children.',
    location: 'School Grounds',
    type: 'Sports',
  ),
  _SchoolEvent(
    id: '3',
    title: 'Staff Development Workshop',
    startDate: DateTime(2026, 4, 23),
    endDate: DateTime(2026, 4, 23),
    startTime: '09:00 AM',
    endTime: '04:00 PM',
    description: 'Professional development workshop for all teaching staff focusing on modern pedagogy and technology integration in the classroom.',
    location: 'Conference Hall',
    type: 'Meeting',
  ),
  _SchoolEvent(
    id: '4',
    title: 'Cultural Day & Talent Show',
    startDate: DateTime(2026, 5, 2),
    endDate: DateTime(2026, 5, 2),
    startTime: '10:00 AM',
    endTime: '04:00 PM',
    description: 'Annual cultural day celebrating the diversity of our school community. Students will showcase dances, art, music, and traditional attire from various cultures.',
    location: 'School Hall',
    type: 'Cultural',
  ),
  _SchoolEvent(
    id: '5',
    title: 'Parents Open Day',
    startDate: DateTime(2026, 5, 9),
    endDate: DateTime(2026, 5, 9),
    startTime: '08:00 AM',
    endTime: '01:00 PM',
    description: 'Parents are invited to meet teachers, review academic progress reports, and interact with school management. Refreshments will be provided.',
    location: 'All Departments',
    type: 'Meeting',
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
Color _eventTypeColor(String type) {
  switch (type) {
    case 'Academic':
      return AppColors.primary;
    case 'Sports':
      return AppColors.accent;
    case 'Cultural':
      return const Color(0xFFEC4899);
    case 'Holiday':
      return AppColors.warning;
    case 'Meeting':
      return const Color(0xFF7C3AED);
    default:
      return AppColors.primary;
  }
}

IconData _eventTypeIcon(String type) {
  switch (type) {
    case 'Academic':
      return Icons.school_rounded;
    case 'Sports':
      return Icons.sports_soccer_rounded;
    case 'Cultural':
      return Icons.celebration_rounded;
    case 'Holiday':
      return Icons.beach_access_rounded;
    case 'Meeting':
      return Icons.groups_rounded;
    default:
      return Icons.event_rounded;
  }
}

const List<String> _monthAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime dt) => '${dt.day} ${_monthAbbr[dt.month - 1]} ${dt.year}';

// ── Screen ────────────────────────────────────────────────────────────────────
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime _focusedMonth = DateTime(2026, 4);
  DateTime? _selectedDate;

  List<_SchoolEvent> get _eventsForSelected {
    if (_selectedDate == null) return _mockEvents;
    return _mockEvents.where((e) {
      final d = _selectedDate!;
      return !d.isBefore(e.startDate) && !d.isAfter(e.endDate);
    }).toList();
  }

  bool _hasEvent(DateTime date) {
    return _mockEvents.any((e) =>
        !date.isBefore(e.startDate) && !date.isAfter(e.endDate));
  }

  void _showAddEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddEventSheet(),
    );
  }

  void _showDetail(_SchoolEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _eventsForSelected;

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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Events',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_mockEvents.length} events',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Calendar strip ───────────────────────────────────
                      _CalendarStrip(
                        focusedMonth: _focusedMonth,
                        selectedDate: _selectedDate,
                        hasEvent: _hasEvent,
                        onDateSelected: (d) =>
                            setState(() => _selectedDate =
                                (_selectedDate?.day == d.day &&
                                        _selectedDate?.month == d.month)
                                    ? null
                                    : d),
                        onMonthChanged: (m) =>
                            setState(() => _focusedMonth = m),
                      ),
                      const SizedBox(height: 24),

                      // ── Events label ─────────────────────────────────────
                      Row(
                        children: [
                          Text(
                            _selectedDate != null
                                ? 'Events on ${_selectedDate!.day} ${_monthAbbr[_selectedDate!.month - 1]}'
                                : 'All Upcoming Events',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDate != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDate = null),
                              child: const Text(
                                'Clear',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 12),

                      // ── Event cards ──────────────────────────────────────
                      if (events.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_rounded,
                                    size: 48,
                                    color: AppColors.textHint.withOpacity(0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No events on this day',
                                  style: TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...List.generate(events.length, (i) {
                          return _EventCard(
                            event: events[i],
                            index: i,
                            onTap: () => _showDetail(events[i]),
                          );
                        }),
                    ],
                  ),
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
    final daysInMonth =
        DateUtils.getDaysInMonth(focusedMonth.year, focusedMonth.month);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            children: [
              GestureDetector(
                onTap: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month - 1)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
              Expanded(
                child: Text(
                  '${_monthAbbr[focusedMonth.month - 1]} ${focusedMonth.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => onMonthChanged(
                    DateTime(focusedMonth.year, focusedMonth.month + 1)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Day strip
          SizedBox(
            height: 68,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (ctx, idx) {
                final day = idx + 1;
                final date =
                    DateTime(focusedMonth.year, focusedMonth.month, day);
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
                        Text(
                          wd,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white.withOpacity(0.8)
                                : AppColors.textHint,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$day',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEv
                                ? (isSelected
                                    ? Colors.white
                                    : AppColors.accent)
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
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms);
  }
}

// ── Event Card ─────────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final _SchoolEvent event;
  final int index;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(event.type);
    final isSingleDay =
        event.startDate.day == event.endDate.day &&
        event.startDate.month == event.endDate.month;

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
                    '${event.startDate.day}',
                    style: TextStyle(
                      color: color,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _monthAbbr[event.startDate.month - 1].toUpperCase(),
                    style: TextStyle(
                      color: color.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!isSingleDay) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('—',
                          style: TextStyle(
                              color: color.withOpacity(0.5), fontSize: 12)),
                    ),
                    Text(
                      '${event.endDate.day}',
                      style: TextStyle(
                        color: color.withOpacity(0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    Text(
                      _monthAbbr[event.endDate.month - 1].toUpperCase(),
                      style: TextStyle(
                        color: color.withOpacity(0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusBadge(label: event.type, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Time range
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${event.startTime} – ${event.endTime}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 11,
                                  color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                event.location,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  final _SchoolEvent event;

  const _EventDetailSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = _eventTypeColor(event.type);

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_eventTypeIcon(event.type), color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(label: event.type, color: color),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _DetailRow(Icons.calendar_today_rounded, 'Date',
              _formatDate(event.startDate)),
          const SizedBox(height: 10),
          _DetailRow(Icons.access_time_rounded, 'Time',
              '${event.startTime} – ${event.endTime}'),
          const SizedBox(height: 10),
          _DetailRow(
              Icons.location_on_rounded, 'Location', event.location),
          const SizedBox(height: 16),

          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),

          const Text('Description',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            event.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          GradientButton(
            label: 'Close',
            gradient: const LinearGradient(
                colors: [AppColors.surface2, AppColors.surface2]),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Add Event Sheet ───────────────────────────────────────────────────────────
class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet();

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _type = 'Academic';
  bool _saving = false;

  final List<String> _types = [
    'Academic', 'Sports', 'Cultural', 'Holiday', 'Meeting'
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
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
            primary: AppColors.primary,
            surface: AppColors.surface2,
          ),
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

  void _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event added successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_rounded,
                        color: AppColors.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Event',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _FormLabel('Event Title'),
              const SizedBox(height: 8),
              _FormTextField(controller: _titleCtrl, hint: 'Enter event title'),
              const SizedBox(height: 16),

              _FormLabel('Description'),
              const SizedBox(height: 8),
              _FormTextField(
                controller: _descCtrl,
                hint: 'Event description...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('Start Date'),
                        const SizedBox(height: 8),
                        _DateButton(
                          date: _startDate,
                          onTap: () => _pickDate(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormLabel('End Date'),
                        const SizedBox(height: 8),
                        _DateButton(
                          date: _endDate,
                          onTap: () => _pickDate(false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _FormLabel('Event Type'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _types
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(_eventTypeIcon(t),
                                      size: 16,
                                      color: _eventTypeColor(t)),
                                  const SizedBox(width: 10),
                                  Text(t),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Save Event',
                loading: _saving,
                onTap: _save,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600),
      );
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _FormTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style:
            const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

class _DateButton extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                _formatDate(date),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
}
