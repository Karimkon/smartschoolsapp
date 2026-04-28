import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;
    if (ok) {
      final user = ref.read(authProvider).user;
      if (user != null) context.go(_homeForRole(user.role));
    }
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
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: size.height * 0.07),

                  // Logo + brand
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16, offset: const Offset(0, 6),
                          )],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      ShaderMask(
                        shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                        child: const Text('Smart Schools',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.07),

                  const Text('Welcome back',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 6),
                  const Text('Sign in to continue',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ).animate(delay: 150.ms).fadeIn(),

                  SizedBox(height: size.height * 0.06),

                  // Form card
                  GlassCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        const Text('Email',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textHint),
                          ),
                          validator: (v) =>
                              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),

                        const SizedBox(height: 18),

                        // Password
                        const Text('Password',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20,
                                color: AppColors.textHint),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textHint, size: 20,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 4) ? 'Enter your password' : null,
                          onFieldSubmitted: (_) => _login(),
                        ),

                        // Error message
                        if (auth.error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(auth.error!,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 13)),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().shakeX(),
                        ],
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  GradientButton(
                    label: 'Sign In',
                    loading: auth.loading,
                    onTap: _login,
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
