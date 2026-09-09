import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/habit_icons_catalog.dart';
import '../../habits/presentation/habit_controller.dart';
import 'note_controller.dart';

class DailyNoteScreen extends ConsumerStatefulWidget {
  final Habit habit;
  final DateTime date;

  const DailyNoteScreen({
    super.key,
    required this.habit,
    required this.date,
  });

  static Future<void> show(BuildContext context, Habit habit, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DailyNoteScreen(habit: habit, date: date),
    );
  }

  @override
  ConsumerState<DailyNoteScreen> createState() => _DailyNoteScreenState();
}

class _DailyNoteScreenState extends ConsumerState<DailyNoteScreen> {
  late final TextEditingController _controller;
  late Habit _currentHabit;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
    _currentDate = widget.date;
    final initialContent = widget.habit.noteOn(widget.date) ?? '';
    _controller = TextEditingController(text: initialContent);

    // Synchronize note state immediately without layout shifts or flashes
    Future.microtask(() {
      if (mounted) {
        ref.read(dailyNoteControllerProvider.notifier).loadNote(
              _currentHabit.id,
              _currentDate,
              initialContent: initialContent,
            );
      }
    });
  }

  @override
  void didUpdateWidget(covariant DailyNoteScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.id != widget.habit.id ||
        formatDateKey(oldWidget.date) != formatDateKey(widget.date)) {
      _currentHabit = widget.habit;
      _currentDate = widget.date;
      final newContent = widget.habit.noteOn(widget.date) ?? '';
      _controller.text = newContent;
      ref.read(dailyNoteControllerProvider.notifier).loadNote(
            _currentHabit.id,
            _currentDate,
            initialContent: newContent,
          );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime newDate) {
    if (formatDateKey(_currentDate) == formatDateKey(newDate)) return;
    final newContent = _currentHabit.noteOn(newDate) ?? '';
    setState(() {
      _currentDate = newDate;
      _controller.text = newContent;
    });
    ref.read(dailyNoteControllerProvider.notifier).loadNote(
          _currentHabit.id,
          newDate,
          initialContent: newContent,
        );
  }

  void _onHabitChanged(Habit newHabit) {
    if (_currentHabit.id == newHabit.id) return;
    final newContent = newHabit.noteOn(_currentDate) ?? '';
    setState(() {
      _currentHabit = newHabit;
      _controller.text = newContent;
    });
    ref.read(dailyNoteControllerProvider.notifier).loadNote(
          newHabit.id,
          _currentDate,
          initialContent: newContent,
        );
  }

  Future<void> _handleSave() async {
    final success = await ref
        .read(dailyNoteControllerProvider.notifier)
        .saveNote(_controller.text);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    final success =
        await ref.read(dailyNoteControllerProvider.notifier).deleteNote();
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to note state changes to update text field
    ref.listen<DailyNoteState>(dailyNoteControllerProvider, (prev, next) {
      if (next.habitId == _currentHabit.id &&
          formatDateKey(next.date) == formatDateKey(_currentDate)) {
        if (next.content != _controller.text && !next.isSaving) {
          _controller.text = next.content;
          _controller.selection =
              TextSelection.fromPosition(TextPosition(offset: next.content.length));
        }
      }

      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    });

    final noteState = ref.watch(dailyNoteControllerProvider);
    final allHabits = ref.watch(habitControllerProvider).value ?? [_currentHabit];
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final shades = _currentHabit.colorShades;
    final appShades = ref.watch(appThemeShadesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final textMuted = AppTheme.getTextMuted(context);
    final borderColor = AppTheme.getBorderColor(context);
    final habitIconData = getHabitIcon(_currentHabit.icon);
    final formattedDate = DateFormat('MMMM d, yyyy').format(_currentDate);

    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: bottomInset + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Habit Icon, Name/Habit Selector, Date with Nav Arrows & Close Button
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: shades.lightBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Icon(habitIconData, color: shades.primary, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allHabits.length > 1)
                        PopupMenuButton<Habit>(
                          initialValue: _currentHabit,
                          tooltip: 'Switch habit',
                          onSelected: _onHabitChanged,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  _currentHabit.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                            ],
                          ),
                          itemBuilder: (context) {
                            return allHabits.map((h) {
                              return PopupMenuItem<Habit>(
                                value: h,
                                child: Row(
                                  children: [
                                    Icon(
                                      getHabitIcon(h.icon),
                                      size: 18,
                                      color: h.colorShades.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      h.name,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: h.id == _currentHabit.id
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                        )
                      else
                        Text(
                          _currentHabit.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      // Date Navigation Row with previous and next day controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              _onDateChanged(
                                _currentDate.subtract(const Duration(days: 1)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              _onDateChanged(
                                _currentDate.add(const Duration(days: 1)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 2,
                              ),
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Notes Input Box (Stable, non-collapsing container with autofocus disabled)
            Container(
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _controller,
                maxLines: 6,
                minLines: 4,
                autofocus: false,
                cursorColor: appShades.primary,
                style: TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a note...\nWhat did you do today? Reflections, metrics, or details...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: textMuted,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons: Save & Delete
            Row(
              children: [
                if (noteState.hasExistingNote) ...[
                  IconButton.filledTonal(
                    onPressed: noteState.isSaving ? null : _handleDelete,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    tooltip: 'Delete note',
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: noteState.isSaving || noteState.isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appShades.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: noteState.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Note',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
