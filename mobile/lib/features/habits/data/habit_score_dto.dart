import '../domain/habit_score.dart';

class HabitScoreDto {
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

  HabitScoreDto({
    this.date,
    this.startDate,
    this.endDate,
    required this.score,
    required this.completed,
    int? total,
    int? expected,
    this.dailyCompleted = 0,
    this.dailyTotal = 0,
    this.habitDaysCompleted = 0,
    this.habitDaysTotal = 0,
    this.habitsCount = 0,
  })  : total = total ?? expected ?? 0,
        expected = expected ?? total ?? 0;

  factory HabitScoreDto.fromJson(Map<String, dynamic> json) {
    final count = (json['total'] ?? json['habitDaysTotal'] ?? json['expected'] ?? json['dailyTotal']) as num?;
    final comp = (json['completed'] ?? json['habitDaysCompleted'] ?? json['dailyCompleted']) as num?;
    final dailyComp = (json['dailyCompleted']) as num?;
    final dailyTot = (json['dailyTotal']) as num?;
    final hdComp = (json['habitDaysCompleted'] ?? json['completed'] ?? 0) as num;
    final hdTot = (json['habitDaysTotal'] ?? json['total'] ?? 0) as num;
    final hCount = (json['habitsCount'] ?? json['uniqueHabits'] ?? 0) as num;

    return HabitScoreDto(
      date: json['date'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      completed: comp?.toInt() ?? 0,
      total: count?.toInt() ?? 0,
      expected: count?.toInt() ?? 0,
      dailyCompleted: dailyComp?.toInt() ?? 0,
      dailyTotal: dailyTot?.toInt() ?? 0,
      habitDaysCompleted: hdComp.toInt(),
      habitDaysTotal: hdTot.toInt(),
      habitsCount: hCount.toInt(),
    );
  }

  HabitScore toDomain() {
    return HabitScore(
      date: date,
      startDate: startDate,
      endDate: endDate,
      score: score,
      completed: completed,
      total: total,
      expected: expected,
      dailyCompleted: dailyCompleted,
      dailyTotal: dailyTotal,
      habitDaysCompleted: habitDaysCompleted,
      habitDaysTotal: habitDaysTotal,
      habitsCount: habitsCount,
    );
  }
}
