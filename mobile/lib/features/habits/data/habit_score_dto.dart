import '../domain/habit_score.dart';

class HabitScoreDto {
  final String? date;
  final double score;
  final int completed;
  final int total;
  final int expected;

  HabitScoreDto({
    this.date,
    required this.score,
    required this.completed,
    int? total,
    int? expected,
  })  : total = total ?? expected ?? 0,
        expected = expected ?? total ?? 0;

  factory HabitScoreDto.fromJson(Map<String, dynamic> json) {
    final count = (json['total'] ?? json['expected']) as num?;
    return HabitScoreDto(
      date: json['date'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      total: count?.toInt() ?? 0,
      expected: count?.toInt() ?? 0,
    );
  }

  HabitScore toDomain() {
    return HabitScore(
      date: date,
      score: score,
      completed: completed,
      total: total,
      expected: expected,
    );
  }
}
