import 'dart:developer' as developer;
import 'habit.dart';
import 'habit_score.dart';
import 'streak_calculator.dart';

class HabitScoreResult {
  final String habitId;
  final String habitName;
  final DateTime startDate;
  final DateTime endDate;
  final int completedDays;
  final int trackedDays;
  final double score;

  const HabitScoreResult({
    required this.habitId,
    required this.habitName,
    required this.startDate,
    required this.endDate,
    required this.completedDays,
    required this.trackedDays,
    required this.score,
  });

  String get scoreText {
    if (trackedDays == 0) return '0%';
    if (score % 1 == 0) {
      return '${score.toInt()}%';
    }
    return '${score.toStringAsFixed(1)}%';
  }
}

class HabitScoreCalculator {
  HabitScoreCalculator._();

  /// Formats double percentage into string (e.g. 100%, 71.4%, 0%)
  static String formatScorePercentage(double score) {
    if (score % 1 == 0) {
      return '${score.toInt()}%';
    }
    return '${score.toStringAsFixed(1)}%';
  }

  /// Calculates the score for a single habit over [startDate] to [endDate].
  ///
  /// Pure function:
  /// Tracked Days = (endDate - startDate).inDays + 1
  /// Completed Days = count of distinct dates in completedDates falling in [startDate, endDate]
  /// Score (%) = (Completed Days / Tracked Days) * 100
  static HabitScoreResult calculateHabitScore({
    required Habit habit,
    required DateTime startDate,
    required DateTime endDate,
    bool enableLogging = false,
  }) {
    final normStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (normEnd.isBefore(normStart)) {
      return HabitScoreResult(
        habitId: habit.id,
        habitName: habit.name,
        startDate: normStart,
        endDate: normEnd,
        completedDays: 0,
        trackedDays: 0,
        score: 0.0,
      );
    }

    final trackedDays = normEnd.difference(normStart).inDays + 1;
    final startKey = formatDateKey(normStart);
    final endKey = formatDateKey(normEnd);

    int completedDays = 0;
    for (final dateKey in habit.completedDates) {
      if (dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0) {
        completedDays++;
      }
    }

    final double rawScore = trackedDays > 0
        ? (completedDays.toDouble() / trackedDays.toDouble()) * 100.0
        : 0.0;
    final double score = (rawScore * 10).round() / 10.0;

    if (enableLogging) {
      developer.log(
        '\n[HabitScore] Calculation inputs for habit: ${habit.name}\n'
        '  Tracking Start: $startKey\n'
        '  End: $endKey\n'
        '  Tracked Days: $trackedDays\n'
        '  Completed Days: $completedDays\n'
        '  Score: ${formatScorePercentage(score)}',
        name: 'HabitScore',
      );
    }

    return HabitScoreResult(
      habitId: habit.id,
      habitName: habit.name,
      startDate: normStart,
      endDate: normEnd,
      completedDays: completedDays,
      trackedDays: trackedDays,
      score: score,
    );
  }

  /// Calculates the overall Habit Score across all active habits over [startDate] to [endDate].
  ///
  /// For single-date (Home screen): [startDate] == [endDate]
  ///   Day Count = 1
  ///   Total Tracked Habit-Days = activeHabits.length * 1
  ///   Total Completed Habit-Days = count of active habits completed on that date
  ///   Score (%) = (Completed / Total) * 100
  ///
  /// For multi-day period: [startDate] to [endDate]
  ///   Day Count = (endDate - startDate).inDays + 1
  ///   Total Tracked Habit-Days = activeHabits.length * dayCount
  ///   Total Completed Habit-Days = count of unique (habitId, date) completion keys
  ///   Score (%) = (Completed / Total) * 100
  static HabitScore calculateOverallScore({
    required List<Habit> habits,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? selectedDate,
    bool enableLogging = false,
  }) {
    final activeHabits = habits.where((h) => !h.archived).toList();
    final normStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normEnd = DateTime(endDate.year, endDate.month, endDate.day);

    if (activeHabits.isEmpty || normEnd.isBefore(normStart)) {
      return HabitScore(
        score: 0.0,
        completed: 0,
        total: 0,
        expected: 0,
        startDate: formatDateKey(normStart),
        endDate: formatDateKey(normEnd),
        dailyCompleted: 0,
        dailyTotal: 0,
        habitDaysCompleted: 0,
        habitDaysTotal: 0,
        habitsCount: 0,
      );
    }

    final dayCount = normEnd.difference(normStart).inDays + 1;
    final totalTrackedHabitDays = activeHabits.length * dayCount;
    final startKey = formatDateKey(normStart);
    final endKey = formatDateKey(normEnd);

    // Logical unique key: "${habit.id}_$dateKey" guarantees deduplication
    final completedSet = <String>{};
    for (final habit in activeHabits) {
      for (final dateKey in habit.completedDates) {
        if (dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0) {
          completedSet.add('${habit.id}_$dateKey');
        }
      }
    }
    final totalCompletedHabitDays = completedSet.length;

    final double rawScore = totalTrackedHabitDays > 0
        ? (totalCompletedHabitDays.toDouble() /
                totalTrackedHabitDays.toDouble()) *
            100.0
        : 0.0;
    final double overallScore = (rawScore * 10).round() / 10.0;

    final targetDate = selectedDate ?? normStart;
    final targetDateKey = formatDateKey(targetDate);
    final dailyCompleted =
        activeHabits.where((h) => h.isCompletedOn(targetDateKey)).length;

    if (enableLogging) {
      developer.log(
        '\n[HabitScore] Calculation:\n'
        '  Selected date: $targetDateKey\n'
        '  Active habits: ${activeHabits.length}\n'
        '  Period: $startKey to $endKey (days: $dayCount)\n'
        '  Total Habit-Days: $totalTrackedHabitDays\n'
        '  Completed Habit-Days: $totalCompletedHabitDays\n'
        '  Daily Completed: $dailyCompleted\n'
        '  Score: ${formatScorePercentage(overallScore)}',
        name: 'HabitScore',
      );
    }

    return HabitScore(
      score: overallScore,
      completed: totalCompletedHabitDays,
      total: totalTrackedHabitDays,
      expected: totalTrackedHabitDays,
      startDate: startKey,
      endDate: endKey,
      dailyCompleted: dailyCompleted,
      dailyTotal: activeHabits.length,
      habitDaysCompleted: totalCompletedHabitDays,
      habitDaysTotal: totalTrackedHabitDays,
      habitsCount: activeHabits.length,
    );
  }

  /// Convenience method for calculating the exact habit score for a single date.
  static HabitScore calculateForDate({
    required List<Habit> habits,
    required DateTime date,
    bool enableLogging = false,
  }) {
    return calculateOverallScore(
      habits: habits,
      startDate: date,
      endDate: date,
      selectedDate: date,
      enableLogging: enableLogging,
    );
  }

  /// Resolves the single deterministic tracking start date.
  ///
  /// Priority:
  /// 1. [persistedStartDate] if provided and valid.
  /// 2. Earliest completion date across all habits.
  /// 3. Earliest habit creation date.
  /// 4. [referenceToday] (or DateTime.now()).
  ///
  /// Always capped at [referenceToday].
  static DateTime getTrackingStartDate(
    List<Habit> habits, {
    DateTime? persistedStartDate,
    DateTime? referenceToday,
  }) {
    final now = referenceToday ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (persistedStartDate != null) {
      final pDate = DateTime(
        persistedStartDate.year,
        persistedStartDate.month,
        persistedStartDate.day,
      );
      return pDate.isAfter(today) ? today : pDate;
    }

    DateTime? earliest;

    for (final habit in habits) {
      for (final dateStr in habit.completedDates) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          final dt = DateTime(parsed.year, parsed.month, parsed.day);
          if (earliest == null || dt.isBefore(earliest)) {
            earliest = dt;
          }
        }
      }

      final created = habit.createdAtDate;
      if (earliest == null || created.isBefore(earliest)) {
        earliest = created;
      }
    }

    if (earliest == null || earliest.isAfter(today)) {
      return today;
    }

    return earliest;
  }
}
