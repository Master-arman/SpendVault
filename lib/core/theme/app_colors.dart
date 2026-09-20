import 'package:flutter/material.dart';

/// Design tokens and semantic color palette for the application.
class AppColors {
  const AppColors._();

  // Core Theme Palette Tokens (Requested)
  static const Color primary = Color(0xFF6366F1);
  static const Color darkSlateBackground = Color(0xFF0A0F1D);
  static const Color surfaceCard = Color(0xFF151D30);
  static const Color borderStroke = Color(0xFF24304F);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Surface Elevation Tokens
  static const Color surfaceCardHover = Color(0xFF1B243B);
  static const Color surfaceCardElevated = Color(0xFF1E2942);
  static const Color surfaceOverlay = Color(0xCC0A0F1D);

  // Accent & Brand Variations
  static const Color indigoLight = Color(0xFF818CF8);
  static const Color indigoDark = Color(0xFF4F46E5);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);

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
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
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
