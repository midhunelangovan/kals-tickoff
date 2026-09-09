import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/habit.dart';
import '../domain/habit_repository.dart';
import '../domain/habit_score.dart';
import 'habit_api_service.dart';

final apiHabitRepositoryProvider = Provider<HabitRepository>((ref) {
  final apiService = ref.watch(habitApiServiceProvider);
  return ApiHabitRepository(apiService);
});

class ApiHabitRepository implements HabitRepository {
  final HabitApiService _apiService;

  ApiHabitRepository(this._apiService);

  @override
  Future<List<Habit>> getHabits({DateTime? date}) async {
    final dtos = await _apiService.getHabits(date: date);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<HabitScore> getHabitScore(DateTime date) async {
    final dto = await _apiService.getHabitScore(date);
    return dto.toDomain();
  }

  @override
  Future<Habit> createHabit(
    String name, {
    String icon = 'bolt',
    String? description,
    String? color,
    DateTime? createdAt,
  }) async {
    final dto = await _apiService.createHabit(
      name,
      icon: icon,
      description: description,
      color: color,
      createdAt: createdAt,
    );
    return dto.toDomain();
  }

  @override
  Future<Habit> updateHabit(
    String habitId, {
    required String name,
    required String icon,
    String? color,
    String? description,
  }) async {
    final dto = await _apiService.updateHabit(
      habitId,
      name: name,
      icon: icon,
      color: color,
      description: description,
    );
    return dto.toDomain();
  }

  @override
  Future<void> deleteHabit(String habitId) async {
    await _apiService.deleteHabit(habitId);
  }

  @override
  Future<Habit> markCompleted(String habitId, DateTime date) async {
    final completion = await _apiService.markCompleted(habitId, date);
    return Habit(
      id: completion.habitId,
      name: '',
      createdAt: DateTime.now(),
      completed: completion.completed,
      currentStreak: completion.currentStreak,
      selectedDate: date,
      completedDates: completion.completions.toSet(),
    );
  }

  @override
  Future<Habit> unmarkCompleted(String habitId, DateTime date) async {
    final completion = await _apiService.unmarkCompleted(habitId, date);
    return Habit(
      id: completion.habitId,
      name: '',
      createdAt: DateTime.now(),
      completed: completion.completed,
      currentStreak: completion.currentStreak,
      selectedDate: date,
      completedDates: completion.completions.toSet(),
    );
  }

  @override
  Future<void> reorderHabits(List<String> habitIds) async {
    await _apiService.reorderHabits(habitIds);
  }
}
