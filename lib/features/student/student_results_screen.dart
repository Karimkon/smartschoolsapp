import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _SubjectResult {
  final String subject;
  final int marks;
  final String grade;
  final Color color;
  const _SubjectResult(this.subject, this.marks, this.grade, this.color);
}

class _TermResult {
  final String term;
  final String gpa;
  final int position;
  final int totalStudents;
  final List<_SubjectResult> subjects;

  const _TermResult({
    required this.term, required this.gpa, required this.position,
    required this.totalStudents, required this.subjects,
  });

  int get average => subjects.isEmpty ? 0 : subjects.map((s) => s.marks).reduce((a, b) => a + b) ~/ subjects.length;
}

const _termResults = [
  _TermResult(
    term: 'Term 1, 2025',
    gpa: 'B+',
    position: 5,
    totalStudents: 32,
    subjects: [
      _SubjectResult('Mathematics', 82, 'B+', AppColors.primary),
      _SubjectResult('English',     76, 'B',  AppColors.roleTeacher),
      _SubjectResult('Science',     88, 'A',  AppColors.accent),
      _SubjectResult('History',     71, 'B',  AppColors.warning),
      _SubjectResult('Kiswahili',   79, 'B+', AppColors.roleAccountant),
      _SubjectResult('Geography',   74, 'B',  AppColors.success),
    ],
  ),
  _TermResult(
    term: 'Term 2, 2025',
    gpa: 'A-',
    position: 3,
    totalStudents: 32,
    subjects: [
      _SubjectResult('Mathematics', 87, 'A',  AppColors.primary),
      _SubjectResult('English',     80, 'B+', AppColors.roleTeacher),
      _SubjectResult('Science',     92, 'A+', AppColors.accent),
      _SubjectResult('History',     75, 'B+', AppColors.warning),
      _SubjectResult('Kiswahili',   83, 'A-', AppColors.roleAccountant),
      _SubjectResult('Geography',   78, 'B+', AppColors.success),
    ],
  ),
  _TermResult(
    term: 'Term 3, 2024',
    gpa: 'B',
    position: 8,
    totalStudents: 32,
    subjects: [
      _SubjectResult('Mathematics', 74, 'B',  AppColors.primary),
      _SubjectResult('English',     68, 'C+', AppColors.roleTeacher),
      _SubjectResult('Science',     80, 'B+', AppColors.accent),
      _SubjectResult('History',     65, 'C+', AppColors.warning),
      _SubjectResult('Kiswahili',   72, 'B',  AppColors.roleAccountant),
      _SubjectResult('Geography',   70, 'B',  AppColors.success),
    ],
  ),
];

const _gradeLegend = [
  ('A+', '90–100', AppColors.accent),
  ('A',  '80–89',  AppColors.success),
  ('A-', '75–79',  AppColors.success),
  ('B+', '70–74',  AppColors.primary),
  ('B',  '65–69',  AppColors.primary),
  ('C+', '60–64',  AppColors.warning),
  ('C',  '55–59',  AppColors.warning),
  ('D',  '50–54',  AppColors.error),
  ('F',  '0–49',   AppColors.error),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  int _selectedTermIdx = 0;

  _TermResult get _current => _termResults[_selectedTermIdx];

  Color _gradeColor(String g) {
    if (g.startsWith('A')) return AppColors.success;
    if (g.startsWith('B')) return AppColors.primary;
    if (g.startsWith('C')) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final term = _current;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('My Results', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Term selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedTermIdx,
                  isExpanded: true,
                  dropdownColor: AppColors.surface1,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                  items: List.generate(_termResults.length, (i) => DropdownMenuItem(
                    value: i,
                    child: Text(_termResults[i].term),
                  )),
                  onChanged: (v) { if (v != null) setState(() => _selectedTermIdx = v); },
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 16),

            // GPA + Position card
            GlassCard(
              gradient: AppColors.primaryGradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Grade', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(term.gpa, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Average: ${term.average}%', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '#${term.position}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      Text(
                        'of ${term.totalStudents}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),

            const SizedBox(height: 20),

            SectionHeader(title: 'Subject Results (${term.term})').animate(delay: 150.ms).fadeIn(),
            const SizedBox(height: 12),

            // Subject results
            ...term.subjects.asMap().entries.map((e) {
              final s = e.value;
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: _gradeColor(s.grade).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            s.grade,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _gradeColor(s.grade)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.marks / 100,
                                minHeight: 6,
                                backgroundColor: AppColors.surface3,
                                valueColor: AlwaysStoppedAnimation<Color>(_gradeColor(s.grade)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${s.marks}%',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _gradeColor(s.grade)),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: Duration(milliseconds: 200 + i * 60)).fadeIn().slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 20),

            // Grade legend
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Grade Legend'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _gradeLegend.map((item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.$3.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: item.$3.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.$1, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.$3)),
                          const SizedBox(width: 6),
                          Text(item.$2, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ).animate(delay: 500.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
