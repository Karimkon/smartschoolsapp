import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding data
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardPage {
  final String title;
  final String subtitle;
  final List<_Feature> features;
  final Color accent;
  final IconData heroIcon;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.accent,
    required this.heroIcon,
  });
}

class _Feature {
  final IconData icon;
  final String label;
  final Color color;
  const _Feature(this.icon, this.label, this.color);
}

const _pages = [
  _OnboardPage(
    title: 'Smart Schools Hub',
    subtitle: 'The all-in-one school management platform trusted by schools across East Africa.',
    accent: Color(0xFF2FA876),
    heroIcon: Icons.school_rounded,
    features: [
      _Feature(Icons.people_alt_rounded,      'Students & Staff',   Color(0xFF2FA876)),
      _Feature(Icons.menu_book_rounded,        'Academics',          Color(0xFF3B82F6)),
      _Feature(Icons.account_balance_wallet,   'Finance & Fees',     Color(0xFFF59E0B)),
      _Feature(Icons.how_to_reg_rounded,       'Attendance',         Color(0xFFEC4899)),
    ],
  ),
  _OnboardPage(
    title: 'Everything You Need',
    subtitle: 'From timetables to report cards — manage every aspect of school life from one app.',
    accent: Color(0xFF3B82F6),
    heroIcon: Icons.dashboard_rounded,
    features: [
      _Feature(Icons.schedule_rounded,         'Timetable',          Color(0xFF3B82F6)),
      _Feature(Icons.assignment_rounded,       'Assignments',        Color(0xFF8B5CF6)),
      _Feature(Icons.bar_chart_rounded,        'Exams & Results',    Color(0xFFF59E0B)),
      _Feature(Icons.local_library_rounded,    'Library',            Color(0xFF2FA876)),
    ],
  ),
  _OnboardPage(
    title: 'Built for Everyone',
    subtitle: 'Role-based dashboards tailored for admins, teachers, students, parents, and more.',
    accent: Color(0xFF8B5CF6),
    heroIcon: Icons.groups_rounded,
    features: [
      _Feature(Icons.admin_panel_settings_rounded, 'Administrator',  Color(0xFF2FA876)),
      _Feature(Icons.person_rounded,               'Teacher',        Color(0xFF3B82F6)),
      _Feature(Icons.school_rounded,               'Student',        Color(0xFF8B5CF6)),
      _Feature(Icons.family_restroom_rounded,      'Parent',         Color(0xFFF59E0B)),
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding Screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  int _current = 0;
  late AnimationController _bgAnim;

  @override
  void initState() {
    super.initState();
    _bgAnim = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgAnim.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(duration: 400.ms, curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final page = _pages[_current];

    return Scaffold(
      body: Stack(
        children: [
          // ── Animated background ────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (_, __) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _BgPainter(_bgAnim.value, page.accent),
              );
            },
          ),

          // ── Skip button ────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: TextButton(
              onPressed: _finish,
              child: Text('Login',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ),

          // ── Page content ───────────────────────────────────────────────────
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) => _PageContent(page: _pages[index]),
          ),

          // ── Bottom controls ────────────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _BottomControls(
              current:  _current,
              total:    _pages.length,
              accent:   page.accent,
              onNext:   _next,
              isLast:   _current == _pages.length - 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page content widget
// ─────────────────────────────────────────────────────────────────────────────
class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            SizedBox(height: size.height * 0.08),

            // Hero icon
            _HeroIcon(icon: page.heroIcon, color: page.accent)
              .animate()
              .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1),
                     duration: 700.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),

            SizedBox(height: size.height * 0.05),

            // Title
            Text(page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w800,
                color: Colors.white, height: 1.2,
                letterSpacing: -0.5,
              ),
            )
            .animate(delay: 150.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 14),

            // Subtitle
            Text(page.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, color: Colors.white.withOpacity(0.72),
                height: 1.55, fontWeight: FontWeight.w400,
              ),
            )
            .animate(delay: 250.ms)
            .fadeIn(duration: 500.ms),

            SizedBox(height: size.height * 0.06),

            // Feature grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: page.features.asMap().entries.map((e) {
                return _FeatureTile(feature: e.value, delay: 350 + e.key * 80)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 350 + e.key * 80), duration: 400.ms)
                  .slideY(begin: 0.3, end: 0,
                    delay: Duration(milliseconds: 350 + e.key * 80), duration: 400.ms,
                    curve: Curves.easeOut);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero icon widget
// ─────────────────────────────────────────────────────────────────────────────
class _HeroIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _HeroIcon({required this.icon, required this.color});

  @override
  State<_HeroIcon> createState() => _HeroIconState();
}

class _HeroIconState extends State<_HeroIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _ctrl.value),
          child: child,
        );
      },
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.15),
          border: Border.all(color: widget.color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 40, spreadRadius: 0),
          ],
        ),
        child: Icon(widget.icon, color: widget.color, size: 58),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feature tile
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final int delay;
  const _FeatureTile({required this.feature, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(feature.icon, color: feature.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(feature.label,
              style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom controls
// ─────────────────────────────────────────────────────────────────────────────
class _BottomControls extends StatelessWidget {
  final int current;
  final int total;
  final Color accent;
  final VoidCallback onNext;
  final bool isLast;

  const _BottomControls({
    required this.current,
    required this.total,
    required this.accent,
    required this.onNext,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 28, right: 28, bottom: MediaQuery.of(context).padding.bottom + 32, top: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(total, (i) {
              final active = i == current;
              return AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(right: 6),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? accent : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Next / Get Started button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: 300.ms,
              padding: EdgeInsets.symmetric(
                horizontal: isLast ? 24 : 20,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.75)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(color: accent.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLast) ...[
                    const Text('Get Started',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isLast ? Icons.arrow_forward_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background painter
// ─────────────────────────────────────────────────────────────────────────────
class _BgPainter extends CustomPainter {
  final double t;
  final Color accent;
  const _BgPainter(this.t, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    final bg = Paint()..color = const Color(0xFF0A1628);
    canvas.drawRect(Offset.zero & size, bg);

    // Animated blobs
    final blob1 = Paint()
      ..shader = RadialGradient(colors: [accent.withOpacity(0.22), Colors.transparent])
           .createShader(Rect.fromCircle(
              center: Offset(size.width * 0.8, size.height * 0.15 + 40 * t),
              radius: 220));
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.15 + 40 * t), 220, blob1);

    final blob2 = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFF3B82F6).withOpacity(0.18), Colors.transparent])
           .createShader(Rect.fromCircle(
              center: Offset(size.width * 0.1, size.height * 0.6 - 30 * t),
              radius: 200));
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.6 - 30 * t), 200, blob2);

    // Subtle grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t || old.accent != accent;
}
