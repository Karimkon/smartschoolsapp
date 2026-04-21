import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _Parent {
  final int id;
  final String name, phone, email, relation;
  final List<String> children;
  const _Parent({required this.id, required this.name, required this.phone, required this.email, required this.relation, required this.children});
  String get initials { final p = name.split(' '); return p.length >= 2 ? '${p[0][0]}${p[1][0]}' : name[0]; }
}

const _mockParents = [
  _Parent(id:1, name:'Mr. Francis Osei',   phone:'+254 722 001001', email:'f.osei@gmail.com',   relation:'Father', children:['Amara Osei (Grade 7A)', 'Kwame Osei (Grade 9B)']),
  _Parent(id:2, name:'Mrs. Agnes Mwangi',  phone:'+254 722 002002', email:'a.mwangi@gmail.com', relation:'Mother', children:['Brian Mwangi (Grade 8B)']),
  _Parent(id:3, name:'Mr. Samuel Kamau',   phone:'+254 722 003003', email:'s.kamau@gmail.com',  relation:'Father', children:['Diana Kamau (Grade 7B)']),
  _Parent(id:4, name:'Mrs. Faith Okonkwo', phone:'+254 722 004004', email:'f.okon@gmail.com',   relation:'Mother', children:['Chidi Okonkwo (Grade 9A)']),
  _Parent(id:5, name:'Mr. James Ssali',    phone:'+254 722 005005', email:'j.ssali@gmail.com',  relation:'Father', children:['Emmanuel Ssali (Grade 10A)', 'Joy Ssali (Grade 8A)']),
  _Parent(id:6, name:'Mrs. Halima Juma',   phone:'+254 722 006006', email:'h.juma@gmail.com',   relation:'Mother', children:['Halima Juma (Grade 9B)']),
  _Parent(id:7, name:'Mr. Peter Hassan',   phone:'+254 722 007007', email:'p.hassan@gmail.com', relation:'Father', children:['Fatima Hassan (Grade 8A)']),
];

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});
  @override State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<_Parent> get _filtered => _mockParents.where((p) =>
    _query.isEmpty || p.name.toLowerCase().contains(_query.toLowerCase()) ||
    p.phone.contains(_query) || p.children.any((c) => c.toLowerCase().contains(_query.toLowerCase()))
  ).toList();

  static const _colors = [AppColors.roleParent, AppColors.primary, AppColors.accent, AppColors.roleTeacher, AppColors.success];
  Color _color(int i) => _colors[i % _colors.length];

  @override
  Widget build(BuildContext context) {
    final parents = _filtered;
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Row(children: [
          const Text('Parents', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(width: 10),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: AppColors.roleParent.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text('${_mockParents.length}', style: const TextStyle(color: AppColors.roleParent, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
        actions: [IconButton(icon: const Icon(Icons.person_add_rounded, color: AppColors.textSecondary), onPressed: () {})],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16,16,16,12),
            child: AppSearchField(hint: 'Search parent or child name...', controller: _searchCtrl, onChanged: (v) => setState(() => _query = v)).animate().fadeIn(),
          ),
          Expanded(child: parents.isEmpty
            ? const Center(child: Text('No parents found', style: TextStyle(color: AppColors.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16,0,16,80),
                itemCount: parents.length,
                itemBuilder: (ctx, i) {
                  final p = parents[i];
                  return Padding(padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(padding: const EdgeInsets.all(14),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        AvatarWidget(initials: p.initials, color: _color(i), size: 50),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                            StatusBadge(label: p.relation, color: _color(i)),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.phone_rounded, size: 12, color: AppColors.textHint), const SizedBox(width: 4),
                            Text(p.phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 6),
                          const Text('Children:', style: TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          ...p.children.map((c) => Row(children: [
                            Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6, top: 2), decoration: BoxDecoration(color: _color(i), shape: BoxShape.circle)),
                            Expanded(child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                          ])),
                        ])),
                        Column(children: [
                          _IBtn(Icons.phone_rounded, AppColors.success, () {}),
                          const SizedBox(height: 6),
                          _IBtn(Icons.message_rounded, AppColors.primary, () {}),
                        ]),
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

class _IBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _IBtn(this.icon, this.color, this.onTap);
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 15)));
}
