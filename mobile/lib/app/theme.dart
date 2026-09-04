import 'package:flutter/material.dart';

/// Centralized application-level theme configuration.
/// Derives all application-level visual states from the base theme color:
/// - primary
/// - primaryLight
/// - primaryDark
/// - selected
/// - hover
/// - pressed
/// - backgroundTint
/// - border
class AppThemeShades {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color selected;
  final Color hover;
  final Color pressed;
  final Color backgroundTint;
  final Color border;

  const AppThemeShades({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.selected,
    required this.hover,
    required this.pressed,
    required this.backgroundTint,
    required this.border,
  });

  factory AppThemeShades.fromColor(Color base) {
    final hsl = HSLColor.fromColor(base);
    final darkHsl = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0));
    final lightHsl = hsl.withLightness((hsl.lightness + 0.35).clamp(0.0, 0.96));

    return AppThemeShades(
      primary: base,
      primaryLight: lightHsl.toColor(),
      primaryDark: darkHsl.toColor(),
      selected: base,
      hover: base.withValues(alpha: 0.12),
      pressed: base.withValues(alpha: 0.25),
      backgroundTint: base.withValues(alpha: 0.10),
      border: base.withValues(alpha: 0.35),
    );
  }
}

class AppTheme {
  static const Color defaultPrimaryColor = Color(0xFF7C3AED); // Deep Violet

  // Light theme colors
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Clean neutral off-white
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  // Dark theme colors
  static const Color darkScaffoldBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkCardColor = Color(0xFF1E293B); // Slate 800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkTextMuted = Color(0xFF64748B); // Slate 500
  static const Color darkBorderColor = Color(0xFF334155); // Slate 700

  static const Color streakFlame = Color(0xFFF97316); // Orange flame
  static const Color streakFlameBg = Color(0xFFFFF7ED); // Soft orange tint

  // Backward compatibility alias
  static const Color primaryColor = defaultPrimaryColor;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getScaffoldBackground(BuildContext context) =>
      isDark(context) ? darkScaffoldBackground : scaffoldBackground;

  static Color getCardColor(BuildContext context) =>
      isDark(context) ? darkCardColor : cardColor;

  static Color getTextPrimary(BuildContext context) =>
      isDark(context) ? darkTextPrimary : textPrimary;

  static Color getTextSecondary(BuildContext context) =>
      isDark(context) ? darkTextSecondary : textSecondary;

  static Color getTextMuted(BuildContext context) =>
      isDark(context) ? darkTextMuted : textMuted;

  static Color getBorderColor(BuildContext context) =>
      isDark(context) ? darkBorderColor : borderColor;
}
