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
    when(() => mockRepository.getHabitScore(any()))
        .thenAnswer((_) async => const HabitScore(score: 0.0, completed: 0, expected: 0));
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

  test('HabitController calculates streak relative to TODAY regardless of selectedDate', () async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final twoDaysAgo = today.subtract(const Duration(days: 2));

    final initialHabits = [
      Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: DateTime.now(),
        completed: true,
        currentStreak: 3,
        selectedDate: yesterday,
        completedDates: {
          formatDateKey(today),
          formatDateKey(yesterday),
          formatDateKey(twoDaysAgo),
        },
      ),
    ];

    when(() => mockRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => initialHabits);

    final container = createContainer();
    final habits = await container.read(habitControllerProvider.future);

    expect(habits.first.currentStreak, 3);
  });

  test('HabitController deleteHabit removes habit from state list', () async {
    final habit = Habit(
      id: 'h1',
      name: 'Running',
      createdAt: DateTime.now(),
      completed: false,
      currentStreak: 0,
    );

    when(() => mockRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => [habit]);
    when(() => mockRepository.deleteHabit('h1')).thenAnswer((_) async {});

    final container = createContainer();
    await container.read(habitControllerProvider.future);

    final controller = container.read(habitControllerProvider.notifier);
    await controller.deleteHabit('h1');

    final state = container.read(habitControllerProvider).value!;
    expect(state, isEmpty);
  });

  test('HabitController optimistic update on historical date calculates streak relative to today', () async {
    final today = DateTime.now();
    final todayStr = formatDateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = formatDateKey(yesterday);

    final initialHabit = Habit(
      id: 'h1',
      name: 'Journaling',
      createdAt: DateTime.now(),
      completed: false,
      currentStreak: 1,
      selectedDate: yesterday,
      completedDates: {todayStr},
    );

    when(() => mockRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => [initialHabit]);

    when(() => mockRepository.markCompleted(any(), any())).thenAnswer(
      (_) async => Habit(
        id: 'h1',
        name: '',
        createdAt: DateTime.now(),
        completed: true,
        currentStreak: 2,
        selectedDate: yesterday,
        completedDates: {todayStr, yesterdayStr},
      ),
    );

    final container = createContainer();
    container.read(selectedDateProvider.notifier).selectDate(yesterday);
    await container.read(habitControllerProvider.future);

    final controller = container.read(habitControllerProvider.notifier);
    await controller.toggleCompletion(initialHabit);

    final state = container.read(habitControllerProvider).value!;
    expect(state.first.completed, true);
    expect(state.first.currentStreak, 2);
  });
}
