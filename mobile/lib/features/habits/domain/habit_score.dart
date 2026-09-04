class HabitScore {
  final String? date;
  final double score;
  final int completed;
  final int total;
  final int expected;

  const HabitScore({
    this.date,
    required this.score,
    required this.completed,
    int total = 0,
    int expected = 0,
  })  : total = total != 0 ? total : expected,
        expected = expected != 0 ? expected : total;

  static const HabitScore empty = HabitScore(
    score: 0.0,
    completed: 0,
    total: 0,
    expected: 0,
  );
}
