import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _api = ApiService();
  List<dynamic> _convs = [];
  List<dynamic> _availableUsers = [];
  bool _loading = true;
  String? _error;

  // Active thread
  dynamic _activeConv;
  List<dynamic> _messages = [];
  bool _loadingThread = false;
  final _bodyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.get(ApiConstants.messages);
      setState(() { _convs = res.data['data'] ?? []; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Failed to load messages'; _loading = false; });
    }
  }

  Future<void> _loadThread(dynamic conv) async {
    setState(() { _activeConv = conv; _loadingThread = true; _messages = []; });
    try {
      final url = ApiConstants.messageThread.replaceAll('{id}', '${conv['id']}');
      final res = await _api.get(url);
      setState(() { _messages = res.data['data'] ?? []; _loadingThread = false; });
      _scrollToBottom();
    } catch (e) {
      setState(() { _loadingThread = false; });
    }
  }

  Future<void> _sendMessage() async {
    if (_bodyCtrl.text.trim().isEmpty || _sending || _activeConv == null) return;
    final body = _bodyCtrl.text.trim();
    setState(() { _sending = true; });
    try {
      await _api.post(ApiConstants.messages, data: {
        'to_user_id': _activeConv['other_user_id'],
        'body': body,
      });
      _bodyCtrl.clear();
      await _loadThread(_activeConv);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    } finally {
      setState(() { _sending = false; });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final res = await _api.get(ApiConstants.messagesUsers);
      setState(() { _availableUsers = res.data['data'] ?? []; });
    } catch (_) {}
  }

  Future<void> _startNewConversation(dynamic user) async {
    try {
      await _api.post(ApiConstants.messages, data: {'to_user_id': user['id'], 'body': '👋 Hello!'});
      await _loadConversations();
      // Find the conversation we just created
      final conv = _convs.firstWhere((c) => c['other_user_id'] == user['id'], orElse: () => null);
      if (conv != null) _loadThread(conv);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Row(
            children: [
              _buildSidebar(),
              Expanded(child: _buildThread()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.surface1,
        border: const Border(right: BorderSide(color: AppColors.surface2, width: 0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.surface2))),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Messages', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                  onPressed: () async {
                    await _loadUsers();
                    if (mounted) _showNewMessageSheet();
                  },
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Conversation list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center))
                    : _convs.isEmpty
                        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            const Text('No conversations yet', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () async { await _loadUsers(); if (mounted) _showNewMessageSheet(); },
                              child: const Text('Start one', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                            ),
                          ])
                        : RefreshIndicator(
                            onRefresh: _loadConversations,
                            color: AppColors.primary,
                            child: ListView.builder(
                              itemCount: _convs.length,
                              itemBuilder: (ctx, i) {
                                final c = _convs[i];
                                final isActive = _activeConv?['id'] == c['id'];
                                final unread = c['unread_count'] as int? ?? 0;
                                return GestureDetector(
                                  onTap: () => _loadThread(c),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.primary.withOpacity(0.15),
                                          child: Text(
                                            (c['other_name'] as String?)?.isNotEmpty == true ? c['other_name'][0].toUpperCase() : '?',
                                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c['other_name'] ?? '', style: TextStyle(color: AppColors.textPrimary, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              Text(c['last_message'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                        if (unread > 0)
                                          Container(
                                            width: 18, height: 18,
                                            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                            child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildThread() {
    if (_activeConv == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_rounded, size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text('Select a conversation', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () async { await _loadUsers(); if (mounted) _showNewMessageSheet(); },
              child: const Text('or start a new one →', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Thread header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            border: const Border(bottom: BorderSide(color: AppColors.surface2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  (_activeConv['other_name'] as String?)?.isNotEmpty == true ? _activeConv['other_name'][0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(_activeConv['other_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15))),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: _loadingThread
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _messages.isEmpty
                  ? const Center(child: Text('No messages yet. Say hello!', style: TextStyle(color: AppColors.textHint)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final m = _messages[i];
                        final isMine = m['is_mine'] == true;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.55),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMine ? AppColors.primary : AppColors.surface2,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                                    bottomRight: Radius.circular(isMine ? 4 : 16),
                                  ),
                                ),
                                child: Text(m['body'] ?? '', style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary, fontSize: 13)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        // Compose
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            border: Border(top: BorderSide(color: AppColors.surface2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bodyCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _sendMessage,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _sending ? AppColors.primary.withOpacity(0.5) : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('New Message', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: _availableUsers.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _availableUsers.length,
                    itemBuilder: (ctx, i) {
                      final u = _availableUsers[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(u['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                        title: Text(u['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(u['role'] ?? '', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                        onTap: () {
                          Navigator.pop(context);
                          _startNewConversation(u);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
