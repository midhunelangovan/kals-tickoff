class HabitScore {
  final String? date;
  final String? startDate;
  final String? endDate;
  final double score;
  final int completed;
  final int total;
  final int expected;
  final int dailyCompleted;
  final int dailyTotal;
  final int habitDaysCompleted;
  final int habitDaysTotal;
  final int habitsCount;

  const HabitScore({
    this.date,
    this.startDate,
    this.endDate,
    required this.score,
    required this.completed,
    int total = 0,
    int expected = 0,
    this.dailyCompleted = 0,
    this.dailyTotal = 0,
    this.habitDaysCompleted = 0,
    this.habitDaysTotal = 0,
    this.habitsCount = 0,
  })  : total = total != 0 ? total : expected,
        expected = expected != 0 ? expected : total;

  static const HabitScore empty = HabitScore(
    score: 0.0,
    completed: 0,
    total: 0,
    expected: 0,
    dailyCompleted: 0,
    dailyTotal: 0,
    habitDaysCompleted: 0,
    habitDaysTotal: 0,
    habitsCount: 0,
  );

  bool get hasApplicableDays => (habitDaysTotal > 0) || (total > 0);

  int get completedHabitDays =>
      habitDaysCompleted != 0 ? habitDaysCompleted : completed;

  int get totalHabitDays => habitDaysTotal != 0 ? habitDaysTotal : total;

  int get uniqueHabits => habitsCount;

  String get habitDaysText => '$completedHabitDays / $totalHabitDays habit-days';

  String get scoreText {
    if (totalHabitDays == 0) {
      return '0%';
    }
    if (score % 1 == 0) {
      return '${score.toInt()}%';
    }
    return '${score.toStringAsFixed(1)}%';
  }
}
