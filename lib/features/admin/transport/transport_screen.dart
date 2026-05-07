import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/services/api_service.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final transportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/transport');
  return Map<String, dynamic>.from(res.data as Map);
});

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _trackingColor(String s) {
  switch (s.toLowerCase()) {
    case 'on route':  return AppColors.warning;
    case 'at school': return AppColors.success;
    default:          return AppColors.textHint;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminTransportScreen extends ConsumerStatefulWidget {
  const AdminTransportScreen({super.key});

  @override
  ConsumerState<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends ConsumerState<AdminTransportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _classFilter = 'All';
  String _search = '';
  final Set<String> _expandedRoutes = {};

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
    final async = ref.watch(transportProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Transport',
            style: TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [Tab(text: 'Routes'), Tab(text: 'Assignments'), Tab(text: 'Tracking')],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: async.when(
            loading: () => Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(children: [
                  Expanded(child: ShimmerCard(height: 72, radius: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: ShimmerCard(height: 72, radius: 14)),
                  const SizedBox(width: 10),
                  Expanded(child: ShimmerCard(height: 72, radius: 14)),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  itemCount: 3,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerCard(height: 90, radius: 20),
                  ),
                ),
              ),
            ]),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                const Text('Failed to load transport data',
                    style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(transportProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (data) {
              final routes = List<dynamic>.from(data['routes'] ?? data['data'] ?? []);
              final assignments = List<dynamic>.from(data['assignments'] ?? data['student_assignments'] ?? []);
              final stats = data['stats'] as Map? ?? {};

              final totalStudents = stats['total_students'] ??
                  routes.fold<int>(
                      0, (s, r) => s + (r['students_count'] as int? ?? 0));
              final activeBuses = stats['active_buses'] ?? 0;

              // Filter assignments
              final filtered = assignments.where((a) {
                final matchClass = _classFilter == 'All' ||
                    (a['class_name'] ?? '').toString().contains(_classFilter);
                final matchSearch = _search.isEmpty ||
                    (a['student_name'] ?? '${a['first_name']} ${a['last_name']}')
                        .toString()
                        .toLowerCase()
                        .contains(_search.toLowerCase());
                return matchClass && matchSearch;
              }).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(transportProvider),
                color: AppColors.primary,
                child: Column(children: [
                  // Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(children: [
                      Expanded(child: StatCard(
                          label: 'Total Routes',
                          value: '${routes.length}',
                          icon: Icons.alt_route_rounded,
                          color: AppColors.primary, index: 0)),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                          label: 'Students',
                          value: '$totalStudents',
                          icon: Icons.people_alt_rounded,
                          color: AppColors.accent, index: 1)),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(
                          label: 'Active Buses',
                          value: '$activeBuses',
                          icon: Icons.directions_bus_rounded,
                          color: AppColors.warning, index: 2)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _RoutesTabView(
                          routes: routes,
                          expandedRoutes: _expandedRoutes,
                          onToggle: (id) => setState(() {
                            if (_expandedRoutes.contains(id)) {
                              _expandedRoutes.remove(id);
                            } else {
                              _expandedRoutes.add(id);
                            }
                          }),
                        ),
                        _AssignmentsTabView(
                          assignments: filtered,
                          classFilter: _classFilter,
                          onClassFilter: (v) => setState(() => _classFilter = v),
                          onSearch: (v) => setState(() => _search = v),
                        ),
                        _TrackingTabView(routes: routes),
                      ],
                    ),
                  ),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Routes Tab ─────────────────────────────────────────────────────────────────

class _RoutesTabView extends StatelessWidget {
  final List<dynamic> routes;
  final Set<String> expandedRoutes;
  final ValueChanged<String> onToggle;

  const _RoutesTabView({
    required this.routes,
    required this.expandedRoutes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const Center(
          child: Text('No routes configured', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: routes.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final id = r['id'].toString();
        final expanded = expandedRoutes.contains(id);
        final stops = List<String>.from(
            (r['stops'] ?? []).map((s) => s is Map ? (s['name'] ?? s.toString()) : s.toString()));
        final studentsCount = r['students_count'] ?? r['student_count'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                InkWell(
                  onTap: () => onToggle(id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_bus_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['name'] ?? 'Route ${i + 1}',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.schedule_rounded, color: AppColors.textHint, size: 13),
                            const SizedBox(width: 4),
                            Text(r['departure_time'] ?? '',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on_rounded, color: AppColors.textHint, size: 13),
                            const SizedBox(width: 4),
                            Text('${stops.length} stops',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.people_rounded, color: AppColors.textHint, size: 13),
                            const SizedBox(width: 4),
                            Text('$studentsCount students',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ]),
                          if ((r['driver'] ?? r['driver_name'] ?? '').toString().isNotEmpty)
                            Text('Driver: ${r['driver'] ?? r['driver_name']}',
                                style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                        ]),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textHint),
                      ),
                    ]),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState:
                      expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: stops.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No stops defined',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            border: Border(
                                top: BorderSide(color: Colors.white.withOpacity(0.06))),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stops',
                                  style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ...stops.asMap().entries.map((se) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('${se.key + 1}',
                                              style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        se.value,
                                        style: TextStyle(
                                          color: se.key == stops.length - 1
                                              ? AppColors.accent
                                              : AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: se.key == stops.length - 1
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ]),
                                  )),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
        );
      }).toList(),
    );
  }
}

// ── Assignments Tab ────────────────────────────────────────────────────────────

class _AssignmentsTabView extends StatelessWidget {
  final List<dynamic> assignments;
  final String classFilter;
  final ValueChanged<String> onClassFilter;
  final ValueChanged<String> onSearch;

  const _AssignmentsTabView({
    required this.assignments,
    required this.classFilter,
    required this.onClassFilter,
    required this.onSearch,
  });

  static const _avatarColors = [
    AppColors.primary, AppColors.accent, AppColors.roleTeacher,
    AppColors.roleParent, AppColors.roleAccountant, AppColors.warning,
  ];

  String _initials(dynamic a) {
    final name = a['student_name'] ?? '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
    final parts = name.toString().split(' ');
    return parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.toString().isNotEmpty
            ? name.toString()[0].toUpperCase()
            : '?';
  }

  @override
  Widget build(BuildContext context) {
    const classes = ['All', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(children: [
          AppSearchField(hint: 'Search students...', onChanged: onSearch),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: classes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = classes[i];
                final active = classFilter == c;
                return GestureDetector(
                  onTap: () => onClassFilter(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surface2,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(c,
                        style: TextStyle(
                            color: active ? Colors.white : AppColors.textSecondary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      Expanded(
        child: assignments.isEmpty
            ? const Center(
                child: Text('No assignments found',
                    style: TextStyle(color: AppColors.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: assignments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final a = assignments[i];
                  final name = a['student_name'] ??
                      '${a['first_name'] ?? ''} ${a['last_name'] ?? ''}'.trim();
                  final className = a['class_name'] ?? a['class'] ?? '';
                  final routeName = a['route_name'] ?? a['route'] ?? '';
                  final stopName = a['stop_name'] ?? a['stop'] ?? '';

                  return GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      AvatarWidget(
                          initials: _initials(a),
                          color: _avatarColors[i % _avatarColors.length],
                          size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(name.toString(),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                          Text(className.toString(),
                              style: const TextStyle(
                                  color: AppColors.textHint, fontSize: 12)),
                          const SizedBox(height: 4),
                          if (routeName.toString().isNotEmpty)
                            Row(children: [
                              const Icon(Icons.directions_bus_rounded,
                                  color: AppColors.primary, size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(routeName.toString(),
                                      style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12),
                                      overflow: TextOverflow.ellipsis)),
                            ]),
                          if (stopName.toString().isNotEmpty)
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.accent, size: 13),
                              const SizedBox(width: 4),
                              Text(stopName.toString(),
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                            ]),
                        ]),
                      ),
                    ]),
                  ).animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
                },
              ),
      ),
    ]);
  }
}

// ── Tracking Tab ──────────────────────────────────────────────────────────────

class _TrackingTabView extends StatelessWidget {
  final List<dynamic> routes;
  const _TrackingTabView({required this.routes});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        GlassCard(
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 14),
            const Text('Live Tracking',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 6),
            const Text(
              'Real-time GPS tracking coming soon.\nRoutes will appear live on map.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Text('Under Development',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          ]),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Routes Status'),
        const SizedBox(height: 12),
        ...routes.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final status = r['status'] ?? 'inactive';
          final statusLabel = status.toString()[0].toUpperCase() +
              status.toString().substring(1).replaceAll('_', ' ');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: _trackingColor(statusLabel),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: _trackingColor(statusLabel).withOpacity(0.4),
                          blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(r['name'] ?? 'Route ${i + 1}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                StatusBadge(label: statusLabel, color: _trackingColor(statusLabel)),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
        }),
      ],
    );
  }
}
