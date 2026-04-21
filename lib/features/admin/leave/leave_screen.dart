import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _LeaveRequest {
  final int id;
  final String staffName, initials, leaveType, dateRange, reason;
  final int days;
  final Color avatarColor;
  String status;

  _LeaveRequest({
    required this.id,
    required this.staffName,
    required this.initials,
    required this.leaveType,
    required this.dateRange,
    required this.reason,
    required this.days,
    required this.avatarColor,
    this.status = 'Pending',
  });
}

final List<_LeaveRequest> _mockLeave = [
  _LeaveRequest(id: 1, staffName: 'Alice Mensah',  initials: 'AM', leaveType: 'Sick',      dateRange: 'Apr 22 – Apr 24', reason: 'Flu and fever, doctor advised bed rest for 3 days',            days: 3,  avatarColor: AppColors.roleTeacher,   status: 'Pending'),
  _LeaveRequest(id: 2, staffName: 'Brian Osei',    initials: 'BO', leaveType: 'Annual',    dateRange: 'May 01 – May 07', reason: 'Family vacation planned for school holiday period',             days: 7,  avatarColor: AppColors.primary,        status: 'Approved'),
  _LeaveRequest(id: 3, staffName: 'Chidi Okonkwo', initials: 'CO', leaveType: 'Emergency', dateRange: 'Apr 19 – Apr 20', reason: 'Family emergency — urgent travel required immediately',         days: 2,  avatarColor: AppColors.accent,         status: 'Approved'),
  _LeaveRequest(id: 4, staffName: 'Diana Kamau',   initials: 'DK', leaveType: 'Sick',      dateRange: 'Apr 25 – Apr 27', reason: 'Medical procedure scheduled, requires recovery time at home',  days: 3,  avatarColor: AppColors.roleParent,     status: 'Pending'),
  _LeaveRequest(id: 5, staffName: 'Emmanuel Ssali',initials: 'ES', leaveType: 'Annual',    dateRange: 'May 10 – May 15', reason: 'Annual leave entitlement — rest and personal commitments',     days: 6,  avatarColor: AppColors.roleAccountant, status: 'Rejected'),
  _LeaveRequest(id: 6, staffName: 'Fatima Hassan', initials: 'FH', leaveType: 'Emergency', dateRange: 'Apr 21 – Apr 21', reason: 'Child hospitalisation — urgent parental attendance needed',     days: 1,  avatarColor: AppColors.warning,        status: 'Pending'),
  _LeaveRequest(id: 7, staffName: 'George Weru',   initials: 'GW', leaveType: 'Annual',    dateRange: 'Jun 02 – Jun 06', reason: 'Pre-booked annual leave during end of term break period',      days: 5,  avatarColor: AppColors.roleTeacher,   status: 'Approved'),
];

const _filters = ['All', 'Pending', 'Approved', 'Rejected'];

Color _leaveTypeColor(String type) {
  switch (type) {
    case 'Sick':      return AppColors.error;
    case 'Annual':    return AppColors.primary;
    case 'Emergency': return AppColors.warning;
    default:          return AppColors.textSecondary;
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'Approved': return AppColors.success;
    case 'Rejected': return AppColors.error;
    default:         return AppColors.warning;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  late List<_LeaveRequest> _requests;
  String _filter = 'All';

  // New leave form controllers
  final _staffCtrl  = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _newLeaveType = 'Sick';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _requests = List.from(_mockLeave);
  }

  @override
  void dispose() {
    _staffCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  List<_LeaveRequest> get _filtered =>
      _filter == 'All' ? _requests : _requests.where((r) => r.status == _filter).toList();

  int _countByStatus(String status) => _requests.where((r) => r.status == status).length;

  void _updateStatus(int id, String status) {
    setState(() {
      final idx = _requests.indexWhere((r) => r.id == id);
      if (idx != -1) _requests[idx].status = status;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request $status'),
        backgroundColor: status == 'Approved' ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2026, 12),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  void _showNewLeaveSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('New Leave Request', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 20),
                _sheetLabel('Staff Name'),
                _sheetField(_staffCtrl, 'Enter staff name'),
                const SizedBox(height: 14),
                _sheetLabel('Leave Type'),
                Container(
                  decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _newLeaveType,
                      dropdownColor: AppColors.surface2,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      items: ['Sick', 'Annual', 'Emergency'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setModal(() => _newLeaveType = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sheetLabel('Start Date'),
                          GestureDetector(
                            onTap: () async {
                              await _pickDate(true);
                              setModal(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _startDate != null
                                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                        : 'Pick date',
                                    style: TextStyle(color: _startDate != null ? AppColors.textPrimary : AppColors.textHint, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sheetLabel('End Date'),
                          GestureDetector(
                            onTap: () async {
                              await _pickDate(false);
                              setModal(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    _endDate != null
                                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                        : 'Pick date',
                                    style: TextStyle(color: _endDate != null ? AppColors.textPrimary : AppColors.textHint, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sheetLabel('Reason'),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'State the reason for leave...',
                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Submit Request',
                  onTap: () {
                    if (_staffCtrl.text.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() {
                        _requests.add(_LeaveRequest(
                          id: _requests.length + 10,
                          staffName: _staffCtrl.text,
                          initials: _staffCtrl.text.isNotEmpty ? _staffCtrl.text.substring(0, 1).toUpperCase() : 'X',
                          leaveType: _newLeaveType,
                          dateRange: _startDate != null && _endDate != null
                              ? '${_startDate!.day}/${_startDate!.month} – ${_endDate!.day}/${_endDate!.month}'
                              : 'TBD',
                          reason: _reasonCtrl.text,
                          days: _startDate != null && _endDate != null ? _endDate!.difference(_startDate!).inDays + 1 : 1,
                          avatarColor: AppColors.primary,
                          status: 'Pending',
                        ));
                      });
                      _staffCtrl.clear();
                      _reasonCtrl.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
  );

  Widget _sheetField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
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
        title: const Text('Leave Management', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewLeaveSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    StatCard(label: 'Total Requests', value: '${_requests.length}',          icon: Icons.event_note_rounded,    color: AppColors.primary,  index: 0),
                    StatCard(label: 'Approved',        value: '${_countByStatus('Approved')}',icon: Icons.check_circle_rounded,  color: AppColors.success,  index: 1),
                    StatCard(label: 'Pending',         value: '${_countByStatus('Pending')}', icon: Icons.hourglass_empty_rounded,color: AppColors.warning, index: 2),
                    StatCard(label: 'Rejected',        value: '${_countByStatus('Rejected')}',icon: Icons.cancel_rounded,        color: AppColors.error,    index: 3),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Chips
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final active = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.surface2,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: active ? AppColors.primary : Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(f, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),

                SectionHeader(title: '${filtered.length} Requests'),
                const SizedBox(height: 12),

                // Leave Cards
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    return _LeaveCard(
                      request: r,
                      onApprove: () => _updateStatus(r.id, 'Approved'),
                      onReject:  () => _updateStatus(r.id, 'Rejected'),
                    ).animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 400.ms)
                      .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Leave Card ────────────────────────────────────────────────────────────────

class _LeaveCard extends StatelessWidget {
  final _LeaveRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _LeaveCard({required this.request, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'Pending';
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(initials: request.initials, color: request.avatarColor, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.staffName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        StatusBadge(label: request.leaveType, color: _leaveTypeColor(request.leaveType)),
                        const SizedBox(width: 8),
                        Text('${request.days} day${request.days != 1 ? 's' : ''}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              StatusBadge(label: request.status, color: _statusColor(request.status)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.textHint, size: 14),
              const SizedBox(width: 6),
              Text(request.dateRange, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            request.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textHint, fontSize: 12, height: 1.4),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
