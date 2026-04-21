import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(2200.ms);
    await ref.read(authProvider.notifier).tryAutoLogin();
    if (!mounted) return;

    final user = ref.read(authProvider).user;
    if (user != null) {
      context.go(_homeForRole(user.role));
      return;
    }

    // Check whether onboarding has been shown before
    final prefs = await SharedPreferences.getInstance();
    final seen  = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;

    context.go(seen ? '/login' : '/onboarding');
  }

  String _homeForRole(String role) {
    switch (role) {
      case 'super_admin':  return '/super-admin';
      case 'school_admin': return '/admin';
      case 'teacher':      return '/teacher';
      case 'student':      return '/student';
      case 'parent':       return '/parent';
      case 'accountant':   return '/accountant';
      case 'librarian':    return '/librarian';
      default:             return '/login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: Stack(
          children: [
            // Background decorations
            Positioned(top: -80, right: -80,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.25), Colors.transparent]),
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 1200.ms, curve: Curves.easeOut),
            ),
            Positioned(bottom: -60, left: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.accent.withOpacity(0.2), Colors.transparent]),
                ),
              ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 1200.ms, delay: 200.ms, curve: Curves.easeOut),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 12))],
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 52),
                  )
                  .animate()
                  .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // App name
                  ShaderMask(
                    shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                    child: const Text('Smart Schools',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                  )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

                  const SizedBox(height: 8),

                  Text('All-in-one School Management',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w400, letterSpacing: 0.3),
                  )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 500.ms),

                  const SizedBox(height: 60),

                  // Loading indicator
                  SizedBox(
                    width: 40, height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(
                        backgroundColor: AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                  )
                  .animate(delay: 800.ms)
                  .fadeIn(duration: 400.ms),
                ],
              ),
            ),

            // Version tag
            Positioned(
              bottom: 30, left: 0, right: 0,
              child: Center(
                child: Text('v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
              ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }
}
