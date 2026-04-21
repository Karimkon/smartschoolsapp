import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Assignment {
  final int id;
  final String title, subject, className, dueDate, status;
  final int submitted, total;
  final Color color;

  const _Assignment({
    required this.id, required this.title, required this.subject,
    required this.className, required this.dueDate, required this.status,
    required this.submitted, required this.total, required this.color,
  });
}

const _mockAssignments = [
  _Assignment(id: 1, title: 'Algebra Problem Set 5', subject: 'Mathematics', className: 'Grade 8A', dueDate: 'Apr 22, 2025', status: 'Active',    submitted: 18, total: 28, color: AppColors.primary),
  _Assignment(id: 2, title: 'Trigonometry Practice',  subject: 'Mathematics', className: 'Grade 9B', dueDate: 'Apr 25, 2025', status: 'Active',    submitted: 12, total: 25, color: AppColors.primary),
  _Assignment(id: 3, title: 'Calculus Introduction',  subject: 'Mathematics', className: 'Grade 10A',dueDate: 'Apr 15, 2025', status: 'Overdue',   submitted: 20, total: 30, color: AppColors.primary),
  _Assignment(id: 4, title: 'Geometry Proofs',        subject: 'Mathematics', className: 'Grade 7A', dueDate: 'Apr 10, 2025', status: 'Completed', submitted: 24, total: 24, color: AppColors.primary),
  _Assignment(id: 5, title: 'Statistics Exercise',    subject: 'Mathematics', className: 'Grade 9A', dueDate: 'Apr 28, 2025', status: 'Active',    submitted: 5,  total: 27, color: AppColors.primary),
  _Assignment(id: 6, title: 'Number Theory Quiz',     subject: 'Mathematics', className: 'Grade 8B', dueDate: 'Apr 03, 2025', status: 'Completed', submitted: 26, total: 26, color: AppColors.primary),
];

const _filterLabels = ['Active', 'Overdue', 'Completed'];

const _classOptions = ['Grade 7A', 'Grade 7B', 'Grade 8A', 'Grade 8B', 'Grade 9A', 'Grade 9B', 'Grade 10A'];

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherAssignmentsScreen extends StatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  String _filter = 'Active';
  List<_Assignment> _assignments = List.from(_mockAssignments);

  // Bottom sheet form state
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String _newClass = 'Grade 7A';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  List<_Assignment> get _filtered => _assignments.where((a) => a.status == _filter).toList();

  Color _statusColor(String s) {
    switch (s) {
      case 'Active':    return AppColors.primary;
      case 'Overdue':   return AppColors.error;
      case 'Completed': return AppColors.success;
      default:          return AppColors.textSecondary;
    }
  }

  void _showCreateSheet() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _newClass = 'Grade 7A';
    _dueDate  = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateAssignmentSheet(
        titleCtrl: _titleCtrl,
        descCtrl: _descCtrl,
        initialClass: _newClass,
        initialDue: _dueDate,
        onSubmit: (title, cls, due, desc) {
          final now = DateTime.now();
          final newA = _Assignment(
            id:        _assignments.length + 1,
            title:     title,
            subject:   'Mathematics',
            className: cls,
            dueDate:   '${due.day} ${_monthName(due.month)}, ${due.year}',
            status:    'Active',
            submitted: 0,
            total:     30,
            color:     AppColors.primary,
          );
          setState(() => _assignments = [newA, ..._assignments]);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment created'), backgroundColor: AppColors.success),
          );
        },
      ),
    );
  }

  String _monthName(int m) {
    const names = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m];
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assignments', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: _filterLabels.map((f) {
                  final sel = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? _statusColor(f) : AppColors.surface2,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _statusColor(f) : Colors.white.withOpacity(0.07)),
                        ),
                        child: Text(f, style: TextStyle(color: sel ? Colors.white : AppColors.textSecondary, fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(),
            ),

            // List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_rounded, color: AppColors.textHint, size: 52),
                          const SizedBox(height: 12),
                          Text('No $_filter assignments', style: const TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final a = items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 4, height: 72,
                                  decoration: BoxDecoration(color: a.color, borderRadius: BorderRadius.circular(4)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(a.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                          ),
                                          StatusBadge(label: a.status, color: _statusColor(a.status)),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(a.subject, style: TextStyle(fontSize: 12, color: a.color, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          const Icon(Icons.people_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(a.className, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(a.dueDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: a.total > 0 ? a.submitted / a.total : 0,
                                                minHeight: 5,
                                                backgroundColor: AppColors.surface3,
                                                valueColor: AlwaysStoppedAnimation<Color>(a.color.withOpacity(0.8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text('${a.submitted}/${a.total}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideX(begin: 0.05, end: 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Assignment Bottom Sheet ────────────────────────────────────────────

class _CreateAssignmentSheet extends StatefulWidget {
  final TextEditingController titleCtrl, descCtrl;
  final String initialClass;
  final DateTime initialDue;
  final void Function(String title, String cls, DateTime due, String desc) onSubmit;

  const _CreateAssignmentSheet({
    required this.titleCtrl, required this.descCtrl, required this.initialClass,
    required this.initialDue, required this.onSubmit,
  });

  @override
  State<_CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<_CreateAssignmentSheet> {
  late String _cls;
  late DateTime _due;

  @override
  void initState() {
    super.initState();
    _cls = widget.initialClass;
    _due = widget.initialDue;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary, surface: AppColors.surface1),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Text('New Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: widget.titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Assignment title',
                filled: true, fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 12),

            // Class dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _cls,
                  isExpanded: true,
                  dropdownColor: AppColors.surface1,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
                  items: _classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _cls = v); },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Due date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Due: ${_due.day}/${_due.month}/${_due.year}',
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: widget.descCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                filled: true, fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            GradientButton(
              label: 'Create Assignment',
              onTap: () {
                if (widget.titleCtrl.text.trim().isNotEmpty) {
                  widget.onSubmit(widget.titleCtrl.text.trim(), _cls, _due, widget.descCtrl.text.trim());
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
