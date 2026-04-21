import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_widgets.dart';

// ── Mock Data ─────────────────────────────────────────────────────────────────

class _Applicant {
  final int id;
  final String name, initials, classApplying, dateApplied, phone, parentName, address;
  final Color avatarColor;
  String status;
  final List<String> documents;

  _Applicant({
    required this.id,
    required this.name,
    required this.initials,
    required this.classApplying,
    required this.dateApplied,
    required this.phone,
    required this.parentName,
    required this.address,
    required this.avatarColor,
    this.status = 'Pending',
    required this.documents,
  });
}

final List<_Applicant> _mockApplicants = [
  _Applicant(id: 1, name: 'Kofi Asante',       initials: 'KA', classApplying: 'Grade 7',  dateApplied: 'Apr 10, 2025', phone: '+233 24 111 2222', parentName: 'Kwame Asante',  address: 'Accra, Ghana',     avatarColor: AppColors.primary,        status: 'Pending',  documents: ['Birth Certificate', 'Report Card', 'Passport Photo', 'Medical Record']),
  _Applicant(id: 2, name: 'Amina Diallo',       initials: 'AD', classApplying: 'Grade 4',  dateApplied: 'Apr 12, 2025', phone: '+221 77 333 4444', parentName: 'Ibrahim Diallo',address: 'Dakar, Senegal',   avatarColor: AppColors.accent,         status: 'Reviewed', documents: ['Birth Certificate', 'Report Card', 'Passport Photo']),
  _Applicant(id: 3, name: 'Tunde Bakare',       initials: 'TB', classApplying: 'Grade 9',  dateApplied: 'Apr 08, 2025', phone: '+234 80 555 6666', parentName: 'Bode Bakare',   address: 'Lagos, Nigeria',   avatarColor: AppColors.roleTeacher,    status: 'Enrolled', documents: ['Birth Certificate', 'Report Card', 'Passport Photo', 'Medical Record', 'Transfer Letter']),
  _Applicant(id: 4, name: 'Sara Omondi',        initials: 'SO', classApplying: 'Grade 2',  dateApplied: 'Apr 15, 2025', phone: '+254 70 777 8888', parentName: 'Peter Omondi',  address: 'Nairobi, Kenya',   avatarColor: AppColors.roleParent,     status: 'Pending',  documents: ['Birth Certificate', 'Passport Photo']),
  _Applicant(id: 5, name: 'Musa Traore',        initials: 'MT', classApplying: 'Grade 6',  dateApplied: 'Apr 05, 2025', phone: '+223 76 999 0000', parentName: 'Lamine Traore', address: 'Bamako, Mali',     avatarColor: AppColors.warning,        status: 'Rejected', documents: ['Birth Certificate', 'Report Card']),
  _Applicant(id: 6, name: 'Grace Acheampong',   initials: 'GA', classApplying: 'Grade 11', dateApplied: 'Apr 18, 2025', phone: '+233 26 123 4567', parentName: 'Ama Acheampong',address: 'Kumasi, Ghana',    avatarColor: AppColors.roleAccountant, status: 'Pending',  documents: ['Birth Certificate', 'Report Card', 'Passport Photo', 'Previous Certificate']),
];

const _filters = ['All', 'Pending', 'Reviewed', 'Enrolled', 'Rejected'];

Color _statusColor(String status) {
  switch (status) {
    case 'Enrolled': return AppColors.success;
    case 'Reviewed': return AppColors.primary;
    case 'Rejected': return AppColors.error;
    default:         return AppColors.warning;
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminAdmissionsScreen extends StatefulWidget {
  const AdminAdmissionsScreen({super.key});

  @override
  State<AdminAdmissionsScreen> createState() => _AdminAdmissionsScreenState();
}

class _AdminAdmissionsScreenState extends State<AdminAdmissionsScreen> {
  late List<_Applicant> _applicants;
  String _filter = 'All';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _applicants = List.from(_mockApplicants);
  }

  List<_Applicant> get _filtered {
    return _applicants.where((a) {
      final matchFilter = _filter == 'All' || a.status == _filter;
      final matchSearch = _search.isEmpty || a.name.toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
  }

  int _countByStatus(String s) => _applicants.where((a) => a.status == s).length;

  void _updateStatus(int id, String status) {
    setState(() {
      final idx = _applicants.indexWhere((a) => a.id == id);
      if (idx != -1) _applicants[idx].status = status;
    });
  }

  void _showDetailSheet(_Applicant applicant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: AppColors.textHint, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        AvatarWidget(initials: applicant.initials, color: applicant.avatarColor, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(applicant.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                              Text('Applying for ${applicant.classApplying}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        ),
                        StatusBadge(label: applicant.status, color: _statusColor(applicant.status)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _detailRow('Date Applied', applicant.dateApplied),
                    _detailRow('Contact', applicant.phone),
                    _detailRow('Parent/Guardian', applicant.parentName),
                    _detailRow('Address', applicant.address),
                    const SizedBox(height: 16),
                    const Text('Documents Checklist', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...applicant.documents.map((doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.success.withOpacity(0.4)),
                            ),
                            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 13),
                          ),
                          const SizedBox(width: 10),
                          Text(doc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    )),
                    const SizedBox(height: 20),
                    if (applicant.status == 'Pending' || applicant.status == 'Reviewed') ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () { Navigator.pop(ctx); _updateStatus(applicant.id, 'Rejected'); },
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () { Navigator.pop(ctx); _updateStatus(applicant.id, 'Reviewed'); },
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GradientButton(
                        label: 'Enroll Student',
                        gradient: const LinearGradient(colors: [AppColors.success, AppColors.accent]),
                        onTap: () { Navigator.pop(ctx); _updateStatus(applicant.id, 'Enrolled'); },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ],
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
        title: const Text('Admissions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
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
                    StatCard(label: 'Total Applications', value: '${_applicants.length}',          icon: Icons.folder_open_rounded,    color: AppColors.primary,  index: 0),
                    StatCard(label: 'Pending Review',     value: '${_countByStatus('Pending')}',   icon: Icons.pending_rounded,         color: AppColors.warning,  index: 1),
                    StatCard(label: 'Enrolled',           value: '${_countByStatus('Enrolled')}',  icon: Icons.school_rounded,          color: AppColors.success,  index: 2),
                    StatCard(label: 'Rejected',           value: '${_countByStatus('Rejected')}',  icon: Icons.cancel_rounded,          color: AppColors.error,    index: 3),
                  ],
                ),
                const SizedBox(height: 16),

                // Search
                AppSearchField(
                  hint: 'Search applicants...',
                  onChanged: (v) => setState(() => _search = v),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 14),

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

                SectionHeader(title: '${filtered.length} Applicants'),
                const SizedBox(height: 12),

                // Applicant Cards
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    return _ApplicantCard(
                      applicant: a,
                      onReview: () => _showDetailSheet(a),
                      onEnroll: () => _updateStatus(a.id, 'Enrolled'),
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

// ── Applicant Card ────────────────────────────────────────────────────────────

class _ApplicantCard extends StatelessWidget {
  final _Applicant applicant;
  final VoidCallback onReview;
  final VoidCallback onEnroll;

  const _ApplicantCard({required this.applicant, required this.onReview, required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    final isPending = applicant.status == 'Pending';
    return GlassCard(
      onTap: () => onReview(),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(initials: applicant.initials, color: applicant.avatarColor, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(applicant.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('${applicant.classApplying}  •  ${applicant.dateApplied}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              StatusBadge(label: applicant.status, color: _statusColor(applicant.status)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_rounded, color: AppColors.textHint, size: 14),
              const SizedBox(width: 6),
              Text(applicant.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.visibility_rounded, size: 15),
                    label: const Text('Review', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEnroll,
                    icon: const Icon(Icons.how_to_reg_rounded, size: 15),
                    label: const Text('Enroll', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
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
