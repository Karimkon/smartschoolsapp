import 'dart:math' as math;
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
      duration: const Duration(seconds: 12),
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
    final bot  = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Animated blobs ─────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: Size(size.width, size.height),
              painter: _BlobPainter(_bgCtrl.value),
            ),
          ),

          // ── Content (no scroll, fits one screen) ───────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(0, top, 0, bot),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          width: 36, height: 36, fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Smart Schools',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3)),
                          Text('Hub',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text('Log In',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),

                // ── Hero ───────────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                                color: AppColors.primary.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              const Text('Trusted by 500+ Schools',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                            .animate(delay: 100.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 20),

                        // Headline
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -1),
                            children: [
                              TextSpan(
                                  text: 'The Complete\n',
                                  style: TextStyle(color: Colors.white)),
                              TextSpan(
                                  text: 'School\nManagement\n',
                                  style: TextStyle(color: AppColors.primary)),
                              TextSpan(
                                  text: 'Platform',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        )
                            .animate(delay: 180.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.3, end: 0),

                        const SizedBox(height: 16),

                        const Text(
                          'All-in-one ERP connecting students, teachers,\nparents and administrators — effortlessly.',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.6),
                        )
                            .animate(delay: 260.ms)
                            .fadeIn(duration: 400.ms),

                        const SizedBox(height: 32),

                        // Login CTA
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.45),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Login to Dashboard',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        )
                            .animate(delay: 340.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),

                // ── Stats strip ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111F3C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(
                      children: [
                        _Stat('21+', 'Modules'),
                        _divider(),
                        _Stat('99.9%', 'Uptime'),
                        _divider(),
                        _Stat('24/7', 'Support'),
                        _divider(),
                        _Stat('500+', 'Schools'),
                      ],
                    ),
                  ),
                )
                    .animate(delay: 420.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 32, color: Colors.white.withOpacity(0.1));
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ]),
      );
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
        colors: [AppColors.primary.withOpacity(0.2), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.15 + 60 * t),
          radius: 280));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15 + 60 * t), 280, blob1);

    final blob2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3B82F6).withOpacity(0.13),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.05, size.height * 0.65 - 40 * t),
          radius: 240));
    canvas.drawCircle(
        Offset(size.width * 0.05, size.height * 0.65 - 40 * t), 240, blob2);

    // Extra subtle accent blob
    final blob3 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6).withOpacity(0.08),
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(
          center: Offset(
              size.width * 0.5, size.height * 0.9 + 30 * math.sin(t * math.pi)),
          radius: 180));
    canvas.drawCircle(
        Offset(size.width * 0.5,
            size.height * 0.9 + 30 * math.sin(t * math.pi)),
        180,
        blob3);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.t != t;
}
