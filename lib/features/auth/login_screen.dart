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

  // Demo accounts for easy testing
  static const _demoAccounts = [
    {'role': 'Admin',      'email': 'admin@school.com',      'pass': 'password', 'color': AppColors.roleAdmin},
    {'role': 'Teacher',    'email': 'teacher@school.com',    'pass': 'password', 'color': AppColors.roleTeacher},
    {'role': 'Student',    'email': 'student@school.com',    'pass': 'password', 'color': AppColors.roleStudent},
    {'role': 'Parent',     'email': 'parent@school.com',     'pass': 'password', 'color': AppColors.roleParent},
    {'role': 'Accountant', 'email': 'accounts@school.com',   'pass': 'password', 'color': AppColors.roleAccountant},
    {'role': 'Librarian',  'email': 'library@school.com',    'pass': 'password', 'color': AppColors.roleLibrarian},
  ];

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(), _passwordCtrl.text,
    );
    if (ok && mounted) {
      final user = ref.read(authProvider).user!;
      context.go(_homeForRole(user.role));
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
                  SizedBox(height: size.height * 0.06),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                        child: const Text('Smart Schools',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.06),

                  // Welcome text
                  const Text('Welcome back',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 6),
                  const Text('Sign in to your account',
                    style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                  ).animate(delay: 150.ms).fadeIn(),

                  SizedBox(height: size.height * 0.05),

                  // Email field
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email
                        const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.textHint),
                          ),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                        ),

                        const SizedBox(height: 16),

                        // Password
                        const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textHint),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textHint, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
                          onFieldSubmitted: (_) => _login(),
                        ),

                        if (auth.error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(auth.error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                              ],
                            ),
                          ).animate().fadeIn().shakeX(),
                        ],
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  // Login button
                  GradientButton(
                    label: 'Sign In',
                    loading: auth.loading,
                    onTap: _login,
                  ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 32),

                  // Quick access demo
                  const Center(
                    child: Text('Quick Demo Access', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8, runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _demoAccounts.map((acc) {
                      return GestureDetector(
                        onTap: () {
                          _emailCtrl.text    = acc['email'] as String;
                          _passwordCtrl.text = acc['pass'] as String;
                          _login();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: (acc['color'] as Color).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: (acc['color'] as Color).withOpacity(0.3)),
                          ),
                          child: Text(acc['role'] as String,
                            style: TextStyle(color: acc['color'] as Color, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate(delay: 500.ms).fadeIn(),

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
