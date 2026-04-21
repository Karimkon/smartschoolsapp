import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Route {
  final int id;
  final String name, departureTime, driver, driverPhone;
  final int studentsCount;
  final List<String> stops;
  bool expanded;

  _Route({
    required this.id,
    required this.name,
    required this.departureTime,
    required this.driver,
    required this.driverPhone,
    required this.studentsCount,
    required this.stops,
    this.expanded = false,
  });
}

class _StudentAssignment {
  final int id;
  final String name, className, routeName, stopName, initials;
  final Color avatarColor;

  const _StudentAssignment({
    required this.id,
    required this.name,
    required this.className,
    required this.routeName,
    required this.stopName,
    required this.initials,
    required this.avatarColor,
  });
}

class _TrackingStatus {
  final String routeName, status, lastUpdate;
  const _TrackingStatus({required this.routeName, required this.status, required this.lastUpdate});
}

final List<_Route> _mockRoutes = [
  _Route(
    id: 1, name: 'Route A – North Accra', departureTime: '6:30 AM',
    driver: 'Kwame Boateng', driverPhone: '+233 24 111 2222',
    studentsCount: 18,
    stops: ['Achimota', 'Legon', 'East Legon', 'Airport Res.', 'School'],
  ),
  _Route(
    id: 2, name: 'Route B – South Accra', departureTime: '6:45 AM',
    driver: 'Ama Serwaa', driverPhone: '+233 26 333 4444',
    studentsCount: 22,
    stops: ['Tema', 'Community 9', 'Sakumono', 'Spintex', 'School'],
  ),
  _Route(
    id: 3, name: 'Route C – West Accra', departureTime: '6:15 AM',
    driver: 'Kofi Owusu', driverPhone: '+233 20 555 6666',
    studentsCount: 15,
    stops: ['Dansoman', 'Kaneshie', 'Odorkor', 'Mataheko', 'School'],
  ),
];

const List<_StudentAssignment> _mockAssignments = [
  _StudentAssignment(id: 1, name: 'Amara Osei',      className: 'Grade 7A', routeName: 'Route A – North Accra', stopName: 'East Legon',  initials: 'AO', avatarColor: AppColors.primary),
  _StudentAssignment(id: 2, name: 'Brian Mwangi',     className: 'Grade 5B', routeName: 'Route B – South Accra', stopName: 'Community 9', initials: 'BM', avatarColor: AppColors.accent),
  _StudentAssignment(id: 3, name: 'Chidi Okonkwo',    className: 'Grade 9A', routeName: 'Route A – North Accra', stopName: 'Legon',       initials: 'CO', avatarColor: AppColors.roleTeacher),
  _StudentAssignment(id: 4, name: 'Diana Kamau',      className: 'Grade 6C', routeName: 'Route C – West Accra',  stopName: 'Kaneshie',    initials: 'DK', avatarColor: AppColors.roleParent),
  _StudentAssignment(id: 5, name: 'Emmanuel Ssali',   className: 'Grade 8B', routeName: 'Route B – South Accra', stopName: 'Spintex',     initials: 'ES', avatarColor: AppColors.roleAccountant),
  _StudentAssignment(id: 6, name: 'Fatima Hassan',    className: 'Grade 4A', routeName: 'Route C – West Accra',  stopName: 'Dansoman',    initials: 'FH', avatarColor: AppColors.warning),
];

const List<_TrackingStatus> _trackingStatuses = [
  _TrackingStatus(routeName: 'Route A – North Accra', status: 'On Route',  lastUpdate: '2 mins ago'),
  _TrackingStatus(routeName: 'Route B – South Accra', status: 'At School', lastUpdate: '5 mins ago'),
  _TrackingStatus(routeName: 'Route C – West Accra',  status: 'Completed', lastUpdate: '1 hr ago'),
];

Color _trackingColor(String s) {
  switch (s) {
    case 'On Route':  return AppColors.warning;
    case 'At School': return AppColors.success;
    default:          return AppColors.textHint;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminTransportScreen extends StatefulWidget {
  const AdminTransportScreen({super.key});

  @override
  State<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends State<AdminTransportScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late List<_Route> _routes;
  late List<_StudentAssignment> _assignments;
  String _classFilter = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _routes = List.from(_mockRoutes);
    _assignments = List.from(_mockAssignments);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<_StudentAssignment> get _filteredAssignments {
    return _assignments.where((a) {
      final matchClass  = _classFilter == 'All' || a.className.contains(_classFilter);
      final matchSearch = _search.isEmpty || a.name.toLowerCase().contains(_search.toLowerCase());
      return matchClass && matchSearch;
    }).toList();
  }

  int get _totalStudents => _mockRoutes.fold(0, (s, r) => s + r.studentsCount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Transport', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Routes'),
            Tab(text: 'Assignments'),
            Tab(text: 'Tracking'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: StatCard(label: 'Total Routes',       value: '${_mockRoutes.length}', icon: Icons.alt_route_rounded,      color: AppColors.primary,  index: 0)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Students Assigned',  value: '$_totalStudents',        icon: Icons.people_alt_rounded,     color: AppColors.accent,   index: 1)),
                    const SizedBox(width: 10),
                    Expanded(child: StatCard(label: 'Active Buses',        value: '2',                     icon: Icons.directions_bus_rounded, color: AppColors.warning,  index: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _RoutesTab(routes: _routes, onToggle: (id) => setState(() {
                      final idx = _routes.indexWhere((r) => r.id == id);
                      if (idx != -1) _routes[idx].expanded = !_routes[idx].expanded;
                    })),
                    _AssignmentsTab(
                      assignments: _filteredAssignments,
                      classFilter: _classFilter,
                      onClassFilter: (v) => setState(() => _classFilter = v),
                      onSearch: (v) => setState(() => _search = v),
                      onUnassign: (id) => setState(() => _assignments.removeWhere((a) => a.id == id)),
                    ),
                    const _TrackingTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Routes Tab ────────────────────────────────────────────────────────────────

class _RoutesTab extends StatelessWidget {
  final List<_Route> routes;
  final ValueChanged<int> onToggle;
  const _RoutesTab({required this.routes, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: routes.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                InkWell(
                  onTap: () => onToggle(r.id),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, color: AppColors.textHint, size: 13),
                                  const SizedBox(width: 4),
                                  Text(r.departureTime, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.location_on_rounded, color: AppColors.textHint, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${r.stops.length} stops', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.people_rounded, color: AppColors.textHint, size: 13),
                                  const SizedBox(width: 4),
                                  Text('${r.studentsCount} students', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('Driver: ${r.driver}', style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: r.expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: r.expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stops', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        ...r.stops.asMap().entries.map((se) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text('${se.key + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700))),
                              ),
                              const SizedBox(width: 10),
                              Text(se.value, style: TextStyle(color: se.key == r.stops.length - 1 ? AppColors.accent : AppColors.textSecondary, fontSize: 13, fontWeight: se.key == r.stops.length - 1 ? FontWeight.w700 : FontWeight.w500)),
                            ],
                          ),
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

// ── Assignments Tab ───────────────────────────────────────────────────────────

class _AssignmentsTab extends StatelessWidget {
  final List<_StudentAssignment> assignments;
  final String classFilter;
  final ValueChanged<String> onClassFilter;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onUnassign;

  const _AssignmentsTab({
    required this.assignments,
    required this.classFilter,
    required this.onClassFilter,
    required this.onSearch,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    const classes = ['All', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9'];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
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
                        child: Text(c, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            itemCount: assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final a = assignments[i];
              return GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    AvatarWidget(initials: a.initials, color: a.avatarColor, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(a.className, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 13),
                              const SizedBox(width: 4),
                              Expanded(child: Text(a.routeName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.accent, size: 13),
                              const SizedBox(width: 4),
                              Text(a.stopName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onUnassign(a.id),
                      icon: const Icon(Icons.link_off_rounded, color: AppColors.error, size: 20),
                      tooltip: 'Unassign',
                    ),
                  ],
                ),
              ).animate(delay: Duration(milliseconds: i * 60))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
            },
          ),
        ),
      ],
    );
  }
}

// ── Tracking Tab ──────────────────────────────────────────────────────────────

class _TrackingTab extends StatelessWidget {
  const _TrackingTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        GlassCard(
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              const Text('Live Tracking', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 6),
              const Text('Real-time GPS tracking coming soon.\nRoutes will appear live on map.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: const Text('Under Development', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Last Known Status'),
        const SizedBox(height: 12),
        ..._trackingStatuses.asMap().entries.map((e) {
          final i = e.key;
          final t = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _trackingColor(t.status),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _trackingColor(t.status).withOpacity(0.4), blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(t.routeName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  StatusBadge(label: t.status, color: _trackingColor(t.status)),
                  const SizedBox(width: 8),
                  Text(t.lastUpdate, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 80))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
          );
        }),
      ],
    );
  }
}
