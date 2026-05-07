import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final biometricScansProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, date) async {
  final res = await ApiService().get('/biometric/scans?date=$date');
  return Map<String, dynamic>.from(res.data as Map);
});

final biometricDevicesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/biometric/devices');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _actionColor(String action) {
  switch (action.toLowerCase()) {
    case 'check_in':  return AppColors.success;
    case 'check_out': return AppColors.primary;
    default:          return AppColors.warning;
  }
}

IconData _methodIcon(String? scan) {
  if (scan == null) return Icons.sensors_rounded;
  if (scan.toLowerCase().contains('fingerprint') || scan.toLowerCase().contains('biometric')) {
    return Icons.fingerprint_rounded;
  }
  if (scan.toLowerCase().contains('qr') || scan.toLowerCase().contains('code')) {
    return Icons.qr_code_scanner_rounded;
  }
  return Icons.contactless_rounded;
}

String _timeFromDt(String? dt) {
  if (dt == null || dt.isEmpty) return '';
  try {
    final t = DateTime.parse(dt);
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  } catch (_) {
    return dt.length > 16 ? dt.substring(11, 16) : dt;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});
  @override ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _dateStr => _selectedDate.toIso8601String().substring(0, 10);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.surface2),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scansAsync   = ref.watch(biometricScansProvider(_dateStr));
    final devicesAsync = ref.watch(biometricDevicesProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Biometric & QR Attendance',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(biometricScansProvider);
              ref.invalidate(biometricDevicesProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.success,
          labelColor: AppColors.success,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Scan Log'), Tab(text: 'Devices')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: TabBarView(
          controller: _tabs,
          children: [
            // ── Scan Log ──────────────────────────────────────────────────
            Column(children: [
              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Text(_dateStr,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_rounded, size: 15, color: AppColors.textHint),
                  ]),
                ),
              ),

              // Stats
              scansAsync.when(
                loading: () => const SizedBox(height: 60),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  final scans    = (data['data'] as List?) ?? [];
                  final checkIns = scans.where((s) =>
                      (s as Map)['action']?.toString().toLowerCase() == 'check_in').length;
                  final checkOuts = scans.where((s) =>
                      (s as Map)['action']?.toString().toLowerCase() == 'check_out').length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(children: [
                      Expanded(child: _StatBox('Total', '${scans.length}', AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatBox('Check In', '$checkIns', AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatBox('Check Out', '$checkOuts', AppColors.accent)),
                    ]).animate().fadeIn(),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Scan list
              Expanded(
                child: scansAsync.when(
                  loading: () => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: 6,
                    itemBuilder: (_, __) =>
                        const Padding(padding: EdgeInsets.only(bottom: 8), child: ShimmerCard(height: 64)),
                  ),
                  error: (e, _) => Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                      const SizedBox(height: 12),
                      const Text('Could not load scan log',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () => ref.invalidate(biometricScansProvider),
                          child: const Text('Retry')),
                    ]),
                  ),
                  data: (data) {
                    final scans = (data['data'] as List?) ?? [];
                    if (scans.isEmpty) {
                      return const Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.sensors_off_rounded, color: AppColors.textHint, size: 48),
                          SizedBox(height: 12),
                          Text('No scans recorded for this date',
                              style: TextStyle(color: AppColors.textHint)),
                        ]),
                      );
                    }
                    return RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface1,
                      onRefresh: () => ref.refresh(biometricScansProvider(_dateStr).future),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: scans.length,
                        itemBuilder: (_, i) {
                          final s      = scans[i] as Map;
                          final name   = s['person_name']?.toString() ?? 'Unknown';
                          final type   = s['person_type']?.toString() ?? 'student';
                          final action = s['action']?.toString() ?? 'check_in';
                          final time   = _timeFromDt(s['scanned_at']?.toString());
                          final color  = _actionColor(action);
                          final label  = action == 'check_in' ? 'Check In' : 'Check Out';
                          final typeColor = type == 'teacher' ? AppColors.roleTeacher : AppColors.primary;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Icon(_methodIcon(s['action']?.toString()), color: color, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  const SizedBox(height: 3),
                                  Row(children: [
                                    StatusBadge(
                                        label: type[0].toUpperCase() + type.substring(1),
                                        color: typeColor),
                                  ]),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  StatusBadge(label: label, color: color),
                                  const SizedBox(height: 4),
                                  Text(time,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textHint,
                                          fontWeight: FontWeight.w600)),
                                ]),
                              ]),
                            ),
                          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
                        },
                      ),
                    );
                  },
                ),
              ),
            ]),

            // ── Devices ───────────────────────────────────────────────────
            devicesAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 3,
                itemBuilder: (_, __) =>
                    const Padding(padding: EdgeInsets.only(bottom: 12), child: ShimmerCard(height: 120)),
              ),
              error: (e, _) => Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.cloud_off_rounded, color: AppColors.textHint, size: 48),
                  const SizedBox(height: 12),
                  const Text('Could not load devices', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => ref.invalidate(biometricDevicesProvider),
                      child: const Text('Retry')),
                ]),
              ),
              data: (data) {
                final devices = (data['data'] as List?) ?? [];
                if (devices.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.sensors_off_rounded, color: AppColors.textHint, size: 48),
                      SizedBox(height: 12),
                      Text('No devices registered', style: TextStyle(color: AppColors.textHint)),
                    ]),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: devices.length,
                  itemBuilder: (_, i) {
                    final d      = devices[i] as Map;
                    final name   = d['name']?.toString() ?? '';
                    final loc    = d['location']?.toString() ?? '';
                    final token  = d['api_token']?.toString() ?? '';
                    final status = d['status']?.toString() ?? 'offline';
                    final online = status.toLowerCase() == 'online' || status.toLowerCase() == 'active';
                    final lastSeen = d['last_seen_at']?.toString() ?? d['updated_at']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                  color: (online ? AppColors.success : AppColors.error).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.sensors_rounded,
                                  color: online ? AppColors.success : AppColors.error, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                              if (loc.isNotEmpty)
                                Text(loc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ])),
                            Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: online ? AppColors.success : AppColors.error,
                                boxShadow: [BoxShadow(
                                    color: (online ? AppColors.success : AppColors.error).withOpacity(0.5),
                                    blurRadius: 6)],
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.surface2, borderRadius: BorderRadius.circular(10)),
                            child: Row(children: [
                              const Icon(Icons.key_rounded, size: 14, color: AppColors.textHint),
                              const SizedBox(width: 6),
                              Expanded(child: Text(
                                token.isNotEmpty
                                    ? '${token.substring(0, token.length > 20 ? 20 : token.length)}…'
                                    : 'No token',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                                    letterSpacing: 0.5),
                                overflow: TextOverflow.ellipsis,
                              )),
                              if (lastSeen.isNotEmpty) ...[
                                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textHint),
                                const SizedBox(width: 4),
                                Text(lastSeen.length > 10 ? lastSeen.substring(0, 10) : lastSeen,
                                    style: TextStyle(fontSize: 11,
                                        color: online ? AppColors.success : AppColors.error)),
                              ],
                            ]),
                          ),
                        ]),
                      ),
                    ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint), textAlign: TextAlign.center),
    ]),
  );
}
