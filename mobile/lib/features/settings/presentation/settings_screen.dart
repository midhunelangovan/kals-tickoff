import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../data/backup_service.dart';
import 'reorder_habits_screen.dart';
import 'theme_settings_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  void _showThemeModeDialog() {
    final currentMode = ref.read(appThemeModeProvider);
    final textPrimary = AppTheme.getTextPrimary(context);
    final appShades = ref.read(appThemeShadesProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Choose Theme',
          style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: currentMode,
              activeColor: appShades.primary,
              title: const Text('System Default'),
              subtitle: const Text('Match system display settings'),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: currentMode,
              activeColor: appShades.primary,
              title: const Text('Light Theme'),
              subtitle: const Text('Clean neutral off-white'),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: currentMode,
              activeColor: appShades.primary,
              title: const Text('Dark Theme'),
              subtitle: const Text('Sleek dark slate aesthetic'),
              onChanged: (val) {
                if (val != null) {
                  ref.read(appThemeModeProvider.notifier).setThemeMode(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog() {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final appShades = ref.read(appThemeShadesProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Create Backup',
          style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: Text(
          'Your habits, completion history, notes and settings will be exported.',
          style: TextStyle(color: textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appShades.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _handleExport();
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final success = await service.exportBackup();
      if (success && mounted) {
        final textPrimary = AppTheme.getTextPrimary(context);
        final textSecondary = AppTheme.getTextSecondary(context);
        final appShades = ref.read(appThemeShadesProvider);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              'Backup Created',
              style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
            ),
            content: Text(
              'Your data has been exported successfully.',
              style: TextStyle(color: textSecondary),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: appShades.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Export Error', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleImportFlow() async {
    setState(() => _isImporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      final rawJson = await service.pickBackupFile();
      if (rawJson == null || rawJson.trim().isEmpty) {
        return;
      }

      BackupSummary summary;
      try {
        summary = service.validateBackup(rawJson);
      } on InvalidBackupException {
        if (mounted) {
          _showErrorDialog(
            'Invalid Backup',
            'This file is not a valid Habit Tracker backup.',
          );
        }
        return;
      } on UnsupportedBackupException {
        if (mounted) {
          _showErrorDialog(
            'Unsupported Backup',
            'This backup was created by a newer version of the application.\n\nPlease update the application first.',
          );
        }
        return;
      }

      if (mounted) {
        _showBackupFoundDialog(summary);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Import Error', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showBackupFoundDialog(BackupSummary summary) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final appShades = ref.read(appThemeShadesProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Backup Found',
          style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Habits', summary.habitsCount.toString(), textSecondary, textPrimary),
            const SizedBox(height: 6),
            _buildStatRow('Completion records', summary.completionsCount.toString(), textSecondary, textPrimary),
            const SizedBox(height: 6),
            _buildStatRow('Notes', summary.notesCount.toString(), textSecondary, textPrimary),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: appShades.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showConfirmRestoreDialog(summary);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 15)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showConfirmRestoreDialog(BackupSummary summary) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Restore Backup?',
          style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: Text(
          'Restoring this backup will replace your current habit data.\n\nYour current data may be lost.',
          style: TextStyle(color: textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performRestore(summary);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BackupSummary summary) async {
    setState(() => _isImporting = true);
    try {
      final service = ref.read(backupServiceProvider);
      await service.restoreBackup(summary);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup restored successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Restore Failed', e.toString());
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
        ),
        content: Text(
          message,
          style: TextStyle(color: textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appThemeModeProvider);
    final tickAnim = ref.watch(tickAnimationEnabledProvider);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final borderColor = AppTheme.getBorderColor(context);
    final appShades = ref.watch(appThemeShadesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ─── Section 1: Appearance ────────────────────────────────
          _buildSectionHeader('Appearance', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Text('🌓', style: TextStyle(fontSize: 20)),
                  title: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    _themeModeLabel(themeMode),
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                  ),
                  onTap: _showThemeModeDialog,
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Text('🎨', style: TextStyle(fontSize: 20)),
                  title: Text(
                    'Accent Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Primary theme color',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  trailing: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: appShades.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: appShades.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  onTap: () => ThemeSettingsSheet.show(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Section 2: Behavior ──────────────────────────────────
          _buildSectionHeader('Behavior', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Text('☷', style: TextStyle(fontSize: 20)),
                  title: Text(
                    'Reorder Habits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: textSecondary,
                  ),
                  onTap: () => ReorderHabitsScreen.show(context),
                ),
                Divider(height: 1, color: borderColor),
                SwitchListTile(
                  title: Text(
                    'Tick Animation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Subtle scale and pop effect on check',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  secondary: const Text('✓', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  value: tickAnim,
                  activeColor: appShades.primary,
                  onChanged: (val) {
                    ref.read(tickAnimationEnabledProvider.notifier).setEnabled(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Section 3: Notes ─────────────────────────────────────
          _buildSectionHeader('Notes', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: ListTile(
              leading: const Text('📝', style: TextStyle(fontSize: 20)),
              title: Text(
                'Daily Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              subtitle: Text(
                'Each habit supports isolated daily reflection notes',
                style: TextStyle(fontSize: 13, color: textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Section 4: Data ──────────────────────────────────────
          _buildSectionHeader('Data', textSecondary),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Text('☁', style: TextStyle(fontSize: 20)),
                  title: Text(
                    'Backup Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Export your habits, history & notes',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: textSecondary,
                        ),
                  onTap: _isExporting ? null : _showBackupDialog,
                ),
                Divider(height: 1, color: borderColor),
                ListTile(
                  leading: const Text('↻', style: TextStyle(fontSize: 20)),
                  title: Text(
                    'Import Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Restore from a backup JSON file',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  trailing: _isImporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: textSecondary,
                        ),
                  onTap: _isImporting ? null : _handleImportFlow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Section 5: Application Information ───────────────────
          _buildSectionHeader('About', textSecondary),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: appShades.backgroundTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.auto_stories_rounded, color: appShades.primary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kals TickOff',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.2.0 (Build 3)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: borderColor),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.security_rounded, size: 18, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Offline-First • Local SQLite Storage',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
