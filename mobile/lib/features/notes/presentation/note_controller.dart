import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../habits/domain/streak_calculator.dart';
import '../../habits/presentation/habit_controller.dart';
import '../data/note_repository.dart';

class DailyNoteState {
  final String habitId;
  final DateTime date;
  final String content;
  final bool isLoading;
  final bool isSaving;
  final bool hasExistingNote;
  final String? errorMessage;

  const DailyNoteState({
    required this.habitId,
    required this.date,
    this.content = '',
    this.isLoading = false,
    this.isSaving = false,
    this.hasExistingNote = false,
    this.errorMessage,
  });

  String get dateStr => formatDateKey(date);

  DailyNoteState copyWith({
    String? habitId,
    DateTime? date,
    String? content,
    bool? isLoading,
    bool? isSaving,
    bool? hasExistingNote,
    String? errorMessage,
  }) {
    return DailyNoteState(
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      content: content ?? this.content,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      hasExistingNote: hasExistingNote ?? this.hasExistingNote,
      errorMessage: errorMessage,
    );
  }
}

final dailyNoteControllerProvider =
    NotifierProvider<DailyNoteNotifier, DailyNoteState>(() {
  return DailyNoteNotifier();
});

class DailyNoteNotifier extends Notifier<DailyNoteState> {
  late final NoteRepository _repository;

  @override
  DailyNoteState build() {
    _repository = ref.watch(noteRepositoryProvider);
    return DailyNoteState(habitId: '', date: DateTime.now());
  }

  /// Initializes or changes the active note session for (habitId, date).
  /// Authoritatively loads the persisted note from database/repository.
  /// Pre-populates with [initialContent] if provided, avoiding layout shifts or flash.
  Future<void> loadNote(
    String habitId,
    DateTime date, {
    String initialContent = '',
  }) async {
    final dateStr = formatDateKey(date);
    final hasInit = initialContent.trim().isNotEmpty;

    // 1. Immediately reset state for the targeted habitId + date combination
    state = DailyNoteState(
      habitId: habitId,
      date: date,
      content: initialContent,
      hasExistingNote: hasInit,
      isLoading: true,
      errorMessage: null,
    );

    // 2. Authoritatively fetch persisted note for (habitId, selectedDate)
    try {
      final note = await _repository.getNote(habitId, dateStr);

      // Verify the response matches the currently active session
      if (state.habitId == habitId && formatDateKey(state.date) == dateStr) {
        if (note != null && note.content.trim().isNotEmpty) {
          state = state.copyWith(
            content: note.content.trim(),
            hasExistingNote: true,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            content: '',
            hasExistingNote: false,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      if (state.habitId == habitId && formatDateKey(state.date) == dateStr) {
        state = state.copyWith(
          content: initialContent,
          hasExistingNote: hasInit,
          isLoading: false,
          errorMessage: 'Failed to load note: $e',
        );
      }
    }
  }

  /// Switch the date while keeping the current habit
  Future<void> changeDate(DateTime newDate) async {
    if (state.habitId.isEmpty) return;
    await loadNote(state.habitId, newDate);
  }

  /// Switch the habit while keeping the current date
  Future<void> changeHabit(String newHabitId) async {
    await loadNote(newHabitId, state.date);
  }

  /// Saves the note for the current (habitId, selectedDate).
  /// If content is empty/cleared, deletes the note record.
  Future<bool> saveNote(String rawContent) async {
    final habitId = state.habitId;
    final date = state.date;
    final dateStr = formatDateKey(date);
    final trimmed = rawContent.trim();

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      if (trimmed.isEmpty) {
        if (state.hasExistingNote) {
          await _repository.deleteNote(habitId, dateStr);
        }
        ref.read(habitControllerProvider.notifier).updateNoteState(
              habitId,
              dateStr,
              null,
            );
        state = state.copyWith(
          content: '',
          hasExistingNote: false,
          isSaving: false,
        );
      } else {
        await _repository.saveNote(habitId, dateStr, trimmed);
        ref.read(habitControllerProvider.notifier).updateNoteState(
              habitId,
              dateStr,
              trimmed,
            );
        state = state.copyWith(
          content: trimmed,
          hasExistingNote: true,
          isSaving: false,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save note: $e',
      );
      return false;
    }
  }

  /// Deletes the note for the current (habitId, selectedDate).
  Future<bool> deleteNote() async {
    final habitId = state.habitId;
    final date = state.date;
    final dateStr = formatDateKey(date);

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await _repository.deleteNote(habitId, dateStr);
      ref.read(habitControllerProvider.notifier).updateNoteState(
            habitId,
            dateStr,
            null,
          );
      state = state.copyWith(
        content: '',
        hasExistingNote: false,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to delete note: $e',
      );
      return false;
    }
  }
}
