import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final top  = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // ── Animated gradient blobs ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) {
              final t = _bgCtrl.value;
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _BlobPainter(t),
              );
            },
          ),

          // ── Scrollable content ──────────────────────────────────────────────
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: top),
                _TopBar(),
                _HeroSection(screenWidth: size.width),
                _StatsRow(),
                _ModulesSection(),
                _RolesSection(),
                _BottomCTA(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/app_icon.png', width: 38, height: 38, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Smart Schools',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              Text('Hub', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          // Log In button
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.7), width: 1.5),
                borderRadius: BorderRadius.circular(50),
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Text('Log In',
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero section
// ─────────────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final double screenWidth;
  const _HeroSection({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                const SizedBox(width: 7),
                const Text('Trusted by 500+ Schools',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 22),

          // Headline
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.8),
              children: [
                TextSpan(text: 'The Complete\n', style: TextStyle(color: Colors.white)),
                TextSpan(text: 'School\nManagement\n', style: TextStyle(color: AppColors.primary)),
                TextSpan(text: 'Platform', style: TextStyle(color: Colors.white)),
              ],
            ),
          ).animate(delay: 180.ms).fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 16),

          // Subtitle
          const Text(
            'An all-in-one multi-school ERP that connects students, teachers, parents, and administrators. Manage academics, finance, communication & more — effortlessly.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6),
          ).animate(delay: 260.ms).fadeIn(duration: 500.ms),

          const SizedBox(height: 30),

          // CTA button
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Login to Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ).animate(delay: 340.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 36),

          // Mock dashboard preview card
          _DashboardPreview()
            .animate(delay: 420.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fake dashboard preview (like the laptop mockup on the web)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111F3C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Window chrome dots
          Row(
            children: [
              _dot(const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFF59E0B)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF10B981)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('smartschoolshub.com',
                  style: TextStyle(color: AppColors.primary, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stats row
          Row(
            children: [
              _StatMini('Students', '1,248', Icons.school_rounded, AppColors.primary),
              const SizedBox(width: 8),
              _StatMini('Teachers', '86', Icons.person_rounded, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _StatMini('Revenue', '98.5M', Icons.account_balance_wallet, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 12),

          // Mini bar chart
          _MiniChart(),
          const SizedBox(height: 10),

          // Attendance badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('98%', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance Rate', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('This semester', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
}

class _StatMini extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatMini(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [0.4, 0.65, 0.5, 0.8, 0.6, 0.9, 0.75];
    return SizedBox(
      height: 44,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.asMap().entries.map((e) {
          final isLast = e.key == data.length - 1;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 44 * e.value,
              decoration: BoxDecoration(
                color: isLast ? AppColors.primary : AppColors.primary.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111F3C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          _Stat('21+', 'Modules'),
          _divider(),
          _Stat('99.9%', 'Uptime'),
          _divider(),
          _Stat('24/7', 'Support'),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.1));
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(value, style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modules section
// ─────────────────────────────────────────────────────────────────────────────
class _ModulesSection extends StatelessWidget {
  static const _modules = [
    _Module('Student Management', 'Admissions, profiles, promotions, transfers & ID cards.', Icons.school_rounded, AppColors.primary),
    _Module('Teacher & Staff', 'Profiles, attendance, leave, payroll & performance tracking.', Icons.people_rounded, Color(0xFF3B82F6)),
    _Module('Academics', 'Classes, subjects, timetables, assignments, exams & report cards.', Icons.menu_book_rounded, Color(0xFF8B5CF6)),
    _Module('Timetable', 'Automated scheduling, conflict detection & teacher mapping.', Icons.calendar_month_rounded, Color(0xFFF59E0B)),
    _Module('Finance', 'Fee structures, invoices, mobile money payments & expense tracking.', Icons.account_balance_wallet_rounded, Color(0xFFEC4899)),
    _Module('Communication', 'Parent-teacher chat, announcements, notice board & SMS.', Icons.chat_bubble_rounded, Color(0xFF06D6A0)),
    _Module('Transport', 'Bus routes, driver management & student transport tracking.', Icons.directions_bus_rounded, Color(0xFFEF4444)),
    _Module('Library', 'Book catalog, borrowing system & late fee management.', Icons.local_library_rounded, Color(0xFFFF6B35)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text('EVERYTHING YOU NEED',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          const Text('21+ Powerful Modules',
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('From academics to finance, communication to transport — manage every aspect of your school from one platform.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.55)),

          const SizedBox(height: 24),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _modules.length,
            itemBuilder: (_, i) => _ModuleCard(_modules[i])
              .animate(delay: Duration(milliseconds: 100 + i * 60))
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
          ),
        ],
      ),
    );
  }
}

class _Module {
  final String title, desc;
  final IconData icon;
  final Color color;
  const _Module(this.title, this.desc, this.icon, this.color);
}

class _ModuleCard extends StatelessWidget {
  final _Module mod;
  const _ModuleCard(this.mod);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111F3C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: mod.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(mod.icon, color: mod.color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(mod.title,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: 6),
          Text(mod.desc,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.85), fontSize: 11.5, height: 1.5)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Roles section
// ─────────────────────────────────────────────────────────────────────────────
class _RolesSection extends StatelessWidget {
  static const _roles = [
    _Role('Administrator', 'Full system control', Icons.admin_panel_settings_rounded, AppColors.primary),
    _Role('Teacher', 'Classes & grading', Icons.person_rounded, Color(0xFF3B82F6)),
    _Role('Student', 'Learning portal', Icons.school_rounded, Color(0xFF8B5CF6)),
    _Role('Parent', 'Child progress', Icons.family_restroom_rounded, Color(0xFFF59E0B)),
    _Role('Accountant', 'Finance & fees', Icons.account_balance_wallet_rounded, Color(0xFFEC4899)),
    _Role('Librarian', 'Book management', Icons.local_library_rounded, Color(0xFF06D6A0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BUILT FOR EVERYONE',
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          const Text('Role-Based Dashboards',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text('Every user gets a tailored experience with exactly the tools they need.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _roles.asMap().entries.map((e) =>
              _RoleChip(e.value)
                .animate(delay: Duration(milliseconds: 80 + e.key * 50))
                .fadeIn(duration: 400.ms)
                .slideX(begin: 0.2, end: 0)
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class _Role {
  final String title, sub;
  final IconData icon;
  final Color color;
  const _Role(this.title, this.sub, this.icon, this.color);
}

class _RoleChip extends StatelessWidget {
  final _Role role;
  const _RoleChip(this.role);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: role.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: role.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(role.icon, color: role.color, size: 16),
          const SizedBox(width: 8),
          Text(role.title,
            style: TextStyle(color: role.color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom CTA
// ─────────────────────────────────────────────────────────────────────────────
class _BottomCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.18), AppColors.primaryDark.withOpacity(0.08)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/images/app_icon.png', width: 56, height: 56, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            const Text('Ready to transform\nyour school?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 10),
            const Text('Join 500+ schools already using Smart Schools Hub.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: const Text('Login to Dashboard',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 20),
            Text('Powered by Smart Schools Hub · smartschoolshub.com',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textHint.withOpacity(0.7), fontSize: 11)),
          ],
        ),
      ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background blob painter
// ─────────────────────────────────────────────────────────────────────────────
class _BlobPainter extends CustomPainter {
  final double t;
  const _BlobPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0A1628);
    canvas.drawRect(Offset.zero & size, bg);

    final blob1 = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.primary.withOpacity(0.18), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.1 + 50 * t), radius: 260));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1 + 50 * t), 260, blob1);

    final blob2 = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF3B82F6).withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.05, size.height * 0.5 - 40 * t), radius: 220));
    canvas.drawCircle(Offset(size.width * 0.05, size.height * 0.5 - 40 * t), 220, blob2);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
