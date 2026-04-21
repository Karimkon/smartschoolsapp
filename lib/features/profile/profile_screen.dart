import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/providers/auth_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _loggingOut = false;

  Color _roleColor(String role) {
    switch (role) {
      case 'super_admin':  return AppColors.roleSuperAdmin;
      case 'school_admin': return AppColors.roleAdmin;
      case 'teacher':      return AppColors.roleTeacher;
      case 'student':      return AppColors.roleStudent;
      case 'parent':       return AppColors.roleParent;
      case 'accountant':   return AppColors.roleAccountant;
      case 'librarian':    return AppColors.roleLibrarian;
      default:             return AppColors.primary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'super_admin':  return 'Super Admin';
      case 'school_admin': return 'Admin';
      case 'teacher':      return 'Teacher';
      case 'student':      return 'Student';
      case 'parent':       return 'Parent';
      case 'accountant':   return 'Accountant';
      case 'librarian':    return 'Librarian';
      default:             return role;
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        title: const Text('Log Out', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _loggingOut = true);
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showChangePassword() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _PasswordField(ctrl: oldCtrl, label: 'Current Password'),
              const SizedBox(height: 12),
              _PasswordField(ctrl: newCtrl, label: 'New Password'),
              const SizedBox(height: 12),
              _PasswordField(ctrl: confCtrl, label: 'Confirm New Password'),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Update Password',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password updated'), backgroundColor: AppColors.success),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    final name     = user?.name     ?? 'User';
    final email    = user?.email    ?? 'user@school.ke';
    final role     = user?.role     ?? 'student';
    final initials = user?.initials ?? 'U';
    final rColor   = _roleColor(role);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text('Profile', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
          children: [
            // Avatar + name block
            GlassCard(
              child: Column(
                children: [
                  AvatarWidget(initials: initials, color: rColor, size: 80)
                      .animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 400.ms),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary))
                      .animate(delay: 100.ms).fadeIn(),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))
                      .animate(delay: 120.ms).fadeIn(),
                  const SizedBox(height: 10),
                  StatusBadge(label: _roleLabel(role), color: rColor)
                      .animate(delay: 150.ms).fadeIn(),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // Settings
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Notifications toggle
                  _SettingsRow(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.warning,
                    label: 'Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (v) => setState(() => _notificationsEnabled = v),
                      activeColor: AppColors.primary,
                      inactiveTrackColor: AppColors.surface3,
                    ),
                  ),
                  _divider(),

                  // Dark mode (always on — descriptive only)
                  _SettingsRow(
                    icon: Icons.dark_mode_rounded,
                    iconColor: AppColors.roleTeacher,
                    label: 'Dark Mode',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.roleTeacher.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Always On', style: TextStyle(fontSize: 11, color: AppColors.roleTeacher, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  _divider(),

                  // Change password
                  _SettingsRow(
                    icon: Icons.lock_outline_rounded,
                    iconColor: AppColors.accent,
                    label: 'Change Password',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                    onTap: _showChangePassword,
                  ),
                  _divider(),

                  // Help
                  _SettingsRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.primary,
                    label: 'Help & Support',
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Help Center...'), backgroundColor: AppColors.primary),
                      );
                    },
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.08),

            const SizedBox(height: 16),

            // Logout
            GlassCard(
              color: AppColors.error.withOpacity(0.08),
              padding: EdgeInsets.zero,
              child: _SettingsRow(
                icon: Icons.logout_rounded,
                iconColor: AppColors.error,
                label: _loggingOut ? 'Logging out...' : 'Log Out',
                labelColor: AppColors.error,
                trailing: _loggingOut
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.error),
                onTap: _loggingOut ? null : _confirmLogout,
              ),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.08),

            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text(
                'Smart Schools v1.0.0',
                style: const TextStyle(fontSize: 11, color: AppColors.textHint),
              ).animate(delay: 400.ms).fadeIn(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: Colors.white.withOpacity(0.05),
  );
}

// ── Settings Row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon, required this.iconColor,
    required this.label, required this.trailing,
    this.labelColor, this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: labelColor ?? AppColors.textPrimary),
            ),
          ),
          trailing,
        ],
      ),
    ),
  );
}

// ── Password Field Helper ─────────────────────────────────────────────────────

class _PasswordField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  const _PasswordField({required this.ctrl, required this.label});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextField(
    controller: widget.ctrl,
    obscureText: _obscure,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: widget.label,
      filled: true, fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(14),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.textHint, size: 18),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
  );
}
