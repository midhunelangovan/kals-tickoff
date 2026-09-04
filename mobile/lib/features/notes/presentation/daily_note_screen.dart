import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/habit_icons_catalog.dart';
import '../../habits/presentation/habit_controller.dart';
import '../data/note_repository.dart';

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
  bool _isLoading = false;
  bool _isFetching = true;
  bool _hasExistingNote = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _fetchNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchNote() async {
    final dateStr = formatDateKey(widget.date);
    // If the habit already has the note cached for this selectedDate, use it immediately
    if (widget.habit.selectedDate != null &&
        formatDateKey(widget.habit.selectedDate!) == dateStr &&
        widget.habit.noteContent != null) {
      _controller.text = widget.habit.noteContent!;
      _hasExistingNote = widget.habit.noteContent!.isNotEmpty;
      setState(() => _isFetching = false);
      return;
    }

    try {
      final repo = ref.read(noteRepositoryProvider);
      final note = await repo.getNote(widget.habit.id, dateStr);
      if (mounted) {
        if (note != null && note.content.isNotEmpty) {
          _controller.text = note.content;
          _hasExistingNote = true;
        }
        setState(() => _isFetching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _saveNote() async {
    final content = _controller.text.trim();
    final dateStr = formatDateKey(widget.date);
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      if (content.isEmpty && _hasExistingNote) {
        await repo.deleteNote(widget.habit.id, dateStr);
        ref.read(habitControllerProvider.notifier).updateNoteState(
              widget.habit.id,
              dateStr,
              null,
            );
      } else if (content.isNotEmpty) {
        await repo.saveNote(widget.habit.id, dateStr, content);
        ref.read(habitControllerProvider.notifier).updateNoteState(
              widget.habit.id,
              dateStr,
              content,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNote() async {
    final dateStr = formatDateKey(widget.date);
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(noteRepositoryProvider);
      await repo.deleteNote(widget.habit.id, dateStr);
      ref.read(habitControllerProvider.notifier).updateNoteState(
            widget.habit.id,
            dateStr,
            null,
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete note: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final shades = widget.habit.colorShades;
    final appShades = ref.watch(appThemeShadesProvider);
    final cardBg = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final borderColor = AppTheme.getBorderColor(context);
    final habitIconData = getHabitIcon(widget.habit.icon);
    final formattedDate = DateFormat('MMMM d, yyyy').format(widget.date);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset + 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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

            // Header Row: Habit icon, name, formatted date & close button
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
                      Text(
                        widget.habit.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
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

            // Notes input box
            if (_isFetching)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _controller,
                  maxLines: 6,
                  minLines: 4,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 15,
                    color: textPrimary,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: 'What did you do today?\nAdd notes, reflections, or details...',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: AppTheme.getTextMuted(context),
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
                if (_hasExistingNote) ...[
                  IconButton.filledTonal(
                    onPressed: _isLoading ? null : _deleteNote,
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
                    onPressed: _isLoading || _isFetching ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appShades.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
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
    );
  }
}
