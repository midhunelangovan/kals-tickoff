import 'package:flutter/material.dart';

class HabitColorInfo {
  final String hex;
  final String name;
  final Color color;

  const HabitColorInfo({
    required this.hex,
    required this.name,
    required this.color,
  });
}

/// Expanded 18-color palette covering:
/// Purple, Violet, Indigo, Blue, Sky Blue, Cyan, Teal, Green, Emerald,
/// Lime, Yellow, Amber, Orange, Red, Rose, Pink, Magenta, Slate.
const List<HabitColorInfo> predefinedHabitColors = [
  HabitColorInfo(hex: '#9333EA', name: 'Purple', color: Color(0xFF9333EA)),
  HabitColorInfo(hex: '#7C3AED', name: 'Violet', color: Color(0xFF7C3AED)),
  HabitColorInfo(hex: '#4F46E5', name: 'Indigo', color: Color(0xFF4F46E5)),
  HabitColorInfo(hex: '#2563EB', name: 'Blue', color: Color(0xFF2563EB)),
  HabitColorInfo(hex: '#0284C7', name: 'Sky Blue', color: Color(0xFF0284C7)),
  HabitColorInfo(hex: '#0891B2', name: 'Cyan', color: Color(0xFF0891B2)),
  HabitColorInfo(hex: '#0D9488', name: 'Teal', color: Color(0xFF0D9488)),
  HabitColorInfo(hex: '#16A34A', name: 'Green', color: Color(0xFF16A34A)),
  HabitColorInfo(hex: '#059669', name: 'Emerald', color: Color(0xFF059669)),
  HabitColorInfo(hex: '#65A30D', name: 'Lime', color: Color(0xFF65A30D)),
  HabitColorInfo(hex: '#CA8A04', name: 'Yellow', color: Color(0xFFCA8A04)),
  HabitColorInfo(hex: '#D97706', name: 'Amber', color: Color(0xFFD97706)),
  HabitColorInfo(hex: '#EA580C', name: 'Orange', color: Color(0xFFEA580C)),
  HabitColorInfo(hex: '#DC2626', name: 'Red', color: Color(0xFFDC2626)),
  HabitColorInfo(hex: '#E11D48', name: 'Rose', color: Color(0xFFE11D48)),
  HabitColorInfo(hex: '#DB2777', name: 'Pink', color: Color(0xFFDB2777)),
  HabitColorInfo(hex: '#C026D3', name: 'Magenta', color: Color(0xFFC026D3)),
  HabitColorInfo(hex: '#854D0E', name: 'Brown', color: Color(0xFF854D0E)),
  HabitColorInfo(hex: '#6B7280', name: 'Gray', color: Color(0xFF6B7280)),
  HabitColorInfo(hex: '#475569', name: 'Slate', color: Color(0xFF475569)),
  HabitColorInfo(hex: '#1F2937', name: 'Dark Gray', color: Color(0xFF1F2937)),
];

/// Centralized color utility that dynamically derives all habit-specific
/// visual states from the habit's base color:
/// - primary
/// - hover
/// - pressed
/// - selected
/// - completed
/// - lightBackground
/// - border
/// - text
class HabitColorShades {
  final Color base;
  final Color primary;
  final Color hover;
  final Color pressed;
  final Color selected;
  final Color completed;
  final Color lightBackground;
  final Color border;
  final Color text;

  const HabitColorShades({
    required this.base,
    required this.primary,
    required this.hover,
    required this.pressed,
    required this.selected,
    required this.completed,
    required this.lightBackground,
    required this.border,
    required this.text,
  });

  factory HabitColorShades.fromColor(Color color) {
    return HabitColorShades(
      base: color,
      primary: color,
      hover: color.withValues(alpha: 0.28),
      pressed: color.withValues(alpha: 0.45),
      selected: color,
      completed: color,
      lightBackground: color.withValues(alpha: 0.12),
      border: color.withValues(alpha: 0.35),
      text: color,
    );
  }

  factory HabitColorShades.fromHex(
    String? hex, {
    Color defaultColor = const Color(0xFF7C3AED),
  }) {
    final color = parseHexColor(hex, defaultColor: defaultColor);
    return HabitColorShades.fromColor(color);
  }
}

Color parseHexColor(
  String? hexString, {
  Color defaultColor = const Color(0xFF7C3AED),
}) {
  if (hexString == null || hexString.isEmpty) {
    return defaultColor;
  }
  try {
    String cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    return Color(int.parse(cleanHex, radix: 16));
  } catch (_) {
    return defaultColor;
  }
}

String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
