import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Branch {
  final int id;
  final String name, address, principal, phone, status;
  final int students, teachers;
  const _Branch({required this.id, required this.name, required this.address, required this.principal,
    required this.phone, required this.status, required this.students, required this.teachers});
}

const _mockBranches = [
  _Branch(id:1, name:'Main Campus',       address:'123 School Road, Nairobi', principal:'Dr. James Mwenda',  phone:'+254 700 100001', status:'Active', students:842, teachers:58),
  _Branch(id:2, name:'Westlands Branch',  address:'45 Waiyaki Way, Nairobi',  principal:'Ms. Grace Aoko',   phone:'+254 700 100002', status:'Active', students:320, teachers:24),
  _Branch(id:3, name:'Eastlands Branch',  address:'89 Outer Ring Rd, Nairobi',principal:'Mr. Peter Lule',   phone:'+254 700 100003', status:'Active', students:215, teachers:18),
  _Branch(id:4, name:'Mombasa Branch',    address:'12 Nyali Rd, Mombasa',     principal:'Mrs. Fatuma Ali',  phone:'+254 700 100004', status:'Inactive',students:0, teachers:0),
];

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});
  @override State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Branches / Campuses', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.add_business_rounded, color: AppColors.primary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _mockBranches.length,
          itemBuilder: (ctx, i) {
            final b = _mockBranches[i];
            final color = [AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.textHint][i % 4];
            return Padding(padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 48, height: 48,
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(i == 0 ? Icons.account_balance_rounded : Icons.business_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(b.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(b.address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ])),
                    StatusBadge(label: b.status, color: b.status == 'Active' ? AppColors.success : AppColors.textHint),
                  ]),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Expanded(child: _InfoTile(Icons.person_rounded, 'Principal', b.principal, color)),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoTile(Icons.phone_rounded, 'Phone', b.phone, AppColors.success)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _StatBox('Students', '${b.students}', AppColors.primary)),
                    const SizedBox(width: 10),
                    Expanded(child: _StatBox('Teachers', '${b.teachers}', AppColors.roleTeacher)),
                  ]),
                ]),
              ),
            ).animate(delay: Duration(milliseconds: i * 80)).fadeIn().slideY(begin: 0.1, end: 0);
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _InfoTile(this.icon, this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, size: 14, color: color),
    const SizedBox(width: 6),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
      Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
    ])),
  ]);
}

class _StatBox extends StatelessWidget {
  final String label, value; final Color color;
  const _StatBox(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}
