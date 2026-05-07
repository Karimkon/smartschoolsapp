import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final receptionProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/visitors');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminReceptionScreen extends ConsumerStatefulWidget {
  const AdminReceptionScreen({super.key});
  @override ConsumerState<AdminReceptionScreen> createState() => _AdminReceptionScreenState();
}

class _AdminReceptionScreenState extends ConsumerState<AdminReceptionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(receptionProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reception',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.invalidate(receptionProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(text: 'Visitors'),
            Tab(text: 'Call Logs'),
            Tab(text: 'Complaints'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: async.when(
          loading: () => _shimmerList(),
          error: (e, _) => Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
              const SizedBox(height: 12),
              const Text('Could not load reception data',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () => ref.invalidate(receptionProvider),
                  child: const Text('Retry')),
            ]),
          ),
          data: (data) {
            final visitors   = (data['visitors']   as List?) ?? [];
            final callLogs   = (data['call_logs']  as List?) ?? [];
            final complaints = (data['complaints'] as List?) ?? [];

            return TabBarView(
              controller: _tabs,
              children: [
                _VisitorsList(visitors: visitors),
                _CallLogsList(callLogs: callLogs),
                _ComplaintsList(complaints: complaints),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _shimmerList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, __) =>
        const Padding(padding: EdgeInsets.only(bottom: 10), child: ShimmerCard(height: 80)),
  );
}

// ── Visitors List ─────────────────────────────────────────────────────────────

class _VisitorsList extends StatelessWidget {
  final List visitors;
  const _VisitorsList({required this.visitors});

  @override
  Widget build(BuildContext context) {
    if (visitors.isEmpty) {
      return const Center(child: Text('No visitor records today', style: TextStyle(color: AppColors.textHint)));
    }
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      onRefresh: () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visitors.length,
        itemBuilder: (_, i) {
          final v        = visitors[i] as Map;
          final name     = v['visitor_name']?.toString() ?? '';
          final purpose  = v['purpose']?.toString() ?? '';
          final host     = v['person_to_meet']?.toString() ?? '';
          final phone    = v['phone']?.toString() ?? '';
          final checkIn  = v['check_in']?.toString() ?? '';
          final checkOut = v['check_out'];
          final isActive = checkOut == null || checkOut.toString().isEmpty;
          final color    = isActive ? AppColors.success : AppColors.textHint;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isActive ? Icons.person_rounded : Icons.person_off_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(purpose, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    if (host.isNotEmpty) ...[
                      const Icon(Icons.person_pin_rounded, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(host, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      const SizedBox(width: 8),
                    ],
                    const Icon(Icons.login_rounded, size: 11, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(_shortTime(checkIn), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    if (!isActive) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.logout_rounded, size: 11, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(_shortTime(checkOut.toString()), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ]),
                ])),
                StatusBadge(label: isActive ? 'In' : 'Out', color: color),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn();
        },
      ),
    );
  }

  String _shortTime(String dt) {
    try {
      final t = DateTime.parse(dt);
      final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return dt.length > 16 ? dt.substring(11, 16) : dt;
    }
  }
}

// ── Call Logs List ────────────────────────────────────────────────────────────

class _CallLogsList extends StatelessWidget {
  final List callLogs;
  const _CallLogsList({required this.callLogs});

  @override
  Widget build(BuildContext context) {
    if (callLogs.isEmpty) {
      return const Center(child: Text('No call logs', style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: callLogs.length,
      itemBuilder: (_, i) {
        final c        = callLogs[i] as Map;
        final caller   = c['caller_name']?.toString() ?? '';
        final phone    = c['phone']?.toString() ?? '';
        final purpose  = c['purpose']?.toString() ?? '';
        final type     = c['call_type']?.toString() ?? 'incoming';
        final date     = c['call_date']?.toString() ?? '';
        final isIncoming = type.toLowerCase() == 'incoming';
        final color    = isIncoming ? AppColors.success : AppColors.primary;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(caller, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                if (purpose.isNotEmpty)
                  Text(purpose, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(phone, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                StatusBadge(label: isIncoming ? 'Incoming' : 'Outgoing', color: color),
                const SizedBox(height: 4),
                Text(_shortDate(date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              ]),
            ]),
          ),
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn();
      },
    );
  }

  String _shortDate(String dt) {
    try {
      final t = DateTime.parse(dt);
      return '${t.day}/${t.month} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt.length > 16 ? dt.substring(0, 10) : dt;
    }
  }
}

// ── Complaints List ───────────────────────────────────────────────────────────

class _ComplaintsList extends StatelessWidget {
  final List complaints;
  const _ComplaintsList({required this.complaints});

  @override
  Widget build(BuildContext context) {
    if (complaints.isEmpty) {
      return const Center(child: Text('No complaints on record', style: TextStyle(color: AppColors.textHint)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (_, i) {
        final c       = complaints[i] as Map;
        final from    = c['from']?.toString() ?? c['name']?.toString() ?? '';
        final subject = c['subject']?.toString() ?? c['description']?.toString() ?? '';
        final status  = c['status']?.toString() ?? 'open';
        final date    = c['created_at']?.toString() ?? '';
        final isOpen  = status.toLowerCase() == 'open';
        final color   = isOpen ? AppColors.warning : AppColors.success;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(isOpen ? Icons.report_problem_rounded : Icons.check_circle_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(from, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(subject, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(date.length > 10 ? date.substring(0, 10) : date,
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
              ])),
              StatusBadge(label: isOpen ? 'Open' : 'Resolved', color: color),
            ]),
          ),
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn();
      },
    );
  }
}
