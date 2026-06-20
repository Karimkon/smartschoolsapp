import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final announcementsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, audience) async {
  final params = audience.isNotEmpty && audience != 'All'
      ? {'audience': audience.toLowerCase()}
      : <String, dynamic>{};
  final res = await ApiService().get('/announcements', params: params);
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _audienceColor(String audience) {
  switch (audience.toLowerCase()) {
    case 'students':   return AppColors.accent;
    case 'teachers':   return AppColors.roleTeacher;
    case 'employees':  return const Color(0xFF7C3AED);
    case 'parents':    return AppColors.warning;
    case 'staff':      return AppColors.roleAccountant;
    case 'class':      return const Color(0xFF0891B2);
    case 'house':      return const Color(0xFFF59E0B);
    case 'leadership': return const Color(0xFFF59E0B);
    default:           return AppColors.primary;
  }
}

IconData _audienceIcon(String audience) {
  switch (audience.toLowerCase()) {
    case 'students':   return Icons.school_rounded;
    case 'teachers':   return Icons.person_pin_rounded;
    case 'employees':  return Icons.badge_rounded;
    case 'parents':    return Icons.family_restroom_rounded;
    case 'staff':      return Icons.support_agent_rounded;
    case 'class':      return Icons.class_rounded;
    case 'house':      return Icons.home_work_rounded;
    case 'leadership': return Icons.star_rounded;
    default:           return Icons.groups_rounded;
  }
}

Color _typeColor(String type) {
  switch (type.toLowerCase()) {
    case 'urgent':   return AppColors.error;
    case 'event':    return const Color(0xFF2563EB);
    case 'academic': return const Color(0xFF7C3AED);
    case 'finance':  return const Color(0xFF0891B2);
    case 'holiday':  return const Color(0xFFF59E0B);
    default:         return AppColors.textHint;
  }
}

String _typeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'urgent':   return 'URGENT';
    case 'event':    return 'Event';
    case 'academic': return 'Academic';
    case 'finance':  return 'Finance';
    case 'holiday':  return 'Holiday';
    default:         return 'General';
  }
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) { return dateStr; }
}

bool _isExpired(String? expiryDate) {
  if (expiryDate == null || expiryDate.isEmpty) return false;
  try { return DateTime.parse(expiryDate).isBefore(DateTime.now()); }
  catch (_) { return false; }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All', 'Students', 'Teachers', 'Employees', 'Parents', 'Staff', 'Class', 'House', 'Leadership',
  ];

  void _showDetail(Map<String, dynamic> ann) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnnouncementDetailSheet(
        announcement: ann,
        onPinToggled: () => ref.invalidate(announcementsProvider),
      ),
    );
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAnnouncementSheet(onCreated: () {
        ref.invalidate(announcementsProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(announcementsProvider(_selectedFilter));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.campaign_rounded, color: Colors.white),
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
                    child: Text('Announcements',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  async.maybeWhen(
                    data: (data) {
                      final list = List<dynamic>.from(
                          data['data'] ?? data['announcements'] ?? []);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${list.length} total',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ]),
              ),

              // ── Filter Chips ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((f) {
                      final isSelected = _selectedFilter == f;
                      final col = f == 'All' ? AppColors.primary : _audienceColor(f);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? col : AppColors.surface2,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? col : Colors.white.withOpacity(0.07),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  f == 'All' ? Icons.all_inclusive_rounded : _audienceIcon(f),
                                  size: 13,
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(f,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 12,
                                    )),
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
                child: async.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    itemCount: 5,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ShimmerCard(height: 130, radius: 18),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(announcementsProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                  data: (data) {
                    final list = List<dynamic>.from(
                        data['data'] ?? data['announcements'] ?? []);
                    if (list.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.campaign_outlined,
                              color: AppColors.textHint, size: 52),
                          const SizedBox(height: 12),
                          const Text('No announcements found',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ]),
                      );
                    }

                    // Pinned first
                    final pinned = list
                        .where((a) => (a['is_pinned'] == true || a['is_pinned'] == 1))
                        .toList();
                    final others = list
                        .where((a) => !(a['is_pinned'] == true || a['is_pinned'] == 1))
                        .toList();
                    final sorted = [...pinned, ...others];

                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(announcementsProvider),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) {
                          final ann = Map<String, dynamic>.from(sorted[i] as Map);
                          return _AnnouncementCard(
                            announcement: ann,
                            index: i,
                            onTap: () => _showDetail(ann),
                          );
                        },
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

// ── Announcement Card ─────────────────────────────────────────────────────────

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> announcement;
  final int index;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final audience = (announcement['audience'] ?? announcement['target_audience'] ?? 'all').toString();
    final color    = _audienceColor(audience);
    final title    = (announcement['title'] ?? 'Announcement').toString();
    final body     = (announcement['message'] ?? announcement['body'] ?? announcement['content'] ?? '').toString();
    final date     = (announcement['created_at'] ?? announcement['date'] ?? '').toString();
    final type     = (announcement['type'] ?? 'general').toString();
    final expiry   = (announcement['expiry_date'] ?? '').toString();
    final isPinned = announcement['is_pinned'] == true || announcement['is_pinned'] == 1;
    final expired  = _isExpired(expiry);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPinned
                ? const Color(0xFFF59E0B).withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // colored top bar
              Container(height: 4, color: expired ? AppColors.error : color),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (isPinned) ...[
                        const Icon(Icons.push_pin_rounded,
                            size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(
                        label: audience[0].toUpperCase() + audience.substring(1),
                        color: color,
                      ),
                    ]),
                    const SizedBox(height: 7),
                    Text(body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                    const SizedBox(height: 10),
                    Row(children: [
                      // type badge
                      if (type != 'general') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _typeColor(type).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(_typeLabel(type),
                              style: TextStyle(
                                  color: _typeColor(type),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (expired) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('EXPIRED',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(_formatDate(date),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textHint.withOpacity(0.4), size: 16),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 55))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _AnnouncementDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> announcement;
  final VoidCallback onPinToggled;

  const _AnnouncementDetailSheet({
    required this.announcement,
    required this.onPinToggled,
  });

  @override
  ConsumerState<_AnnouncementDetailSheet> createState() => _AnnouncementDetailSheetState();
}

class _AnnouncementDetailSheetState extends ConsumerState<_AnnouncementDetailSheet> {
  bool _pinning = false;

  Future<void> _togglePin() async {
    final id = widget.announcement['id'];
    if (id == null) return;
    setState(() => _pinning = true);
    try {
      await ApiService().post('/announcements/$id/pin');
      widget.onPinToggled();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _pinning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audience = (widget.announcement['audience'] ?? 'all').toString();
    final color    = _audienceColor(audience);
    final title    = (widget.announcement['title'] ?? 'Announcement').toString();
    final body     = (widget.announcement['message'] ?? widget.announcement['body'] ?? '').toString();
    final date     = (widget.announcement['created_at'] ?? '').toString();
    final type     = (widget.announcement['type'] ?? 'general').toString();
    final expiry   = (widget.announcement['expiry_date'] ?? '').toString();
    final isPinned = widget.announcement['is_pinned'] == true || widget.announcement['is_pinned'] == 1;
    final expired  = _isExpired(expiry);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(22),
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
            const SizedBox(height: 18),

            // Audience + date row
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_audienceIcon(audience), size: 13, color: color),
                  const SizedBox(width: 5),
                  Text(audience[0].toUpperCase() + audience.substring(1),
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
              if (type != 'general') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _typeColor(type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_typeLabel(type),
                      style: TextStyle(
                          color: _typeColor(type), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              if (expired) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('EXPIRED',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              const Spacer(),
              Text(_formatDate(date),
                  style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
            ]),

            const SizedBox(height: 14),
            // Pinned indicator
            if (isPinned)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: const [
                  Icon(Icons.push_pin_rounded, size: 14, color: Color(0xFFF59E0B)),
                  SizedBox(width: 6),
                  Text('Pinned announcement',
                      style: TextStyle(
                          color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),

            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3)),
            const SizedBox(height: 12),
            Container(height: 1, color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 14),
            Text(body,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.7)),

            if (expiry.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(children: [
                const Icon(Icons.event_busy_rounded, size: 13, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text('Expires: ${_formatDate(expiry)}',
                    style: TextStyle(
                        color: expired ? AppColors.error : AppColors.textHint,
                        fontSize: 12)),
              ]),
            ],

            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pinning ? null : _togglePin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: isPinned
                          ? const Color(0xFFF59E0B).withOpacity(0.15)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPinned
                            ? const Color(0xFFF59E0B).withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Center(
                      child: _pinning
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Color(0xFFF59E0B)))
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                                size: 16,
                                color: isPinned ? const Color(0xFFF59E0B) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(isPinned ? 'Unpin' : 'Pin',
                                  style: TextStyle(
                                      color: isPinned
                                          ? const Color(0xFFF59E0B)
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Close',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Create Announcement Sheet ─────────────────────────────────────────────────

class _CreateAnnouncementSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateAnnouncementSheet({required this.onCreated});

  @override
  ConsumerState<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends ConsumerState<_CreateAnnouncementSheet> {
  final _titleCtrl   = TextEditingController();
  final _messageCtrl = TextEditingController();
  String  _audience  = 'all';
  String  _type      = 'general';
  bool    _isPinned  = false;
  bool    _sending   = false;
  String? _expiryDate;

  static const _audienceOptions = [
    'all', 'students', 'teachers', 'employees', 'parents', 'staff', 'class', 'house', 'leadership',
  ];
  static const _typeOptions = [
    'general', 'urgent', 'event', 'academic', 'finance', 'holiday',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _expiryDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  void _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService().post('/announcements', data: {
        'title':       _titleCtrl.text.trim(),
        'message':     _messageCtrl.text.trim(),
        'audience':    _audience,
        'type':        _type,
        'is_pinned':   _isPinned ? 1 : 0,
        if (_expiryDate != null) 'expiry_date': _expiryDate,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Announcement broadcast successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to send announcement'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text,
        style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 12.5, fontWeight: FontWeight.w600)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(22),
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
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.campaign_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Broadcast Announcement',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),

              // Title
              _label('Title *'),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Announcement title...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
              const SizedBox(height: 14),

              // Message
              _label('Message *'),
              TextField(
                controller: _messageCtrl,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write your announcement here...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 14),

              // Target + Type row
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Target Audience'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(14)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _audience,
                            isExpanded: true,
                            dropdownColor: AppColors.surface2,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            iconEnabledColor: AppColors.textSecondary,
                            items: _audienceOptions
                                .map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Row(children: [
                                        Icon(_audienceIcon(a),
                                            size: 14, color: _audienceColor(a)),
                                        const SizedBox(width: 8),
                                        Text(a[0].toUpperCase() + a.substring(1)),
                                      ]),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _audience = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Type'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(14)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _type,
                            isExpanded: true,
                            dropdownColor: AppColors.surface2,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            iconEnabledColor: AppColors.textSecondary,
                            items: _typeOptions
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t[0].toUpperCase() + t.substring(1)),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => _type = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),

              // Expiry date
              _label('Expiry Date (optional)'),
              GestureDetector(
                onTap: _pickExpiry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.event_rounded,
                        size: 16, color: AppColors.textHint),
                    const SizedBox(width: 10),
                    Text(
                      _expiryDate ?? 'No expiry date',
                      style: TextStyle(
                          color: _expiryDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontSize: 13),
                    ),
                    const Spacer(),
                    if (_expiryDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: const Icon(Icons.clear_rounded,
                            size: 16, color: AppColors.textHint),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Pin toggle
              GestureDetector(
                onTap: () => setState(() => _isPinned = !_isPinned),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: _isPinned
                        ? const Color(0xFFF59E0B).withOpacity(0.1)
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isPinned
                          ? const Color(0xFFF59E0B).withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                      size: 18,
                      color: _isPinned ? const Color(0xFFF59E0B) : AppColors.textHint,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isPinned ? 'Pinned — shows at top' : 'Pin this announcement',
                      style: TextStyle(
                          color: _isPinned
                              ? const Color(0xFFF59E0B)
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isPinned,
                      activeColor: const Color(0xFFF59E0B),
                      onChanged: (v) => setState(() => _isPinned = v),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 22),

              GradientButton(
                  label: 'Send Announcement', loading: _sending, onTap: _send),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
