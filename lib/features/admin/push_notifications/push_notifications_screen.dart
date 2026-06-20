import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final pushNotificationsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/push-notifications');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _targetColor(String target) {
  switch (target.toLowerCase()) {
    case 'students':   return AppColors.accent;
    case 'teachers':   return AppColors.roleTeacher;
    case 'employees':  return const Color(0xFF7C3AED);
    case 'parents':    return AppColors.warning;
    case 'class':      return const Color(0xFF0891B2);
    case 'house':      return const Color(0xFFF59E0B);
    case 'leadership': return const Color(0xFFF59E0B);
    default:           return AppColors.primary;
  }
}

IconData _targetIcon(String target) {
  switch (target.toLowerCase()) {
    case 'students':   return Icons.school_rounded;
    case 'teachers':   return Icons.person_pin_rounded;
    case 'employees':  return Icons.badge_rounded;
    case 'parents':    return Icons.family_restroom_rounded;
    case 'class':      return Icons.class_rounded;
    case 'house':      return Icons.home_work_rounded;
    case 'leadership': return Icons.star_rounded;
    default:           return Icons.groups_rounded;
  }
}

String _formatDatetime(String? dt) {
  if (dt == null || dt.isEmpty) return '';
  try {
    final d = DateTime.parse(dt).toLocal();
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month-1]} · ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  } catch (_) { return dt; }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PushNotificationsScreen extends ConsumerStatefulWidget {
  const PushNotificationsScreen({super.key});

  @override
  ConsumerState<PushNotificationsScreen> createState() => _PushNotificationsScreenState();
}

class _PushNotificationsScreenState extends ConsumerState<PushNotificationsScreen> {
  void _showSendSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendNotificationSheet(onSent: () {
        ref.invalidate(pushNotificationsProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pushNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.notifications_rounded, color: Colors.white),
        label: const Text('Send',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Push Notifications',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(pushNotificationsProvider),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: 6,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShimmerCard(height: 90, radius: 16),
            ),
          ),
          error: (e, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.notifications_off_rounded, color: AppColors.textHint, size: 52),
              const SizedBox(height: 14),
              const Text('Could not load notifications',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              const Text(
                'FCM server key not configured.\nAdd FCM_SERVER_KEY to the server .env file.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textHint, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(pushNotificationsProvider),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry'),
              ),
            ]),
          ),
          data: (data) {
            final stats = data['stats'] as Map? ?? {};
            final list  = List<dynamic>.from(
                data['data'] ?? data['notifications'] ?? data['history'] ?? []);

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(pushNotificationsProvider),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  // ── Stats ────────────────────────────────────────────────
                  _StatsRow(stats: stats).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 18),

                  // ── Section header ────────────────────────────────────────
                  Row(children: [
                    const Text('History',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${list.length}',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ]).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),

                  // ── Empty ────────────────────────────────────────────────
                  if (list.isEmpty)
                    _EmptyState().animate().fadeIn(delay: 200.ms)
                  else
                    ...list.asMap().entries.map((e) => _NotificationCard(
                          notification: Map<String, dynamic>.from(e.value as Map),
                          index: e.key,
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem('Registered\nDevices', '${stats['device_count'] ?? 0}',
          Icons.devices_rounded, AppColors.primary),
      _StatItem('Sent', '${stats['total_sent'] ?? 0}',
          Icons.send_rounded, AppColors.success),
      _StatItem('Delivered', '${stats['delivered'] ?? 0}',
          Icons.mark_email_read_rounded, AppColors.accent),
      _StatItem('Read', '${stats['read'] ?? 0}',
          Icons.visibility_rounded, const Color(0xFF7C3AED)),
    ];

    return Row(
      children: items.asMap().entries.map((e) {
        final idx  = e.key;
        final item = e.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < items.length - 1 ? 8 : 0),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 17),
                ),
                const SizedBox(height: 7),
                Text(item.value,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

// ── Notification Card ─────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final int index;

  const _NotificationCard({required this.notification, required this.index});

  @override
  Widget build(BuildContext context) {
    final title     = (notification['title'] ?? 'Notification').toString();
    final body      = (notification['body'] ?? notification['message'] ?? '').toString();
    final target    = (notification['target'] ?? notification['target_type'] ?? 'all').toString();
    final sentAt    = (notification['sent_at'] ?? notification['created_at'] ?? '').toString();
    final delivered = (notification['delivered_count'] ?? 0).toString();
    final read      = (notification['read_count'] ?? 0).toString();
    final devices   = (notification['device_count'] ?? notification['total_devices'] ?? 0).toString();
    final status    = (notification['status'] ?? 'sent').toString();
    final color     = _targetColor(target);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_targetIcon(target), color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700)),
                  Text(_formatDatetime(sentAt),
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11)),
                ]),
              ),
              StatusBadge(
                label: status == 'sent' ? 'Sent' : status,
                color: status == 'sent' || status == 'delivered'
                    ? AppColors.success
                    : AppColors.textHint,
              ),
            ]),
            if (body.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
            ],
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 8),
            Row(children: [
              _MicroStat(Icons.devices_rounded, devices, 'Devices', AppColors.textHint),
              const SizedBox(width: 14),
              _MicroStat(Icons.mark_email_read_rounded, delivered, 'Delivered', AppColors.success),
              const SizedBox(width: 14),
              _MicroStat(Icons.visibility_rounded, read, 'Read', const Color(0xFF7C3AED)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  target[0].toUpperCase() + target.substring(1),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideY(begin: 0.08, end: 0);
  }
}

class _MicroStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;

  const _MicroStat(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text('$value ',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
    ]);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.notifications_rounded, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 16),
        const Text('No notifications sent yet',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text(
          'Tap the Send button to broadcast push\nnotifications to students, teachers, or parents.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textHint, fontSize: 13, height: 1.5),
        ),
      ]),
    );
  }
}

// ── Send Notification Sheet ───────────────────────────────────────────────────

class _SendNotificationSheet extends ConsumerStatefulWidget {
  final VoidCallback onSent;
  const _SendNotificationSheet({required this.onSent});

  @override
  ConsumerState<_SendNotificationSheet> createState() => _SendNotificationSheetState();
}

class _SendNotificationSheetState extends ConsumerState<_SendNotificationSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  String _target   = 'all';
  bool   _sending  = false;

  static const _targets = [
    'all', 'students', 'teachers', 'employees', 'parents', 'class', 'house', 'leadership',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _send() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService().post('/push-notifications', data: {
        'title':  _titleCtrl.text.trim(),
        'body':   _bodyCtrl.text.trim(),
        'target': _target,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSent();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Notification sent successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Failed to send notification'),
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
                      color: AppColors.textHint,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text('Send Push Notification',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 20),

              // Title
              const Text('Title *',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Notification title...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                ),
              ),
              const SizedBox(height: 14),

              // Body
              const Text('Message *',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              TextField(
                controller: _bodyCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Notification message...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 14),

              // Target
              const Text('Send To',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(14)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _target,
                    isExpanded: true,
                    dropdownColor: AppColors.surface2,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    iconEnabledColor: AppColors.textSecondary,
                    items: _targets
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Row(children: [
                                Icon(_targetIcon(t), size: 15, color: _targetColor(t)),
                                const SizedBox(width: 10),
                                Text(t[0].toUpperCase() + t.substring(1)),
                              ]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _target = v!),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              GradientButton(
                  label: 'Send Notification', loading: _sending, onTap: _send),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
