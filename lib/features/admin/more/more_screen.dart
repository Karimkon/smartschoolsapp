import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Data model ────────────────────────────────────────────────────────────────
class _FeatureTile {
  final String label;
  final String route;
  final IconData icon;
  final Color color;
  const _FeatureTile(this.label, this.route, this.icon, this.color);
}

class _FeatureSection {
  final String title;
  final Color accentColor;
  final List<_FeatureTile> tiles;
  const _FeatureSection(this.title, this.accentColor, this.tiles);
}

// ── Screen ────────────────────────────────────────────────────────────────────
class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const List<_FeatureSection> _sections = [
    _FeatureSection('PEOPLE', AppColors.primary, [
      _FeatureTile('Students',  '/admin/students',  Icons.people_rounded,          Color(0xFF2563EB)),
      _FeatureTile('Teachers',  '/admin/teachers',  Icons.person_pin_rounded,       Color(0xFF7C3AED)),
      _FeatureTile('Staff',     '/admin/staff',     Icons.badge_rounded,            Color(0xFF06D6A0)),
      _FeatureTile('Parents',   '/admin/parents',   Icons.family_restroom_rounded,  Color(0xFFF59E0B)),
      _FeatureTile('Classes',   '/admin/classes',   Icons.class_rounded,            Color(0xFF3B82F6)),
      _FeatureTile('Branches',  '/admin/branches',  Icons.account_tree_rounded,     Color(0xFF8B5CF6)),
    ]),
    _FeatureSection('ACADEMICS', Color(0xFF7C3AED), [
      _FeatureTile('Timetable',      '/admin/timetable',    Icons.calendar_month_rounded,  Color(0xFF2563EB)),
      _FeatureTile('Assignments',    '/admin/assignments',  Icons.assignment_rounded,       Color(0xFF7C3AED)),
      _FeatureTile('Exams',          '/admin/exams',        Icons.quiz_rounded,             Color(0xFFF59E0B)),
      _FeatureTile('Report Cards',   '/admin/report-cards', Icons.school_rounded,           Color(0xFF10B981)),
      _FeatureTile('Marks Entry',    '/admin/marks',        Icons.edit_note_rounded,        Color(0xFF06D6A0)),
      _FeatureTile('Study Materials','/admin/materials',    Icons.menu_book_rounded,        Color(0xFFEF4444)),
    ]),
    _FeatureSection('FINANCE', AppColors.success, [
      _FeatureTile('Fees',         '/admin/fees',         Icons.account_balance_wallet_rounded, Color(0xFF10B981)),
      _FeatureTile('Expenses',     '/admin/expenses',     Icons.receipt_long_rounded,            Color(0xFFEF4444)),
      _FeatureTile('Payroll',      '/admin/payroll',      Icons.payments_rounded,                Color(0xFFEC4899)),
      _FeatureTile('Requirements', '/admin/requirements', Icons.checklist_rounded,               Color(0xFFF59E0B)),
    ]),
    _FeatureSection('ATTENDANCE', AppColors.primary, [
      _FeatureTile('Daily Attendance', '/admin/attendance',        Icons.fact_check_rounded,   Color(0xFF2563EB)),
      _FeatureTile('Leave Management', '/admin/leave',             Icons.event_busy_rounded,   Color(0xFFEF4444)),
      _FeatureTile('Biometric/QR',     '/admin/biometric',         Icons.fingerprint_rounded,  Color(0xFF06D6A0)),
      _FeatureTile('Att. Reports',     '/admin/attendance-reports',Icons.analytics_rounded,    Color(0xFF7C3AED)),
    ]),
    _FeatureSection('OPERATIONS', AppColors.warning, [
      _FeatureTile('Library',      '/admin/library',      Icons.local_library_rounded,  Color(0xFFEF4444)),
      _FeatureTile('Transport',    '/admin/transport',    Icons.directions_bus_rounded,  Color(0xFFF59E0B)),
      _FeatureTile('Inventory',    '/admin/inventory',    Icons.inventory_2_rounded,     Color(0xFF06D6A0)),
      _FeatureTile('ID Cards',     '/admin/id-cards',     Icons.badge_rounded,           Color(0xFF2563EB)),
      _FeatureTile('Disciplinary', '/admin/disciplinary', Icons.gavel_rounded,           Color(0xFFEF4444)),
    ]),
    _FeatureSection('COMMUNICATION & RECEPTION', Color(0xFF2563EB), [
      _FeatureTile('Announcements', '/admin/announcements', Icons.campaign_rounded,      Color(0xFF2563EB)),
      _FeatureTile('Events',        '/admin/events',        Icons.event_rounded,         Color(0xFF7C3AED)),
      _FeatureTile('Reception',     '/admin/reception',     Icons.desk_rounded,          Color(0xFF10B981)),
      _FeatureTile('Admissions',    '/admin/admissions',    Icons.how_to_reg_rounded,    Color(0xFFF59E0B)),
    ]),
    _FeatureSection('SETTINGS', AppColors.textHint, [
      _FeatureTile('School Settings', '/admin/settings',     Icons.settings_rounded, Color(0xFF475569)),
      _FeatureTile('SMS Settings',    '/admin/sms-settings', Icons.sms_rounded,      Color(0xFF06D6A0)),
    ]),
  ];

  List<_FeatureSection> get _filtered {
    if (_query.isEmpty) return _sections;
    final q = _query.toLowerCase();
    final result = <_FeatureSection>[];
    for (final s in _sections) {
      final tiles = s.tiles.where((t) => t.label.toLowerCase().contains(q)).toList();
      if (tiles.isNotEmpty) result.add(_FeatureSection(s.title, s.accentColor, tiles));
    }
    return result;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
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
                        'All Features',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search_rounded,
                          color: AppColors.textSecondary, size: 24),
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: _FeatureSearchDelegate(_sections, context),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Search bar (inline) ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: AppSearchField(
                  hint: 'Search features...',
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, si) {
                    final section = filtered[si];
                    return _SectionBlock(
                      section: section,
                      sectionIndex: si,
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

// ── Section Block ─────────────────────────────────────────────────────────────
class _SectionBlock extends StatelessWidget {
  final _FeatureSection section;
  final int sectionIndex;

  const _SectionBlock({required this.section, required this.sectionIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Section header with colored left bar
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: section.accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              section.title,
              style: TextStyle(
                color: section.accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ],
        )
            .animate(delay: Duration(milliseconds: sectionIndex * 60))
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 12),
        // Tiles in Wrap — 4 per row
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(section.tiles.length, (ti) {
            final tile = section.tiles[ti];
            final globalIndex = sectionIndex * 6 + ti;
            return _FeatureTileWidget(
              tile: tile,
              index: globalIndex,
            );
          }),
        ),
      ],
    );
  }
}

// ── Feature Tile Widget ───────────────────────────────────────────────────────
class _FeatureTileWidget extends StatelessWidget {
  final _FeatureTile tile;
  final int index;

  const _FeatureTileWidget({required this.tile, required this.index});

  @override
  Widget build(BuildContext context) {
    // 4 per row: (screenWidth - 40 padding - 3*10 spacing) / 4
    final width = (MediaQuery.of(context).size.width - 40 - 30) / 4;

    return GestureDetector(
      onTap: () {
        try {
          context.push(tile.route);
        } catch (_) {
          // Route may not be registered yet — silently ignore in dev
        }
      },
      child: SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: tile.color.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tile.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tile.icon, color: tile.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                tile.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 30))
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Search Delegate ───────────────────────────────────────────────────────────
class _FeatureSearchDelegate extends SearchDelegate<String> {
  final List<_FeatureSection> sections;
  final BuildContext parentContext;

  _FeatureSearchDelegate(this.sections, this.parentContext);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textHint),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final results = <_FeatureTile>[];
    for (final s in sections) {
      for (final t in s.tiles) {
        if (t.label.toLowerCase().contains(q)) results.add(t);
      }
    }
    if (results.isEmpty) {
      return const Center(
        child: Text('No features found',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Container(
      color: AppColors.bgDark,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (ctx, i) {
          final t = results[i];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(t.icon, color: t.color, size: 20),
            ),
            title: Text(t.label,
                style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(t.route,
                style: const TextStyle(
                    color: AppColors.textHint, fontSize: 11)),
            onTap: () {
              close(context, t.route);
              try {
                parentContext.push(t.route);
              } catch (_) {}
            },
          );
        },
      ),
    );
  }
}
