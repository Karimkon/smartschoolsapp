import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final parentConversationsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/parent/messages');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

final parentMessagesProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, int>((ref, convId) async {
  final res = await ApiService().get('/parent/messages/$convId');
  return Map<String, dynamic>.from(res.data as Map);
});

final parentStaffProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiService().get('/parent/staff');
  final data = res.data as Map;
  return (data['data'] as List?) ?? [];
});

// ── Conversations List Screen ─────────────────────────────────────────────────

class ParentMessagesScreen extends ConsumerWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(children: [
                const Text('Messages',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () => ref.refresh(parentConversationsProvider),
                ),
                IconButton(
                  icon: const Icon(Icons.add_comment_rounded, color: AppColors.roleParent),
                  onPressed: () => _showNewMessageSheet(context, ref),
                ),
              ]),
            ),
            Expanded(
              child: async.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(4, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerCard(height: 72),
                  )),
                ),
                error: (e, _) => Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 52),
                    const SizedBox(height: 12),
                    const Text('Could not load messages',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: () => ref.refresh(parentConversationsProvider),
                        child: const Text('Retry')),
                  ],
                )),
                data: (convs) {
                  if (convs.isEmpty) {
                    return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.textHint, size: 56),
                        const SizedBox(height: 14),
                        const Text('No messages yet',
                            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        const Text('Tap + to message a teacher or admin',
                            style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.roleParent),
                          icon: const Icon(Icons.add_comment_rounded, size: 16),
                          label: const Text('New Message'),
                          onPressed: () => _showNewMessageSheet(context, ref),
                        ),
                      ],
                    ));
                  }

                  return RefreshIndicator(
                    color: AppColors.roleParent,
                    backgroundColor: AppColors.surface1,
                    onRefresh: () => ref.refresh(parentConversationsProvider.future),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: convs.length,
                      itemBuilder: (_, i) {
                        final c       = convs[i] as Map;
                        final name    = c['other_name']?.toString() ?? 'Staff';
                        final last    = c['last_message']?.toString() ?? '';
                        final unread  = toI(c['unread_count'], 0);
                        final role    = c['other_role']?.toString() ?? 'staff';
                        final convId  = toI(c['id']);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(
                                    convId: convId,
                                    otherName: name,
                                  ),
                                ),
                              ).then((_) => ref.refresh(parentConversationsProvider)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                child: Row(children: [
                                  _RoleAvatar(name: name, role: role),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(name,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary)),
                                        ),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.roleParent,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text('$unread',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
                                          ),
                                      ]),
                                      const SizedBox(height: 3),
                                      Text(_roleBadge(role),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: _roleColor(role),
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 4),
                                      Text(last,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: unread > 0
                                                  ? AppColors.textPrimary
                                                  : AppColors.textSecondary,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.w400)),
                                    ],
                                  )),
                                ]),
                              ),
                            ),
                          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: -0.04),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showNewMessageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewMessageSheet(onSent: () {
        ref.refresh(parentConversationsProvider);
      }),
    );
  }

  String _roleBadge(String role) {
    switch (role) {
      case 'school_admin': return 'Admin';
      case 'teacher':      return 'Teacher';
      case 'accountant':   return 'Accountant';
      default:             return 'Staff';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'school_admin': return AppColors.roleAdmin;
      case 'teacher':      return AppColors.roleTeacher;
      case 'accountant':   return AppColors.roleAccountant;
      default:             return AppColors.primary;
    }
  }
}

// ── Role Avatar ───────────────────────────────────────────────────────────────

class _RoleAvatar extends StatelessWidget {
  final String name;
  final String role;
  const _RoleAvatar({required this.name, required this.role});

  Color get _color {
    switch (role) {
      case 'school_admin': return AppColors.roleAdmin;
      case 'teacher':      return AppColors.roleTeacher;
      case 'accountant':   return AppColors.roleAccountant;
      default:             return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: _color.withOpacity(0.4), width: 1.5),
      ),
      child: Center(
        child: Text(initial,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _color)),
      ),
    );
  }
}

// ── New Message Sheet ─────────────────────────────────────────────────────────

class _NewMessageSheet extends ConsumerStatefulWidget {
  final VoidCallback onSent;
  const _NewMessageSheet({required this.onSent});

  @override
  ConsumerState<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends ConsumerState<_NewMessageSheet> {
  int? _selectedUserId;
  String? _selectedName;
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_selectedUserId == null || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiService().post('/parent/messages', data: {
        'to_user_id': _selectedUserId,
        'body': _bodyCtrl.text.trim(),
      });
      widget.onSent();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(parentStaffProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Message',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            staffAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load staff',
                  style: const TextStyle(color: AppColors.textSecondary)),
              data: (staff) => DropdownButtonFormField<int>(
                value: _selectedUserId,
                dropdownColor: AppColors.surface2,
                decoration: InputDecoration(
                  hintText: 'Select recipient',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: staff.map((s) {
                  final m    = s as Map;
                  final id   = toI(m['id']);
                  final name = m['name']?.toString() ?? 'Staff';
                  final role = m['role']?.toString() ?? 'staff';
                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text('$name (${_roleBadge(role)})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() {
                  _selectedUserId = v;
                  final s = staff.firstWhere(
                      (s) => (s as Map)['id'] == v, orElse: () => null);
                  _selectedName = (s as Map?)?['name']?.toString();
                }),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.roleParent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send Message',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _roleBadge(String role) {
    switch (role) {
      case 'school_admin': return 'Admin';
      case 'teacher':      return 'Teacher';
      case 'accountant':   return 'Accountant';
      default:             return 'Staff';
    }
  }
}

// ── Chat Detail Screen ────────────────────────────────────────────────────────

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int convId;
  final String otherName;
  const ChatDetailScreen({super.key, required this.convId, required this.otherName});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _ctrl       = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending     = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      // Get other user id from conversation data
      final convData = ref.read(parentMessagesProvider(widget.convId)).valueOrNull;
      final messages = (convData?['data'] as List?) ?? [];
      // Find a message not from us to get other_user_id
      // Actually, we need to store other_user_id — let's look it up from the conversation list
      final convList = ref.read(parentConversationsProvider).valueOrNull ?? [];
      final conv     = convList.firstWhere(
          (c) => (c as Map)['id'] == widget.convId, orElse: () => null);
      final toId     = conv != null ? (conv as Map)['other_user_id'] as int : 0;

      await ApiService().post('/parent/messages', data: {
        'to_user_id': toId,
        'body': text,
      });
      ref.refresh(parentMessagesProvider(widget.convId));
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(parentMessagesProvider(widget.convId));

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(children: [
            // Header
            Container(
              color: AppColors.surface1,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.roleParent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.roleParent),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.otherName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: () => ref.refresh(parentMessagesProvider(widget.convId)),
                ),
              ]),
            ),

            // Messages
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.roleParent)),
                error: (e, _) => Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: () => ref.refresh(parentMessagesProvider(widget.convId)),
                        child: const Text('Retry')),
                  ]),
                ),
                data: (data) {
                  final msgs = (data['data'] as List?) ?? [];
                  if (msgs.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Say hello!',
                          style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m      = msgs[i] as Map;
                      final isMine = m['is_mine'] == true;
                      final body   = m['body']?.toString() ?? '';
                      final time   = _formatTime(m['created_at']?.toString());
                      return _MessageBubble(body: body, isMine: isMine, time: time);
                    },
                  );
                },
              ),
            ),

            // Input bar
            Container(
              color: AppColors.surface1,
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.roleParent,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatTime(String? ts) {
    if (ts == null) return '';
    try {
      final dt   = DateTime.parse(ts).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inHours < 1)    return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return ts ?? '';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final String body;
  final bool isMine;
  final String time;
  const _MessageBubble({required this.body, required this.isMine, required this.time});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMine) const SizedBox(width: 8),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine
                  ? AppColors.roleParent.withOpacity(0.85)
                  : AppColors.surface2,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(16),
                topRight:    const Radius.circular(16),
                bottomLeft:  Radius.circular(isMine ? 16 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(body,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMine ? Colors.white : AppColors.textPrimary,
                        height: 1.4)),
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(
                        fontSize: 10,
                        color: isMine
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textHint)),
              ],
            ),
          ),
        ),
        if (isMine) const SizedBox(width: 8),
      ],
    ),
  );
}
