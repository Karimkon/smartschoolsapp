import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFF2FA876); // web brand green
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark  = Color(0xFF059669);
  static const Color accent       = Color(0xFF06D6A0);
  static const Color accentLight  = Color(0xFF34D399);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color error        = Color(0xFFEF4444);
  static const Color success      = Color(0xFF10B981);

  static const Color bgDark       = Color(0xFF0A1628);
  static const Color surface1     = Color(0xFF111F3C);
  static const Color surface2     = Color(0xFF1A2F52);
  static const Color surface3     = Color(0xFF243759);

  static const Color textPrimary  = Color(0xFFF1F5F9);
  static const Color textSecondary= Color(0xFF94A3B8);
  static const Color textHint     = Color(0xFF475569);

  static const Color roleAdmin      = Color(0xFF2563EB);
  static const Color roleTeacher    = Color(0xFF7C3AED);
  static const Color roleStudent    = Color(0xFF06D6A0);
  static const Color roleParent     = Color(0xFFF59E0B);
  static const Color roleAccountant = Color(0xFFEC4899);
  static const Color roleLibrarian  = Color(0xFFEF4444);
  static const Color roleSuperAdmin = Color(0xFFFF6B35);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2FA876), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2FA876), Color(0xFF06D6A0)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF111F3C)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  );
  static const List<Color> chartPalette = [
    Color(0xFF2563EB), Color(0xFF06D6A0), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF7C3AED), Color(0xFFEC4899),
  ];
}
