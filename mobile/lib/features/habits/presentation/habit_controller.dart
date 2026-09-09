import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_repository.dart';
import '../domain/habit_score.dart';
import '../domain/habit_score_calculator.dart';

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void selectDate(DateTime date) => state = date;
}

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, DateTime>(() {
  return SelectedDateNotifier();
});

class SelectedHabitIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String habitId) {
    if (state.contains(habitId)) {
      state = state.where((id) => id != habitId).toSet();
    } else {
      state = {...state, habitId};
    }
  }

  void select(String habitId) {
    state = {...state, habitId};
  }

  void clear() {
    state = {};
  }
}

final selectedHabitIdsProvider =
    NotifierProvider<SelectedHabitIdsNotifier, Set<String>>(() {
  return SelectedHabitIdsNotifier();
});

final habitScoreProvider =
    AsyncNotifierProvider<HabitScoreNotifier, HabitScore>(() {
  return HabitScoreNotifier();
});

class HabitScoreNotifier extends AsyncNotifier<HabitScore> {
  late final HabitRepository _repository;

  @override
  FutureOr<HabitScore> build() {
    _repository = ref.watch(apiHabitRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    return _repository.getHabitScore(selectedDate);
  }

  Future<void> refreshScore([DateTime? date]) async {
    final DateTime targetDate = date ?? ref.read(selectedDateProvider);
    state = await AsyncValue.guard(() => _repository.getHabitScore(targetDate));
  }

  void setOptimisticScore(HabitScore score) {
    state = AsyncValue.data(score);
  }
}

final habitControllerProvider =
    AsyncNotifierProvider<HabitController, List<Habit>>(() {
  return HabitController();
});

class HabitController extends AsyncNotifier<List<Habit>> {
  late final HabitRepository _repository;
  List<Habit> _masterHabits = [];

  List<Habit> _getApplicableHabitsFor(DateTime date) {
    return _masterHabits
        .where((h) => h.isApplicableOn(date))
        .map((h) => h.copyWith(
              completed: h.isCompletedOn(date),
              hasNote: h.hasNoteOn(date),
              noteContent: h.noteOn(date),
              clearNote: !h.hasNoteOn(date),
              selectedDate: date,
            ))
        .toList();
  }

  void _mergeMasterHabits(List<Habit> incoming) {
    final map = {for (final h in _masterHabits) h.id: h};
    for (final h in incoming) {
      if (map.containsKey(h.id)) {
        final existing = map[h.id]!;
        final mergedNotes = Map<String, String>.from(existing.notesByDate);
        mergedNotes.addAll(h.notesByDate);
        if (h.selectedDate != null) {
          final dateKey = formatDateKey(h.selectedDate!);
          if (h.hasNote && h.noteContent != null && h.noteContent!.trim().isNotEmpty) {
            mergedNotes[dateKey] = h.noteContent!.trim();
          } else {
            mergedNotes.remove(dateKey);
          }
        }

        map[h.id] = existing.copyWith(
          name: h.name,
          icon: h.icon,
          color: h.color,
          description: h.description,
          archived: h.archived,
          sortOrder: h.sortOrder,
          // CRITICAL: Preserve existing creation date so historical creation is never mutated
          createdAt: existing.createdAt,
          // Cumulative completion dates so historical completion records are preserved
          completedDates: {...existing.completedDates, ...h.completedDates},
          notesByDate: mergedNotes,
        );
      } else {
        map[h.id] = h;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) {
      final cmp = a.sortOrder.compareTo(b.sortOrder);
      if (cmp != 0) return cmp;
      return b.createdAt.compareTo(a.createdAt);
    });
    _masterHabits = list;
  }

  @override
  FutureOr<List<Habit>> build() async {
    _repository = ref.watch(apiHabitRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final habits = await _repository.getHabits(date: selectedDate);
    _mergeMasterHabits(habits);
    return _getApplicableHabitsFor(selectedDate);
  }

  Future<void> loadHabits({DateTime? date}) async {
    final DateTime targetDate = date ?? ref.read(selectedDateProvider);
    state = const AsyncValue.loading();
    try {
      final habits = await _repository.getHabits(date: targetDate);
      _mergeMasterHabits(habits);
      state = AsyncValue.data(_getApplicableHabitsFor(targetDate));
      ref.read(habitScoreProvider.notifier).refreshScore(targetDate);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> changeSelectedDate(DateTime newDate) async {
    // 1. Update selected date
    ref.read(selectedDateProvider.notifier).selectDate(newDate);

    // 2. Immediate 0ms local state update from master habits for newDate
    final instantApplicable = _getApplicableHabitsFor(newDate);
    state = AsyncValue.data(instantApplicable);

    // 3. Immediate 0ms local habit score update for selected date
    final instantScore = HabitScoreCalculator.calculateForDate(
      habits: _masterHabits,
      date: newDate,
    );
    ref.read(habitScoreProvider.notifier).setOptimisticScore(instantScore);

    // 4. Silently synchronize with backend without full-screen loader
    try {
      final serverHabits = await _repository.getHabits(date: newDate);
      _mergeMasterHabits(serverHabits);
      state = AsyncValue.data(_getApplicableHabitsFor(newDate));
      ref.read(habitScoreProvider.notifier).refreshScore(newDate);
    } catch (_) {
      // Keep optimistic state if network fails
    }
  }

  Future<void> addHabit(
    String name, {
    String icon = 'bolt',
    String? description,
    String? color,
    DateTime? createdAt,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final selectedDate = ref.read(selectedDateProvider);
    final targetCreationDate = createdAt ?? selectedDate;

    final newHabit = await _repository.createHabit(
      trimmed,
      icon: icon,
      description: description,
      color: color,
      createdAt: targetCreationDate,
    );
    _mergeMasterHabits([newHabit]);
    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));
    ref.read(habitScoreProvider.notifier).refreshScore(selectedDate);
  }

  Future<void> editHabit(
    String habitId, {
    required String name,
    required String icon,
    String? color,
    String? description,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final updated = await _repository.updateHabit(
      habitId,
      name: trimmed,
      icon: icon,
      color: color,
      description: description,
    );

    _masterHabits = _masterHabits.map((h) {
      if (h.id == habitId) {
        return h.copyWith(
          name: updated.name,
          icon: updated.icon,
          color: updated.color,
          description: updated.description,
        );
      }
      return h;
    }).toList();

    final selectedDate = ref.read(selectedDateProvider);
    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));
    ref.read(habitScoreProvider.notifier).refreshScore(selectedDate);
  }

  Future<void> deleteHabit(String habitId) async {
    await _repository.deleteHabit(habitId);
    ref.read(selectedHabitIdsProvider.notifier).clear();
    _masterHabits = _masterHabits.where((h) => h.id != habitId).toList();
    final selectedDate = ref.read(selectedDateProvider);
    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));
    ref.read(habitScoreProvider.notifier).refreshScore(selectedDate);
  }

  Future<void> toggleCompletion(Habit habit, {DateTime? date}) async {
    final DateTime selectedDate = date ?? ref.read(selectedDateProvider);
    final String selectedDateStr = formatDateKey(selectedDate);
    final DateTime today = DateTime.now();

    final wasCompleted = habit.completed;
    final willComplete = !wasCompleted;

    // 1. Optimistically update completedDates set
    final updatedCompletedDates = Set<String>.from(habit.completedDates);
    if (willComplete) {
      updatedCompletedDates.add(selectedDateStr);
    } else {
      updatedCompletedDates.remove(selectedDateStr);
    }

    // 2. Calculate optimistic current streak strictly relative to TODAY
    final optimisticStreak = calculateCurrentStreak(updatedCompletedDates, today);

    _masterHabits = _masterHabits.map((h) {
      if (h.id == habit.id) {
        return h.copyWith(
          completed: willComplete,
          currentStreak: optimisticStreak,
          completedDates: updatedCompletedDates,
          selectedDate: selectedDate,
        );
      }
      return h;
    }).toList();

    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));

    // Optimistically update selected-date Habit Score using pure HabitScoreCalculator
    final optimisticScore = HabitScoreCalculator.calculateForDate(
      habits: _masterHabits,
      date: selectedDate,
      enableLogging: true,
    );
    ref.read(habitScoreProvider.notifier).setOptimisticScore(optimisticScore);

    // 3. Send API request
    try {
      final serverResult = willComplete
          ? await _repository.markCompleted(habit.id, selectedDate)
          : await _repository.unmarkCompleted(habit.id, selectedDate);

      _masterHabits = _masterHabits.map((h) {
        if (h.id == habit.id) {
          final serverDates = serverResult.completedDates.isNotEmpty
              ? serverResult.completedDates
              : updatedCompletedDates;

          return h.copyWith(
            completed: serverResult.completed,
            currentStreak: serverResult.currentStreak,
            completedDates: serverDates,
            selectedDate: selectedDate,
          );
        }
        return h;
      }).toList();

      state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));
      ref.read(habitScoreProvider.notifier).refreshScore(selectedDate);
    } catch (error) {
      // Rollback on failure
      updatedCompletedDates.remove(selectedDateStr);
      if (wasCompleted) updatedCompletedDates.add(selectedDateStr);
      _masterHabits = _masterHabits.map((h) {
        if (h.id == habit.id) {
          return h.copyWith(
            completed: wasCompleted,
            completedDates: updatedCompletedDates,
            selectedDate: selectedDate,
          );
        }
        return h;
      }).toList();
      state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));

      final rollbackScore = HabitScoreCalculator.calculateForDate(
        habits: _masterHabits,
        date: selectedDate,
      );
      ref.read(habitScoreProvider.notifier).setOptimisticScore(rollbackScore);
      rethrow;
    }
  }

  Future<void> reorderHabits(List<String> orderedIds) async {
    final habitMap = {for (final h in _masterHabits) h.id: h};
    final reordered = <Habit>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final h = habitMap[orderedIds[i]];
      if (h != null) {
        reordered.add(h.copyWith(sortOrder: i));
      }
    }
    for (final h in _masterHabits) {
      if (!orderedIds.contains(h.id)) {
        reordered.add(h);
      }
    }
    _masterHabits = reordered;

    final selectedDate = ref.read(selectedDateProvider);
    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));

    try {
      await _repository.reorderHabits(orderedIds);
    } catch (_) {
      // Revert if needed or ignore
    }
  }

  void updateNoteState(String habitId, String dateStr, String? content) {
    final trimmed = (content != null && content.trim().isNotEmpty) ? content.trim() : null;

    // 1. Update master habits notesByDate
    _masterHabits = _masterHabits.map((h) {
      if (h.id == habitId) {
        final updatedNotes = Map<String, String>.from(h.notesByDate);
        if (trimmed != null) {
          updatedNotes[dateStr] = trimmed;
        } else {
          updatedNotes.remove(dateStr);
        }
        return h.copyWith(notesByDate: updatedNotes);
      }
      return h;
    }).toList();

    // 2. Project state for currently selected date
    final selectedDate = ref.read(selectedDateProvider);
    state = AsyncValue.data(_getApplicableHabitsFor(selectedDate));
  }
}
