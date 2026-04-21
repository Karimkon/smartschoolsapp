import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Visitor {
  final int id;
  final String name, purpose, host, phone, checkIn;
  String? checkOut;
  _Visitor({required this.id, required this.name, required this.purpose, required this.host, required this.phone, required this.checkIn, this.checkOut});
  bool get isActive => checkOut == null;
}

class _Complaint {
  final int id;
  final String from, subject, date;
  String status;
  _Complaint({required this.id, required this.from, required this.subject, required this.date, this.status = 'Open'});
}

class _CallLog {
  final int id;
  final String callerName, phone, reason, dateTime, direction;
  const _CallLog({required this.id, required this.callerName, required this.phone, required this.reason, required this.dateTime, required this.direction});
}

class _PostalItem {
  final int id;
  final String sender, recipient, type, date, status;
  const _PostalItem({required this.id, required this.sender, required this.recipient, required this.type, required this.date, required this.status});
}

final List<_Visitor> _visitors = [
  _Visitor(id: 1, name: 'Mr. Kwame Asante',   purpose: 'Parent-Teacher Meeting', host: 'Ms. Alice Mensah',  phone: '+233 24 111 2222', checkIn: '09:15 AM', checkOut: '10:30 AM'),
  _Visitor(id: 2, name: 'Mrs. Amina Traore',   purpose: 'Student Enrollment',     host: 'Admin Office',       phone: '+221 77 333 4444', checkIn: '10:05 AM'),
  _Visitor(id: 3, name: 'Dr. Chidi Nwosu',     purpose: 'Guest Lecture',          host: 'Mr. George Weru',   phone: '+234 80 555 6666', checkIn: '11:00 AM'),
  _Visitor(id: 4, name: 'Ms. Diana Otieno',    purpose: 'Fee Payment',            host: 'Finance Office',    phone: '+254 70 777 8888', checkIn: '11:45 AM', checkOut: '12:15 PM'),
  _Visitor(id: 5, name: 'Mr. Emmanuel Kouame', purpose: 'Transport Inquiry',      host: 'Reception',         phone: '+225 05 999 1234', checkIn: '02:30 PM'),
];

final List<_Complaint> _complaints = [
  _Complaint(id: 1, from: 'Mrs. Fatima Hassan (Parent)',  subject: 'Bullying incident in Grade 6 classroom',    date: 'Apr 19, 2025', status: 'Open'),
  _Complaint(id: 2, from: 'Kofi Mensah (Student)',         subject: 'Unfair grading on mathematics test',        date: 'Apr 17, 2025', status: 'Resolved'),
  _Complaint(id: 3, from: 'Mr. Lamine Diallo (Parent)',    subject: 'Transport bus consistently late by 30 min', date: 'Apr 15, 2025', status: 'Open'),
  _Complaint(id: 4, from: 'Amara Osei (Student)',          subject: 'Library books not returned from last term', date: 'Apr 12, 2025', status: 'Resolved'),
  _Complaint(id: 5, from: 'Ms. Grace Acheampong (Parent)', subject: 'Canteen food quality is substandard',       date: 'Apr 10, 2025', status: 'Open'),
];

const List<_CallLog> _callLogs = [
  _CallLog(id: 1, callerName: 'Mr. Peter Omondi',   phone: '+254 70 123 4567', reason: 'Absence notification for child',            dateTime: 'Apr 21, 08:15 AM', direction: 'Incoming'),
  _CallLog(id: 2, callerName: 'MOE Education Dept',  phone: '+233 30 111 2345', reason: 'School inspection schedule reminder',        dateTime: 'Apr 20, 02:30 PM', direction: 'Incoming'),
  _CallLog(id: 3, callerName: 'Bus Company GhanaEx', phone: '+233 24 999 8888', reason: 'Transport route change confirmation',        dateTime: 'Apr 20, 10:00 AM', direction: 'Outgoing'),
  _CallLog(id: 4, callerName: 'Mrs. Sarah Kamau',    phone: '+254 72 345 6789', reason: 'Inquiry about fee payment deadline',         dateTime: 'Apr 19, 03:45 PM', direction: 'Incoming'),
  _CallLog(id: 5, callerName: 'School Supplies Ltd', phone: '+233 20 777 6543', reason: 'Follow up on stationery order delivery',     dateTime: 'Apr 18, 11:20 AM', direction: 'Outgoing'),
];

const List<_PostalItem> _postalItems = [
  _PostalItem(id: 1, sender: 'Ghana Education Service', recipient: 'School Principal',       type: 'Incoming', date: 'Apr 21, 2025', status: 'Received'),
  _PostalItem(id: 2, sender: 'School Admin',             recipient: 'Ministry of Education', type: 'Outgoing', date: 'Apr 19, 2025', status: 'Dispatched'),
  _PostalItem(id: 3, sender: 'Bank of Ghana',            recipient: 'Finance Department',    type: 'Incoming', date: 'Apr 18, 2025', status: 'Received'),
  _PostalItem(id: 4, sender: 'PTA Committee',            recipient: 'All Parents',           type: 'Outgoing', date: 'Apr 15, 2025', status: 'Dispatched'),
  _PostalItem(id: 5, sender: 'NHIS Office',              recipient: 'School Nurse',          type: 'Incoming', date: 'Apr 14, 2025', status: 'Pending'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminReceptionScreen extends StatefulWidget {
  const AdminReceptionScreen({super.key});

  @override
  State<AdminReceptionScreen> createState() => _AdminReceptionScreenState();
}

class _AdminReceptionScreenState extends State<AdminReceptionScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late List<_Visitor> _visitorList;
  late List<_Complaint> _complaintList;

  // FAB form controllers
  final _nameCtrl    = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _hostCtrl    = TextEditingController();
  final _fromCtrl    = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _callerCtrl  = TextEditingController();
  final _reasonCtrl  = TextEditingController();
  final _callerPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _visitorList = List.from(_visitors);
    _complaintList = List.from(_complaints);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose(); _purposeCtrl.dispose(); _phoneCtrl.dispose(); _hostCtrl.dispose();
    _fromCtrl.dispose(); _subjectCtrl.dispose(); _callerCtrl.dispose(); _reasonCtrl.dispose();
    _callerPhoneCtrl.dispose();
    super.dispose();
  }

  void _checkOut(int id) {
    setState(() {
      final idx = _visitorList.indexWhere((v) => v.id == id);
      if (idx != -1) _visitorList[idx].checkOut = 'Now';
    });
  }

  void _resolveComplaint(int id) {
    setState(() {
      final idx = _complaintList.indexWhere((c) => c.id == id);
      if (idx != -1) _complaintList[idx].status = 'Resolved';
    });
  }

  void _showLogVisitorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'Log Visitor',
        children: [
          _sheetField(_nameCtrl, 'Visitor Name', Icons.person_rounded),
          const SizedBox(height: 12),
          _sheetField(_purposeCtrl, 'Purpose of Visit', Icons.info_rounded),
          const SizedBox(height: 12),
          _sheetField(_phoneCtrl, 'Phone Number', Icons.phone_rounded),
          const SizedBox(height: 12),
          _sheetField(_hostCtrl, 'Host (Teacher/Staff)', Icons.supervisor_account_rounded),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Log Visitor',
            onTap: () {
              if (_nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _visitorList.add(_Visitor(
                    id: _visitorList.length + 10,
                    name: _nameCtrl.text,
                    purpose: _purposeCtrl.text.isEmpty ? 'General Visit' : _purposeCtrl.text,
                    host: _hostCtrl.text.isEmpty ? 'Reception' : _hostCtrl.text,
                    phone: _phoneCtrl.text,
                    checkIn: 'Now',
                  ));
                });
                _nameCtrl.clear(); _purposeCtrl.clear(); _phoneCtrl.clear(); _hostCtrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNewComplaintSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'New Complaint',
        children: [
          _sheetField(_fromCtrl, 'From (Name & Role)', Icons.person_rounded),
          const SizedBox(height: 12),
          _sheetField(_subjectCtrl, 'Subject', Icons.subject_rounded),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Submit Complaint',
            onTap: () {
              if (_fromCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _complaintList.add(_Complaint(
                    id: _complaintList.length + 10,
                    from: _fromCtrl.text,
                    subject: _subjectCtrl.text.isEmpty ? 'General Complaint' : _subjectCtrl.text,
                    date: 'Today',
                    status: 'Open',
                  ));
                });
                _fromCtrl.clear(); _subjectCtrl.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLogCallSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'Log Call',
        children: [
          _sheetField(_callerCtrl, 'Caller Name', Icons.person_rounded),
          const SizedBox(height: 12),
          _sheetField(_callerPhoneCtrl, 'Phone Number', Icons.phone_rounded),
          const SizedBox(height: 12),
          _sheetField(_reasonCtrl, 'Reason for Call', Icons.chat_bubble_rounded),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Log Call',
            onTap: () {
              Navigator.pop(ctx);
              _callerCtrl.clear(); _callerPhoneCtrl.clear(); _reasonCtrl.clear();
            },
          ),
        ],
      ),
    );
  }

  void _showLogPostalSheet() {
    final senderCtrl    = TextEditingController();
    final recipientCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildSheet(
        ctx,
        title: 'Log Postal Item',
        children: [
          _sheetField(senderCtrl,    'Sender',    Icons.send_rounded),
          const SizedBox(height: 12),
          _sheetField(recipientCtrl, 'Recipient', Icons.person_rounded),
          const SizedBox(height: 20),
          GradientButton(
            label: 'Log Postal Item',
            onTap: () {
              Navigator.pop(ctx);
              senderCtrl.dispose();
              recipientCtrl.dispose();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSheet(BuildContext ctx, {required String title, required List<Widget> children}) {
    return Container(
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
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );

  void _onFABPressed() {
    switch (_tabs.index) {
      case 0: _showLogVisitorSheet(); break;
      case 1: _showNewComplaintSheet(); break;
      case 2: _showLogCallSheet(); break;
      case 3: _showLogPostalSheet(); break;
    }
  }

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
        title: const Text('Reception', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Visitors'),
            Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Complaints'),
            Tab(icon: Icon(Icons.phone_rounded, size: 18), text: 'Call Logs'),
            Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), text: 'Postal'),
          ],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (_, __) {
          final labels = ['Log Visitor', 'New Complaint', 'Log Call', 'Log Postal'];
          final icons  = [Icons.person_add_rounded, Icons.add_comment_rounded, Icons.phone_in_talk_rounded, Icons.add_box_rounded];
          return FloatingActionButton.extended(
            onPressed: _onFABPressed,
            backgroundColor: AppColors.primary,
            icon: Icon(icons[_tabs.index], color: Colors.white),
            label: Text(labels[_tabs.index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          );
        },
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: TabBarView(
            controller: _tabs,
            children: [
              _VisitorsTab(visitors: _visitorList, onCheckOut: _checkOut),
              _ComplaintsTab(complaints: _complaintList, onResolve: _resolveComplaint),
              const _CallLogsTab(),
              const _PostalTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Visitors Tab ──────────────────────────────────────────────────────────────

class _VisitorsTab extends StatelessWidget {
  final List<_Visitor> visitors;
  final ValueChanged<int> onCheckOut;
  const _VisitorsTab({required this.visitors, required this.onCheckOut});

  @override
  Widget build(BuildContext context) {
    final active = visitors.where((v) => v.isActive).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.how_to_reg_rounded, color: AppColors.success, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$active Active', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 20)),
                  const Text('Visitors currently inside', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        ...visitors.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarWidget(initials: v.name.isNotEmpty ? v.name[0] : 'V', color: AppColors.primary, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(v.purpose, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (v.isActive)
                        StatusBadge(label: 'Inside', color: AppColors.success)
                      else
                        StatusBadge(label: 'Left', color: AppColors.textHint),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.supervisor_account_rounded, color: AppColors.textHint, size: 14),
                      const SizedBox(width: 4),
                      Text('Host: ${v.host}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, color: AppColors.textHint, size: 14),
                      const SizedBox(width: 4),
                      Text('In: ${v.checkIn}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      if (v.checkOut != null) ...[
                        const Text('  Out: ', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
                        Text(v.checkOut!, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      ],
                    ],
                  ),
                  if (v.isActive) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onCheckOut(v.id),
                        icon: const Icon(Icons.logout_rounded, size: 15),
                        label: const Text('Check Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ).animate(delay: Duration(milliseconds: i * 60))
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
          );
        }),
      ],
    );
  }
}

// ── Complaints Tab ────────────────────────────────────────────────────────────

class _ComplaintsTab extends StatelessWidget {
  final List<_Complaint> complaints;
  final ValueChanged<int> onResolve;
  const _ComplaintsTab({required this.complaints, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: complaints.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(c.subject, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: c.status, color: c.status == 'Resolved' ? AppColors.success : AppColors.error),
                  ],
                ),
                const SizedBox(height: 6),
                Text('From: ${c.from}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(c.date, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                if (c.status == 'Open') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => onResolve(c.id),
                      icon: const Icon(Icons.check_circle_rounded, size: 15),
                      label: const Text('Mark Resolved', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
        );
      }).toList(),
    );
  }
}

// ── Call Logs Tab ─────────────────────────────────────────────────────────────

class _CallLogsTab extends StatelessWidget {
  const _CallLogsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: _callLogs.asMap().entries.map((e) {
        final i = e.key;
        final c = e.value;
        final isIncoming = c.direction == 'Incoming';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (isIncoming ? AppColors.success : AppColors.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncoming ? Icons.call_received_rounded : Icons.call_made_rounded,
                    color: isIncoming ? AppColors.success : AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.callerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(c.phone, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(c.reason, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(label: c.direction, color: isIncoming ? AppColors.success : AppColors.primary),
                    const SizedBox(height: 6),
                    Text(c.dateTime, style: const TextStyle(color: AppColors.textHint, fontSize: 10), textAlign: TextAlign.right),
                  ],
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
        );
      }).toList(),
    );
  }
}

// ── Postal Tab ────────────────────────────────────────────────────────────────

class _PostalTab extends StatelessWidget {
  const _PostalTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: _postalItems.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final isIncoming = p.type == 'Incoming';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (isIncoming ? AppColors.accent : AppColors.warning).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isIncoming ? Icons.move_to_inbox_rounded : Icons.outbox_rounded,
                    color: isIncoming ? AppColors.accent : AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isIncoming ? p.sender : p.recipient, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(isIncoming ? 'To: ${p.recipient}' : 'From: ${p.sender}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(p.date, style: const TextStyle(color: AppColors.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(label: p.type, color: isIncoming ? AppColors.accent : AppColors.warning),
                    const SizedBox(height: 6),
                    StatusBadge(label: p.status, color: p.status == 'Received' || p.status == 'Dispatched' ? AppColors.success : AppColors.warning),
                  ],
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: i * 60))
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut),
        );
      }).toList(),
    );
  }
}
