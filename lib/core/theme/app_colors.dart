import 'package:flutter/material.dart';

/// Design tokens and semantic color palette for the application.
class AppColors {
  const AppColors._();

  // Core Theme Palette Tokens (Vibrant Teal / Mint)
  static const Color primary = Color(0xFF0D9488);
  static const Color darkSlateBackground = Color(0xFF0A0F1D);
  static const Color surfaceCard = Color(0xFF151D30);
  static const Color borderStroke = Color(0xFF24304F);
  static const Color accentIndigo = Color(0xFF14B8A6);

  // Consumer Product Design System - Light Theme
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightPrimary = Color(0xFF0D9488); // Modern Vibrant Teal
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Consumer Product Design System - Dark Theme (Matte Dark Slate)
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkPrimary = Color(0xFF14B8A6);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Phase 49: Pure OLED Theme (Pitch Black for AMOLED Battery Conservation)
  static const Color oledBackground = Color(0xFF000000);
  static const Color oledCard = Color(0xFF0D0D0D);
  static const Color oledBorder = Color(0xFF1E1E1E);
  static const Color oledPrimary = Color(0xFF14B8A6);
  static const Color oledSurfaceElevated = Color(0xFF141414);
  static const Color oledTextPrimary = Color(0xFFFFFFFF);
  static const Color oledTextSecondary = Color(0xFFA1A1AA);
  static const Color oledTextMuted = Color(0xFF71717A);

  // Surface Elevation Tokens
  static const Color surfaceCardHover = Color(0xFF1B243B);
  static const Color surfaceCardElevated = Color(0xFF1E2942);
  static const Color surfaceOverlay = Color(0xCC0A0F1D);

  // Accent & Brand Variations
  static const Color indigoLight = Color(0xFF5EEAD4);
  static const Color indigoDark = Color(0xFF0F766E);
  static const Color accentViolet = Color(0xFF06B6D4);
  static const Color accentCyan = Color(0xFF2DD4BF);

  // Semantic Feedback Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenSoft = Color(0x1F10B981);
  static const Color expenseRed = Color(0xFFF43F5E);
  static const Color expenseRedSoft = Color(0x1FF43F5E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberSoft = Color(0x1FF59E0B);
  static const Color infoBlue = Color(0xFF38BDF8);

  // Typography & Content Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

  // Linear & Radial Gradient Tokens
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D9488),
      Color(0xFF14B8A6),
      Color(0xFF2DD4BF),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF172036),
      Color(0xFF151D30),
    ],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF0A0F1D),
    ],
  );
}
