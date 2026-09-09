import 'habit.dart';
import 'habit_score.dart';

abstract class HabitRepository {
  Future<List<Habit>> getHabits({DateTime? date});

  Future<HabitScore> getHabitScore(DateTime date);

  Future<Habit> createHabit(
    String name, {
    String icon = 'bolt',
    String? description,
    String? color,
    DateTime? createdAt,
  });

  Future<Habit> updateHabit(
    String habitId, {
    required String name,
    required String icon,
    String? color,
    String? description,
  });

  Future<void> deleteHabit(String habitId);

  Future<Habit> markCompleted(String habitId, DateTime date);

  Future<Habit> unmarkCompleted(String habitId, DateTime date);

  Future<void> reorderHabits(List<String> habitIds);
}
