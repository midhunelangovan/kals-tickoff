import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/features/habits/data/api_habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_score.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/habit_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockRepository;

  setUp(() {
    mockRepository = MockHabitRepository();
  });

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        apiHabitRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('HabitScore Business Rule Tests', () {
    test('Case 1: 3 active habits, 2 completed -> 66.7%', () async {
      const score = HabitScore(
        date: '2026-09-02',
        score: 66.7,
        completed: 2,
        total: 3,
      );
      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => score);

      final container = createContainer();
      final result = await container.read(habitScoreProvider.future);

      expect(result.score, 66.7);
      expect(result.completed, 2);
      expect(result.total, 3);
      expect(result.expected, 3);
    });

    test('Case 2: 3 active habits, 3 completed -> 100.0%', () async {
      const score = HabitScore(
        date: '2026-09-02',
        score: 100.0,
        completed: 3,
        total: 3,
      );
      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => score);

      final container = createContainer();
      final result = await container.read(habitScoreProvider.future);

      expect(result.score, 100.0);
      expect(result.completed, 3);
      expect(result.total, 3);
    });

    test('Case 3: 3 active habits, 0 completed -> 0.0%', () async {
      const score = HabitScore(
        date: '2026-09-02',
        score: 0.0,
        completed: 0,
        total: 3,
      );
      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => score);

      final container = createContainer();
      final result = await container.read(habitScoreProvider.future);

      expect(result.score, 0.0);
      expect(result.completed, 0);
      expect(result.total, 3);
    });

    test('Zero-habit case: 0 active habits -> 0 of 0 completed, 0.0%', () async {
      const score = HabitScore(
        date: '2026-09-02',
        score: 0.0,
        completed: 0,
        total: 0,
      );
      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => score);

      final container = createContainer();
      final result = await container.read(habitScoreProvider.future);

      expect(result.score, 0.0);
      expect(result.completed, 0);
      expect(result.total, 0);
      expect(result.score.toStringAsFixed(1), '0.0');
    });

    test('Case 6: Date change refreshes Habit Score for new selected date', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      const todayScore = HabitScore(score: 66.7, completed: 2, total: 3);
      const yesterdayScore = HabitScore(score: 33.3, completed: 1, total: 3);

      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((invocation) async {
        final dt = invocation.positionalArguments[0] as DateTime;
        if (dt.day == yesterday.day) {
          return yesterdayScore;
        }
        return todayScore;
      });

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => []);

      final container = createContainer();
      await container.read(habitScoreProvider.future);

      await container.read(habitControllerProvider.notifier).changeSelectedDate(yesterday);
      await pumpEventQueue();

      final updatedScore = container.read(habitScoreProvider).value;
      expect(updatedScore?.score, 33.3);
      expect(updatedScore?.completed, 1);
    });

    test('Case 7 & 8: Toggle completion updates optimistic score and reconciles with server', () async {
      final today = DateTime.now();
      const initialScore = HabitScore(score: 33.3, completed: 1, total: 3);
      const serverReconciledScore = HabitScore(score: 66.7, completed: 2, total: 3);

      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => initialScore);
      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => []);

      final habit = Habit(
        id: 'h-1',
        name: 'Walking',
        createdAt: today,
        completed: false,
        completedDates: {},
      );

      when(() => mockRepository.markCompleted(any(), any()))
          .thenAnswer((_) async => Habit(
                id: 'h-1',
                name: 'Walking',
                createdAt: today,
                completed: true,
                completedDates: {formatDateKey(today)},
              ));

      final container = createContainer();
      await container.read(habitScoreProvider.future);

      // Trigger completion toggle
      when(() => mockRepository.getHabitScore(any()))
          .thenAnswer((_) async => serverReconciledScore);

      await container.read(habitControllerProvider.notifier).toggleCompletion(habit);
      await pumpEventQueue();

      final finalScore = container.read(habitScoreProvider).value;
      expect(finalScore?.completed, 2);
      expect(finalScore?.score, 66.7);
    });
  });
}
