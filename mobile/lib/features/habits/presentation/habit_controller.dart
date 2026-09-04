import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_habit_repository.dart';
import '../domain/habit.dart';
import '../domain/habit_repository.dart';
import '../domain/habit_score.dart';

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

  Future<void> refreshScore({DateTime? date}) async {
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

  @override
  FutureOr<List<Habit>> build() {
    _repository = ref.watch(apiHabitRepositoryProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    return _repository.getHabits(date: selectedDate);
  }

  Future<void> loadHabits({DateTime? date}) async {
    final DateTime targetDate = date ?? ref.read(selectedDateProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getHabits(date: targetDate));
    ref.read(habitScoreProvider.notifier).refreshScore(date: targetDate);
  }

  Future<void> changeSelectedDate(DateTime newDate) async {
    // 1. Update selected date
    ref.read(selectedDateProvider.notifier).selectDate(newDate);

    // 2. Immediate 0ms local state update for all habits
    final currentHabits = state.value;
    if (currentHabits != null) {
      final instantUpdated = currentHabits.map((h) {
        return h.copyWith(
          completed: h.isCompletedOn(newDate),
          selectedDate: newDate,
        );
      }).toList();
      state = AsyncValue.data(instantUpdated);

      // Immediately calculate optimistic score for newDate
      final total = instantUpdated.length;
      final completed = instantUpdated.where((h) => h.isCompletedOn(newDate)).length;
      final score = total > 0 ? ((completed / total) * 1000).round() / 10.0 : 0.0;
      ref.read(habitScoreProvider.notifier).setOptimisticScore(
        HabitScore(date: formatDateKey(newDate), score: score, completed: completed, total: total),
      );
    }

    // 3. Immediately refresh Habit Score from backend for newDate
    ref.read(habitScoreProvider.notifier).refreshScore(date: newDate);

    // 4. Silently synchronize with backend without full-screen loader
    try {
      final serverHabits = await _repository.getHabits(date: newDate);
      state = AsyncValue.data(serverHabits);
    } catch (_) {
      // Keep optimistic state if network fails
    }
  }

  Future<void> addHabit(
    String name, {
    String icon = 'bolt',
    String? description,
    String? color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final newHabit = await _repository.createHabit(
      trimmed,
      icon: icon,
      description: description,
      color: color,
    );
    final currentHabits = state.value ?? [];
    state = AsyncValue.data([newHabit, ...currentHabits]);
    ref.read(habitScoreProvider.notifier).refreshScore(date: ref.read(selectedDateProvider));
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

    final currentHabits = state.value ?? [];
    state = AsyncValue.data(
      currentHabits.map((h) {
        if (h.id == habitId) {
          return h.copyWith(
            name: updated.name,
            icon: updated.icon,
            color: updated.color,
            description: updated.description,
          );
        }
        return h;
      }).toList(),
    );
    ref.read(habitScoreProvider.notifier).refreshScore(date: ref.read(selectedDateProvider));
  }

  Future<void> deleteHabit(String habitId) async {
    await _repository.deleteHabit(habitId);
    ref.read(selectedHabitIdsProvider.notifier).clear();
    final currentHabits = state.value ?? [];
    state = AsyncValue.data(currentHabits.where((h) => h.id != habitId).toList());
    ref.read(habitScoreProvider.notifier).refreshScore(date: ref.read(selectedDateProvider));
  }

  Future<void> toggleCompletion(Habit habit, {DateTime? date}) async {
    final DateTime selectedDate = date ?? ref.read(selectedDateProvider);
    final String selectedDateStr = formatDateKey(selectedDate);
    final DateTime today = DateTime.now();

    final previousList = state.value ?? [];
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

    final updatedHabits = previousList.map((h) {
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

    state = AsyncValue.data(updatedHabits);

    // Optimistically update score for selectedDate
    final currentScore = ref.read(habitScoreProvider).value;
    if (currentScore != null && currentScore.total > 0) {
      final newCompleted = (currentScore.completed + (willComplete ? 1 : -1)).clamp(0, currentScore.total);
      final raw = (newCompleted / currentScore.total) * 100.0;
      final newScore = (raw * 10).round() / 10.0;
      ref.read(habitScoreProvider.notifier).setOptimisticScore(
        HabitScore(
          date: currentScore.date,
          score: newScore,
          completed: newCompleted,
          total: currentScore.total,
        ),
      );
    }

    // 3. Send API request
    try {
      final serverResult = willComplete
          ? await _repository.markCompleted(habit.id, selectedDate)
          : await _repository.unmarkCompleted(habit.id, selectedDate);

      final reconciledList = (state.value ?? []).map((h) {
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

      state = AsyncValue.data(reconciledList);
      ref.read(habitScoreProvider.notifier).refreshScore(date: selectedDate);
    } catch (error) {
      // Rollback on failure
      state = AsyncValue.data(previousList);
      rethrow;
    }
  }

  Future<void> reorderHabits(List<String> orderedIds) async {
    final currentList = state.value;
    if (currentList == null) return;

    final habitMap = {for (final h in currentList) h.id: h};
    final reordered = <Habit>[];
    for (int i = 0; i < orderedIds.length; i++) {
      final h = habitMap[orderedIds[i]];
      if (h != null) {
        reordered.add(h.copyWith(sortOrder: i));
      }
    }
    // Add any not in list
    for (final h in currentList) {
      if (!orderedIds.contains(h.id)) {
        reordered.add(h);
      }
    }

    state = AsyncValue.data(reordered);

    try {
      await _repository.reorderHabits(orderedIds);
    } catch (_) {
      // Revert if needed or ignore
    }
  }

  void updateNoteState(String habitId, String dateStr, String? content) {
    final currentList = state.value;
    if (currentList == null) return;

    final updated = currentList.map((h) {
      if (h.id == habitId) {
        final currentSelectedStr = h.selectedDate != null
            ? formatDateKey(h.selectedDate!)
            : formatDateKey(DateTime.now());

        if (currentSelectedStr == dateStr) {
          final hasNote = content != null && content.trim().isNotEmpty;
          return h.copyWith(
            hasNote: hasNote,
            noteContent: hasNote ? content.trim() : null,
          );
        }
      }
      return h;
    }).toList();

    state = AsyncValue.data(updated);
  }
}
