import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/features/habits/data/api_habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/data/habit_api_service.dart';
import 'package:habit_tracker_mobile/features/habits/data/habit_dto.dart';
import 'package:habit_tracker_mobile/features/habits/data/habit_score_dto.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitApiService extends Mock implements HabitApiService {}

void main() {
  late MockHabitApiService mockApiService;
  late ApiHabitRepository repository;

  setUp(() {
    mockApiService = MockHabitApiService();
    repository = ApiHabitRepository(mockApiService);
  });

  group('ApiHabitRepository Tests', () {
    test('getHabits delegates to service and converts to domain', () async {
      final dtos = [
        HabitDto(
          id: '1',
          name: 'Meditation',
          createdAt: DateTime.now(),
          archived: false,
          completed: true,
          currentStreak: 4,
          completions: ['2026-09-01'],
        ),
      ];

      when(() => mockApiService.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => dtos);

      final result = await repository.getHabits();
      expect(result.length, 1);
      expect(result.first.name, 'Meditation');
      expect(result.first.completed, true);
      expect(result.first.currentStreak, 4);
    });

    test('getHabitScore delegates to service and returns domain score', () async {
      final scoreDto = HabitScoreDto(
        score: 75.0,
        completed: 15,
        expected: 20,
      );

      when(() => mockApiService.getHabitScore(any()))
          .thenAnswer((_) async => scoreDto);

      final result = await repository.getHabitScore(DateTime.now());
      expect(result.score, 75.0);
      expect(result.completed, 15);
      expect(result.expected, 20);
    });

    test('createHabit delegates to service and maps response', () async {
      final dto = HabitDto(
        id: '2',
        name: 'Gym',
        icon: 'fitness_center',
        color: '#10B981',
        createdAt: DateTime.now(),
        archived: false,
        completed: false,
        currentStreak: 0,
        completions: [],
      );

      when(() => mockApiService.createHabit(
            'Gym',
            icon: any(named: 'icon'),
            color: any(named: 'color'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => dto);

      final result = await repository.createHabit('Gym', icon: 'fitness_center', color: '#10B981');
      expect(result.id, '2');
      expect(result.name, 'Gym');
      expect(result.icon, 'fitness_center');
      expect(result.color, '#10B981');
    });

    test('updateHabit delegates to service and maps response', () async {
      final dto = HabitDto(
        id: '2',
        name: 'Gym Workout',
        icon: 'fitness_center',
        color: '#10B981',
        createdAt: DateTime.now(),
        archived: false,
        completed: false,
        currentStreak: 0,
        completions: [],
      );

      when(() => mockApiService.updateHabit(
            '2',
            name: 'Gym Workout',
            icon: 'fitness_center',
            color: any(named: 'color'),
            description: any(named: 'description'),
          )).thenAnswer((_) async => dto);

      final result = await repository.updateHabit(
        '2',
        name: 'Gym Workout',
        icon: 'fitness_center',
        color: '#10B981',
      );
      expect(result.name, 'Gym Workout');
    });

    test('deleteHabit delegates to service', () async {
      when(() => mockApiService.deleteHabit('2')).thenAnswer((_) async {});

      await repository.deleteHabit('2');
      verify(() => mockApiService.deleteHabit('2')).called(1);
    });

    test('markCompleted calls service and returns updated completion and history', () async {
      final completionDto = CompletionResponseDto(
        habitId: '1',
        completionDate: '2026-09-01',
        completed: true,
        currentStreak: 5,
        completions: ['2026-09-01'],
      );

      when(() => mockApiService.markCompleted(any(), any()))
          .thenAnswer((_) async => completionDto);

      final result = await repository.markCompleted('1', DateTime.now());
      expect(result.id, '1');
      expect(result.completed, true);
      expect(result.currentStreak, 5);
      expect(result.completions, contains('2026-09-01'));
    });
  });
}
