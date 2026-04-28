import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

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
    case 'students': return AppColors.accent;
    case 'teachers': return AppColors.roleTeacher;
    case 'parents':  return AppColors.warning;
    case 'staff':    return AppColors.roleAccountant;
    default:         return AppColors.primary;
  }
}

IconData _audienceIcon(String audience) {
  switch (audience.toLowerCase()) {
    case 'students': return Icons.school_rounded;
    case 'teachers': return Icons.person_pin_rounded;
    case 'parents':  return Icons.family_restroom_rounded;
    case 'staff':    return Icons.badge_rounded;
    default:         return Icons.groups_rounded;
  }
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final dt = DateTime.parse(dateStr);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  } catch (_) {
    return dateStr;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Students', 'Teachers', 'Parents', 'Staff'];

  void _showDetail(Map<String, dynamic> ann) {
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
                    child: Text('Announcements',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ),
                  async.maybeWhen(
                    data: (data) {
                      final list = List<dynamic>.from(data['data'] ?? data['announcements'] ?? []);
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
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? _audienceColor(f) : AppColors.surface2,
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
                                Icon(_audienceIcon(f),
                                    size: 14,
                                    color: isSelected ? Colors.white : AppColors.textSecondary),
                                const SizedBox(width: 6),
                                Text(f,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
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
                      child: ShimmerBox(height: 120, borderRadius: 18),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load announcements',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(announcementsProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ]),
                  ),
                  data: (data) {
                    final list = List<dynamic>.from(data['data'] ?? data['announcements'] ?? []);
                    if (list.isEmpty) {
                      return const Center(
                        child: Text('No announcements found',
                            style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(announcementsProvider),
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) {
                          final ann = Map<String, dynamic>.from(list[i] as Map);
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
    final audience = announcement['audience'] ?? announcement['target_audience'] ?? 'all';
    final color = _audienceColor(audience.toString());
    final title = announcement['title'] ?? 'Announcement';
    final body = announcement['message'] ?? announcement['body'] ?? announcement['content'] ?? '';
    final date = announcement['created_at'] ?? announcement['date'] ?? '';

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
              Container(height: 4, decoration: BoxDecoration(color: color)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(title.toString(),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(
                        label: audience.toString()[0].toUpperCase() +
                            audience.toString().substring(1),
                        color: color,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(body.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(_formatDate(date.toString()),
                          style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.textHint.withOpacity(0.5), size: 18),
                    ]),
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
  final Map<String, dynamic> announcement;

  const _AnnouncementDetailSheet({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final audience = announcement['audience'] ?? announcement['target_audience'] ?? 'all';
    final color = _audienceColor(audience.toString());
    final title = announcement['title'] ?? 'Announcement';
    final body = announcement['message'] ?? announcement['body'] ?? announcement['content'] ?? '';
    final date = announcement['created_at'] ?? announcement['date'] ?? '';

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_audienceIcon(audience.toString()), size: 14, color: color),
                const SizedBox(width: 6),
                Text(audience.toString()[0].toUpperCase() + audience.toString().substring(1),
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            const Spacer(),
            Text(_formatDate(date.toString()),
                style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
          ]),
          const SizedBox(height: 16),
          Text(title.toString(),
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3)),
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),
          Text(body.toString(),
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14, height: 1.7)),
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

// ── Create Announcement Sheet ─────────────────────────────────────────────────

class _CreateAnnouncementSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateAnnouncementSheet({required this.onCreated});

  @override
  ConsumerState<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends ConsumerState<_CreateAnnouncementSheet> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _audience = 'all';
  bool _sending = false;

  final List<String> _audienceOptions = ['all', 'students', 'teachers', 'parents', 'staff'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService().post('/announcements', data: {
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'audience': _audience,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Announcement sent successfully'),
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
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('New Announcement',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 24),
              const Text('Title',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Message',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              const Text('Audience',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface2, borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _audience,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _audienceOptions
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Row(children: [
                                Icon(_audienceIcon(a), size: 16, color: _audienceColor(a)),
                                const SizedBox(width: 10),
                                Text(a[0].toUpperCase() + a.substring(1)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _audience = v!),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(label: 'Send Announcement', loading: _sending, onTap: _send),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
