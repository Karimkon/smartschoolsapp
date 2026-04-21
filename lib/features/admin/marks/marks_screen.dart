import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

class _StudentMark {
  final String name;
  int? score;
  _StudentMark({required this.name, this.score});
  String get grade {
    if (score == null) return '-';
    if (score! >= 80) return 'A';
    if (score! >= 65) return 'B';
    if (score! >= 50) return 'C';
    if (score! >= 35) return 'D';
    return 'F';
  }
  Color get gradeColor {
    if (score == null) return AppColors.textHint;
    if (score! >= 80) return AppColors.success;
    if (score! >= 65) return AppColors.primary;
    if (score! >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

const _classes = ['Grade 7A', 'Grade 7B', 'Grade 8A', 'Grade 8B', 'Grade 9A'];
const _subjects = ['Mathematics', 'English', 'Science', 'History', 'Kiswahili', 'Geography'];
const _exams = ['Mid-Term 1', 'End of Term 1', 'CAT 1', 'CAT 2'];

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key});
  @override State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  String _class = 'Grade 7A';
  String _subject = 'Mathematics';
  String _exam = 'Mid-Term 1';
  bool _saving = false;

  final List<_StudentMark> _students = [
    _StudentMark(name: 'Amara Osei',     score: 78),
    _StudentMark(name: 'Brian Mwangi',   score: 65),
    _StudentMark(name: 'Chloe Wanjiru',  score: 91),
    _StudentMark(name: 'David Kamau',    score: 54),
    _StudentMark(name: 'Esther Auko',    score: 82),
    _StudentMark(name: 'Faith Otieno',   score: null),
    _StudentMark(name: 'George Lule',    score: 47),
    _StudentMark(name: 'Hannah Juma',    score: 88),
  ];

  int get _entered => _students.where((s) => s.score != null).length;
  double get _avg {
    final scored = _students.where((s) => s.score != null).toList();
    if (scored.isEmpty) return 0;
    return scored.map((s) => s.score!).reduce((a, b) => a + b) / scored.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Marks Entry', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : () async {
              setState(() => _saving = true);
              await Future.delayed(const Duration(seconds: 1));
              setState(() => _saving = false);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marks saved!'), backgroundColor: AppColors.success));
            },
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(children: [
          // Selectors
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _DropdownRow('Class', _classes, _class, (v) => setState(() => _class = v!)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _DropdownRow('Subject', _subjects, _subject, (v) => setState(() => _subject = v!))),
                const SizedBox(width: 10),
                Expanded(child: _DropdownRow('Exam', _exams, _exam, (v) => setState(() => _exam = v!))),
              ]),
              const SizedBox(height: 10),
              // Summary row
              GlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _StatMini('Entered', '$_entered/${_students.length}', AppColors.primary),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _StatMini('Average', '${_avg.toStringAsFixed(1)}%', AppColors.success),
                  Container(width: 1, height: 30, color: Colors.white12),
                  _StatMini('Pending', '${_students.length - _entered}', AppColors.warning),
                ]),
              ).animate(delay: 150.ms).fadeIn(),
            ]).animate().fadeIn(),
          ),
          // Student marks table
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16,0,16,80),
              itemCount: _students.length,
              itemBuilder: (ctx, i) {
                final s = _students[i];
                return Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: GlassCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      AvatarWidget(initials: s.name[0], color: [AppColors.primary, AppColors.roleTeacher, AppColors.accent, AppColors.success][i % 4], size: 38),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        if (s.score != null)
                          Text('Grade: ${s.grade}', style: TextStyle(fontSize: 11, color: s.gradeColor, fontWeight: FontWeight.w600)),
                      ])),
                      SizedBox(width: 80,
                        child: TextFormField(
                          initialValue: s.score?.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: '0-100',
                            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                            filled: true, fillColor: AppColors.surface2,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (v) { final n = int.tryParse(v); setState(() => s.score = n != null ? n.clamp(0, 100) : null); },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: s.gradeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Center(child: Text(s.grade, style: TextStyle(color: s.gradeColor, fontSize: 13, fontWeight: FontWeight.w800))),
                      ),
                    ]),
                  ),
                ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05, end: 0);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;
  const _DropdownRow(this.label, this.items, this.value, this.onChanged);

  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.07))),
    child: Row(children: [
      Text('$label: ', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
      Expanded(child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: AppColors.surface1,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      )),
    ]),
  );
}

class _StatMini extends StatelessWidget {
  final String label, value; final Color color;
  const _StatMini(this.label, this.value, this.color);
  @override Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
  ]);
}
