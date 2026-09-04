import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../app/theme.dart';
import '../../../app/theme_controller.dart';
import '../../habits/domain/habit_color_palette.dart';
import '../../habits/presentation/habit_controller.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dio = ref.watch(dioProvider);
  return BackupService(dio, ref);
});

class BackupSummary {
  final int habitsCount;
  final int completionsCount;
  final int notesCount;
  final Map<String, dynamic> rawData;

  const BackupSummary({
    required this.habitsCount,
    required this.completionsCount,
    required this.notesCount,
    required this.rawData,
  });
}

class InvalidBackupException implements Exception {
  final String message;
  InvalidBackupException(this.message);
  @override
  String toString() => message;
}

class UnsupportedBackupException implements Exception {
  final String message;
  UnsupportedBackupException(this.message);
  @override
  String toString() => message;
}

class BackupService {
  static const MethodChannel _channel = MethodChannel('io.kals.tickoff/backend');
  final Dio _dio;
  final Ref _ref;

  BackupService(this._dio, this._ref);

  Future<bool> exportBackup() async {
    final response = await _dio.get('/backup/export');
    if (response.statusCode != 200 || response.data is! Map) {
      throw Exception('Failed to export data from local database');
    }

    final Map<String, dynamic> exportData =
        Map<String, dynamic>.from(response.data as Map);

    // Attach local settings from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final themeColor = prefs.getString('tickoff_app_theme_color') ?? '#7C3AED';
    final themeMode = prefs.getString('tickoff_theme_mode') ?? 'light';
    final tickAnim = prefs.getBool('tickoff_tick_animation_enabled') ?? true;

    exportData['settings'] = {
      'themeColor': themeColor,
      'themeMode': themeMode,
      'tickAnimationEnabled': tickAnim,
    };

    exportData['app'] = 'Kals TickOff';

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final fileName = 'kals_tickoff_backup_$dateStr.json';
    final jsonContent = const JsonEncoder.withIndent('  ').convert(exportData);

    final success = await _channel.invokeMethod<bool>('shareBackup', {
      'fileName': fileName,
      'content': jsonContent,
    });

    return success ?? false;
  }

  Future<String?> pickBackupFile() async {
    return await _channel.invokeMethod<String>('pickBackupFile');
  }

  BackupSummary validateBackup(String rawJson) {
    dynamic parsed;
    try {
      parsed = jsonDecode(rawJson);
    } catch (_) {
      throw InvalidBackupException('This file is not a valid Kals TickOff backup.');
    }

    if (parsed is! Map<String, dynamic>) {
      throw InvalidBackupException('This file is not a valid Kals TickOff backup.');
    }

    final app = parsed['app']?.toString();
    if (app != 'Kals TickOff' && app != 'Kals Log' && app != 'Habit Tracker') {
      throw InvalidBackupException('This file is not a valid Kals TickOff backup.');
    }

    final version = (parsed['version'] as num?)?.toInt() ?? 0;
    if (version > 1) {
      throw UnsupportedBackupException(
        'This backup was created by a newer version of the application. Please update the application first.',
      );
    }

    final habits = parsed['habits'] is List ? (parsed['habits'] as List) : [];
    final completions =
        parsed['completions'] is List ? (parsed['completions'] as List) : [];
    final notes = parsed['notes'] is List ? (parsed['notes'] as List) : [];

    return BackupSummary(
      habitsCount: habits.length,
      completionsCount: completions.length,
      notesCount: notes.length,
      rawData: parsed,
    );
  }

  Future<void> restoreBackup(BackupSummary summary) async {
    // 1. Restore database atomically via backend endpoint
    final response = await _dio.post('/backup/restore', data: summary.rawData);
    if (response.statusCode != 200) {
      throw Exception('Database restore failed. Original data was preserved.');
    }

    // 2. Restore settings if present
    if (summary.rawData['settings'] is Map) {
      final settings = summary.rawData['settings'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      if (settings['themeColor'] is String) {
        final colorHex = settings['themeColor'] as String;
        await prefs.setString('tickoff_app_theme_color', colorHex);
        _ref
            .read(appThemeColorProvider.notifier)
            .setThemeColor(parseHexColor(colorHex, defaultColor: AppTheme.defaultPrimaryColor));
      }

      if (settings['themeMode'] is String) {
        final mode = settings['themeMode'] as String;
        await prefs.setString('tickoff_theme_mode', mode);
        _ref
            .read(appThemeModeProvider.notifier)
            .setThemeMode(mode == 'dark' ? ThemeMode.dark : ThemeMode.light);
      }

      if (settings['tickAnimationEnabled'] is bool) {
        final anim = settings['tickAnimationEnabled'] as bool;
        await prefs.setBool('tickoff_tick_animation_enabled', anim);
        _ref
            .read(tickAnimationEnabledProvider.notifier)
            .setEnabled(anim);
      }
    }

    // 3. Reload habit data & scores
    await _ref.read(habitControllerProvider.notifier).loadHabits();
    await _ref.read(habitScoreProvider.notifier).refreshScore();
  }
}
