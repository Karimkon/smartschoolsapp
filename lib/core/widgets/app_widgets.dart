import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme/app_colors.dart';

// ── Gradient Card ─────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key, required this.child, this.padding, this.radius = 20,
    this.color, this.gradient, this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        gradient == null ? (color ?? AppColors.surface1) : null,
          gradient:     gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final int index;
  final VoidCallback? onTap;

  const StatCard({
    super.key, required this.label, required this.value,
    required this.icon, required this.color, this.subtitle, this.index = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: MediaQuery.withNoTextScaling(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.textHint)
                else if (subtitle != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(subtitle!, style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textPrimary, height: 1.15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500, height: 1.15),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );

    final animated = card
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut);

    if (onTap == null) return animated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.15),
        highlightColor: color.withOpacity(0.08),
        child: animated,
      ),
    );
  }
}

// ── Gradient Button ───────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final Gradient gradient;
  final double height;

  const GradientButton({
    super.key, required this.label, this.onTap, this.loading = false,
    this.gradient = AppColors.primaryGradient, this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

// ── Shimmer Loader ────────────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const ShimmerCard({super.key, this.height = 90, this.width, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2,
      highlightColor: AppColors.surface3,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ── Avatar Widget ─────────────────────────────────────────────────────────────
class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final Color color;
  final double size;

  const AvatarWidget({
    super.key, this.imageUrl, required this.initials,
    required this.color, this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Center(
      child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.36)),
    ),
  );
}

// ── Status Badge ──────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Search Field ──────────────────────────────────────────────────────────────
class AppSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AppSearchField({super.key, this.hint = 'Search...', this.onChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
