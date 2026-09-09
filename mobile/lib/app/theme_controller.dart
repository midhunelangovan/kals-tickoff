import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/habits/domain/habit_color_palette.dart';
import 'theme.dart';

const String _kThemePrefKey = 'tickoff_app_theme_color';
const String _kThemeModePrefKey = 'tickoff_theme_mode';
const String _kTickAnimationPrefKey = 'tickoff_tick_animation_enabled';

final appThemeColorProvider =
    NotifierProvider<AppThemeNotifier, Color>(() {
  return AppThemeNotifier();
});

final appThemeShadesProvider = Provider<AppThemeShades>((ref) {
  final color = ref.watch(appThemeColorProvider);
  return AppThemeShades.fromColor(color);
});

final appThemeModeProvider =
    NotifierProvider<AppThemeModeNotifier, ThemeMode>(() {
  return AppThemeModeNotifier();
});

final tickAnimationEnabledProvider =
    NotifierProvider<TickAnimationNotifier, bool>(() {
  return TickAnimationNotifier();
});

class AppThemeNotifier extends Notifier<Color> {
  @override
  Color build() {
    _loadSavedTheme();
    return AppTheme.defaultPrimaryColor;
  }

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedHex = prefs.getString(_kThemePrefKey);
      if (savedHex != null && savedHex.isNotEmpty) {
        state = parseHexColor(savedHex, defaultColor: AppTheme.defaultPrimaryColor);
      }
    } catch (_) {
      // In-memory fallback
    }
  }

  Future<void> setThemeColor(Color color) async {
    state = color;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemePrefKey, colorToHex(color));
    } catch (_) {
      // Fallback
    }
  }
}

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSavedMode();
    return ThemeMode.system;
  }

  Future<void> _loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_kThemeModePrefKey);
      if (modeStr == 'dark') {
        state = ThemeMode.dark;
      } else if (modeStr == 'light') {
        state = ThemeMode.light;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      await prefs.setString(_kThemeModePrefKey, modeStr);
    } catch (_) {
      // Fallback
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}

class TickAnimationNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSavedSetting();
    return true; // Default ON
  }

  Future<void> _loadSavedSetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_kTickAnimationPrefKey)) {
        state = prefs.getBool(_kTickAnimationPrefKey) ?? true;
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kTickAnimationPrefKey, value);
    } catch (_) {
      // Fallback
    }
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

ThemeData buildCustomTheme(Color primaryColor, {bool isDark = false}) {
  final shades = AppThemeShades.fromColor(primaryColor);

  final colorScheme = isDark
      ? ColorScheme.dark(
          primary: shades.primary,
          onPrimary: Colors.white,
          secondary: shades.primaryLight,
          onSecondary: Colors.black,
          primaryContainer: shades.primaryDark,
          onPrimaryContainer: Colors.white,
          surface: AppTheme.darkCardColor,
          onSurface: AppTheme.darkTextPrimary,
          error: const Color(0xFFEF4444),
        )
      : ColorScheme.light(
          primary: shades.primary,
          onPrimary: Colors.white,
          secondary: shades.primaryDark,
          onSecondary: Colors.white,
          primaryContainer: shades.primaryLight,
          onPrimaryContainer: shades.primaryDark,
          surface: AppTheme.cardColor,
          onSurface: AppTheme.textPrimary,
          error: const Color(0xFFEF4444),
        );

  final scaffoldBg =
      isDark ? AppTheme.darkScaffoldBackground : AppTheme.scaffoldBackground;
  final cardBg = isDark ? AppTheme.darkCardColor : AppTheme.cardColor;
  final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
  final textSecondary =
      isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
  final borderColor = isDark ? AppTheme.darkBorderColor : AppTheme.borderColor;

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: scaffoldBg,
    cardColor: cardBg,
    primaryColor: shades.primary,
    dividerColor: borderColor,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldBg,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontSize: 15,
        color: textSecondary,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: shades.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: shades.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: shades.primary,
      linearTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
      circularTrackColor: shades.hover,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return shades.primary;
        }
        return Colors.transparent;
      }),
      checkColor: const WidgetStatePropertyAll(Colors.white),
      side: BorderSide(color: shades.border, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: shades.primary,
      selectionColor: shades.hover,
      selectionHandleColor: shades.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      hintStyle: TextStyle(
        color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: TextStyle(
        color: textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: shades.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: shades.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    ),
  );
}
