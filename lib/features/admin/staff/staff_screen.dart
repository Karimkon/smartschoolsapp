import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Staff {
  final int id;
  final String name, role, department, phone, email, status;
  const _Staff({required this.id, required this.name, required this.role,
    required this.department, required this.phone, required this.email, required this.status});
  String get initials { final p = name.split(' '); return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : name[0]; }
}

const _mockStaff = [
  _Staff(id:1, name:'John Kamau',     role:'Accountant',       department:'Finance',      phone:'+254 700 111001', email:'j.kamau@school.ke',     status:'Active'),
  _Staff(id:2, name:'Mary Akinyi',    role:'Secretary',        department:'Admin',        phone:'+254 700 111002', email:'m.akinyi@school.ke',    status:'Active'),
  _Staff(id:3, name:'Robert Njoroge', role:'Driver',           department:'Transport',    phone:'+254 700 111003', email:'r.njoroge@school.ke',   status:'Active'),
  _Staff(id:4, name:'Alice Waweru',   role:'Librarian',        department:'Library',      phone:'+254 700 111004', email:'a.waweru@school.ke',    status:'Active'),
  _Staff(id:5, name:'Samuel Otieno',  role:'Security Guard',   department:'Security',     phone:'+254 700 111005', email:'s.otieno@school.ke',    status:'Active'),
  _Staff(id:6, name:'Catherine Meli', role:'Nurse',            department:'Medical',      phone:'+254 700 111006', email:'c.meli@school.ke',      status:'Active'),
  _Staff(id:7, name:'George Oloo',    role:'Groundskeeper',    department:'Maintenance',  phone:'+254 700 111007', email:'g.oloo@school.ke',      status:'On Leave'),
  _Staff(id:8, name:'Esther Naliaka', role:'Lab Technician',   department:'Sciences',     phone:'+254 700 111008', email:'e.naliaka@school.ke',   status:'Active'),
];

const _depts = ['All','Finance','Admin','Transport','Library','Security','Medical','Maintenance','Sciences'];

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _dept = 'All';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Staff> get _filtered => _mockStaff.where((s) {
    final md = _dept == 'All' || s.department == _dept;
    final mq = _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()) || s.role.toLowerCase().contains(_query.toLowerCase());
    return md && mq;
  }).toList();

  static const _colors = [AppColors.primary, AppColors.roleAccountant, AppColors.accent, AppColors.success, AppColors.warning, AppColors.roleTeacher];
  Color _color(int i) => _colors[i % _colors.length];
  Color _statusColor(String s) => s == 'Active' ? AppColors.success : s == 'On Leave' ? AppColors.warning : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final staff = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Row(children: [
          const Text('Staff', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.roleAccountant.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${_mockStaff.length}', style: const TextStyle(color: AppColors.roleAccountant, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        actions: [IconButton(icon: const Icon(Icons.person_add_rounded, color: AppColors.textSecondary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,0),
            child: Column(children: [
              AppSearchField(hint: 'Search staff by name or role...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
              const SizedBox(height: 12),
              SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: _depts.map((d) {
                final sel = d == _dept;
                return Padding(padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(onTap: () => setState(() => _dept = d),
                    child: AnimatedContainer(duration: 200.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.roleAccountant : AppColors.surface2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.roleAccountant : Colors.white.withOpacity(0.07)),
                      ),
                      child: Text(d, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  ),
                );
              }).toList())).animate(delay: 100.ms).fadeIn(),
            ]),
          ),
          Expanded(child: staff.isEmpty
            ? const Center(child: Text('No staff found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,12,16,80),
                itemCount: staff.length,
                itemBuilder: (ctx, i) {
                  final s = staff[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        AvatarWidget(initials: s.initials, color: _color(i), size: 50),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                            StatusBadge(label: s.status, color: _statusColor(s.status)),
                          ]),
                          const SizedBox(height: 3),
                          Text(s.role, style: TextStyle(fontSize: 12, color: _color(i), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.domain_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(s.department, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.phone_rounded, size: 11, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(s.phone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ]),
                        ])),
                      ]),
                    ),
                  ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                },
              ),
          ),
        ]),
      ),
    );
  }
}
