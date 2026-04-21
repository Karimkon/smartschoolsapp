import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _Announcement {
  final String id;
  final String title;
  final String body;
  final String audience; // All | Students | Teachers | Parents
  final DateTime date;

  const _Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.date,
  });
}

// ── Mock data ─────────────────────────────────────────────────────────────────
final List<_Announcement> _mockAnnouncements = [
  _Announcement(
    id: '1',
    title: 'End of Term Examinations Schedule',
    body: 'The end of term examinations will begin on 28th April 2026. All students are expected to report by 7:30 AM. Please ensure you carry your student ID cards and all required stationery. No electronic devices are allowed in the examination hall.',
    audience: 'Students',
    date: DateTime(2026, 4, 18),
  ),
  _Announcement(
    id: '2',
    title: 'Staff Meeting — Wednesday 4 PM',
    body: 'All teaching and non-teaching staff are required to attend the mandatory staff meeting this Wednesday at 4:00 PM in the main conference hall. Agenda: curriculum review, term planning, and student welfare updates.',
    audience: 'Teachers',
    date: DateTime(2026, 4, 17),
  ),
  _Announcement(
    id: '3',
    title: 'Parents & Guardians Open Day',
    body: 'We cordially invite all parents and guardians to attend our Open Day on 2nd May 2026. Come and interact with teachers, review your child\'s academic progress, and tour our newly renovated facilities. Refreshments will be provided.',
    audience: 'Parents',
    date: DateTime(2026, 4, 16),
  ),
  _Announcement(
    id: '4',
    title: 'School Closure — Public Holiday',
    body: 'Please be informed that the school will be closed on 1st May 2026 in observance of the public holiday. Normal operations will resume on 4th May. Parents are requested to make appropriate arrangements for their children.',
    audience: 'All',
    date: DateTime(2026, 4, 15),
  ),
  _Announcement(
    id: '5',
    title: 'New Sports Equipment Available',
    body: 'The school has received a new batch of sports equipment including footballs, basketballs, and athletics gear. Students wishing to access these items should report to the sports office with their student ID during lunch break.',
    audience: 'Students',
    date: DateTime(2026, 4, 14),
  ),
  _Announcement(
    id: '6',
    title: 'Fee Payment Deadline Reminder',
    body: 'This is a reminder to all parents that the second term fee payment deadline is 30th April 2026. Late payments will attract a 5% surcharge. Please visit the school bursar\'s office or use the online payment portal for transactions.',
    audience: 'Parents',
    date: DateTime(2026, 4, 12),
  ),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
Color _audienceColor(String audience) {
  switch (audience) {
    case 'Students':
      return AppColors.accent;
    case 'Teachers':
      return AppColors.roleTeacher;
    case 'Parents':
      return AppColors.warning;
    default:
      return AppColors.primary;
  }
}

IconData _audienceIcon(String audience) {
  switch (audience) {
    case 'Students':
      return Icons.school_rounded;
    case 'Teachers':
      return Icons.person_pin_rounded;
    case 'Parents':
      return Icons.family_restroom_rounded;
    default:
      return Icons.groups_rounded;
  }
}

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// ── Screen ────────────────────────────────────────────────────────────────────
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Students', 'Teachers', 'Parents'];

  List<_Announcement> get _filtered {
    if (_selectedFilter == 'All') return _mockAnnouncements;
    return _mockAnnouncements
        .where((a) => a.audience == _selectedFilter || a.audience == 'All')
        .toList();
  }

  void _showDetail(_Announcement ann) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnnouncementDetailSheet(announcement: ann),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateAnnouncementSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
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
                        'Announcements',
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
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_mockAnnouncements.length} total',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filter Chips ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _selectedFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: 220.ms,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _audienceColor(f)
                                  : AppColors.surface2,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? _audienceColor(f)
                                    : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _audienceIcon(f),
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  f,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),

              // ── List ──────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No announcements found',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          return _AnnouncementCard(
                            announcement: filtered[i],
                            index: i,
                            onTap: () => _showDetail(filtered[i]),
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

// ── Announcement Card ─────────────────────────────────────────────────────────
class _AnnouncementCard extends StatelessWidget {
  final _Announcement announcement;
  final int index;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _audienceColor(announcement.audience);

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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored top bar
              Container(
                height: 4,
                decoration: BoxDecoration(color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        StatusBadge(
                          label: announcement.audience,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      announcement.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 13, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(announcement.date),
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: AppColors.textHint.withOpacity(0.5),
                            size: 18),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────
class _AnnouncementDetailSheet extends StatelessWidget {
  final _Announcement announcement;

  const _AnnouncementDetailSheet({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final color = _audienceColor(announcement.audience);

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
          // Handle
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

          // Audience badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_audienceIcon(announcement.audience),
                        size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(announcement.audience,
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(announcement.date),
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            announcement.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            announcement.body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 24),

          // Close button
          GradientButton(
            label: 'Close',
            gradient: const LinearGradient(
              colors: [AppColors.surface2, AppColors.surface2],
            ),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Create Announcement Sheet ─────────────────────────────────────────────────
class _CreateAnnouncementSheet extends StatefulWidget {
  const _CreateAnnouncementSheet();

  @override
  State<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<_CreateAnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _audience = 'All';
  bool _sending = false;

  final List<String> _audienceOptions = ['All', 'Students', 'Teachers', 'Parents'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _sending = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Announcement sent successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
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
              // Handle
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

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Announcement',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title field
              const Text('Title',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Announcement title...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Message field
              const Text('Message',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your announcement here...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              // Audience dropdown
              const Text('Audience',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
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
                    value: _audience,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _audienceOptions
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Row(
                                children: [
                                  Icon(_audienceIcon(a),
                                      size: 16,
                                      color: _audienceColor(a)),
                                  const SizedBox(width: 10),
                                  Text(a),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _audience = v!),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              GradientButton(
                label: 'Send Announcement',
                loading: _sending,
                onTap: _send,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
