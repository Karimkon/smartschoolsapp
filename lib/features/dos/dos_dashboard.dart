import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/services/api_service.dart';
import 'package:smartschools/core/utils/safe_num.dart';

final dosDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/dashboard');
  return Map<String, dynamic>.from(res.data);
});

class DosDashboard extends ConsumerWidget {
  const DosDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user  = ref.watch(currentUserProvider);
    final async = ref.watch(dosDashboardProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (_, __) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                const Text('Could not load dashboard'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => ref.refresh(dosDashboardProvider), child: const Text('Retry')),
              ]),
            ),
            data: (data) => _buildContent(context, user?.name ?? 'DOS', data, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, String name, Map data, WidgetRef ref) {
    final stats      = Map<String, dynamic>.from(data['stats'] ?? {});
    final stuAtt     = Map<String, dynamic>.from(data['student_attendance_today'] ?? {});
    final tchAtt     = Map<String, dynamic>.from(data['teacher_attendance_today'] ?? {});
    final classAtt   = (data['class_attendance'] as List? ?? []).cast<Map>();
    final quickActs  = (data['quick_actions']    as List? ?? []).cast<Map>();
    final absent     = (tchAtt['absent'] as List? ?? []).cast<Map>();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface1,
      onRefresh: () async => ref.refresh(dosDashboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Good day,', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              Text('Dean of Studies', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ])),
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.15),
              radius: 24,
              child: const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 28),
            ),
          ]).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 20),

          // ── Stats Row ─────────────────────────────────────────────────────────
          Row(children: [
            _StatCard(label: 'Students', value: '${stats['students'] ?? 0}', icon: Icons.school_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            _StatCard(label: 'Teachers', value: '${stats['teachers'] ?? 0}', icon: Icons.people_rounded, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            _StatCard(label: 'Classes', value: '${stats['classes'] ?? 0}', icon: Icons.class_rounded, color: const Color(0xFF047857)),
          ]).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 16),

          // ── Today's Student Attendance ────────────────────────────────────────
          _SectionCard(
            title: "Student Attendance Today",
            icon: Icons.how_to_reg_rounded,
            iconColor: AppColors.primary,
            child: Column(children: [
              _AttRow(label: 'Present', value: '${stuAtt['present'] ?? 0}', color: const Color(0xFF059669)),
              _AttRow(label: 'Absent',  value: '${stuAtt['absent']  ?? 0}', color: const Color(0xFFDC2626)),
              _AttRow(label: 'Total',   value: '${stuAtt['total']   ?? 0}', color: AppColors.textSecondary),
              const SizedBox(height: 10),
              _PercentBar(pct: toD(stuAtt['pct'], 0), color: AppColors.primary),
            ]),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 12),

          // ── Today's Teacher Attendance ────────────────────────────────────────
          _SectionCard(
            title: "Teacher Attendance Today",
            icon: Icons.assignment_ind_rounded,
            iconColor: const Color(0xFF7C3AED),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: _AttRow(label: 'Present', value: '${tchAtt['present'] ?? 0}', color: const Color(0xFF059669))),
                Expanded(child: _AttRow(label: 'Total',   value: '${tchAtt['total']   ?? 0}', color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 8),
              _PercentBar(pct: toD(tchAtt['pct'], 0), color: const Color(0xFF7C3AED)),
              if (absent.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Absent Today:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                ...absent.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.person_off_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text(t['name']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
                    const Spacer(),
                    Text(t['employee_id']?.toString() ?? '', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                )),
              ],
            ]),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          // ── Class Attendance Breakdown ────────────────────────────────────────
          if (classAtt.isNotEmpty)
            _SectionCard(
              title: "Attendance by Class",
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF047857),
              child: Column(children: classAtt.take(8).map((cls) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(width: 90, child: Text(cls['class']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis))),
                  const SizedBox(width: 8),
                  Expanded(child: LinearProgressIndicator(
                    value: (toD(cls['pct'], 0)) / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: _attColor(toD(cls['pct'], 0)),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  )),
                  const SizedBox(width: 8),
                  Text('${cls['pct']}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _attColor(toD(cls['pct'], 0)))),
                ]),
              )).toList()),
            ).animate().fadeIn(delay: 250.ms),

          const SizedBox(height: 16),

          // ── Quick Actions ─────────────────────────────────────────────────────
          Text('Quick Actions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: [
              _QuickAction(label: 'Student Attendance', icon: Icons.calendar_today_rounded, color: AppColors.primary,        onTap: () => context.push('/dos/attendance')),
              _QuickAction(label: 'Teacher Attendance', icon: Icons.how_to_reg_rounded,     color: const Color(0xFF7C3AED), onTap: () => context.push('/dos/attendance')),
              _QuickAction(label: 'Report Cards',       icon: Icons.assessment_rounded,     color: const Color(0xFF047857), onTap: () => context.push('/dos/report-cards')),
              _QuickAction(label: 'Students',           icon: Icons.school_rounded,         color: const Color(0xFF1D4ED8), onTap: () => context.push('/dos/students')),
            ],
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Color _attColor(double pct) {
    if (pct >= 80) return const Color(0xFF059669);
    if (pct >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surface3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.iconColor, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface1, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.surface3)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
      const SizedBox(height: 12),
      child,
    ]),
  );
}

class _AttRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AttRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    const Spacer(),
    Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
  ]);
}

class _PercentBar extends StatelessWidget {
  final double pct;
  final Color color;
  const _PercentBar({required this.pct, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: pct / 100,
        backgroundColor: Colors.grey.shade100,
        color: color,
        minHeight: 8,
      ),
    ),
    const SizedBox(height: 4),
    Text('${pct.toStringAsFixed(0)}% attendance', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}
