import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/app/app.dart';
import 'package:habit_tracker_mobile/features/habits/data/api_habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_score.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late MockHabitRepository mockHabitRepository;

  setUp(() {
    mockHabitRepository = MockHabitRepository();
    when(() => mockHabitRepository.getHabitScore(any()))
        .thenAnswer((_) async => const HabitScore(score: 0.0, completed: 0, expected: 0));
  });

  testWidgets('Renders empty state and date selector strip', (tester) async {
    when(() => mockHabitRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiHabitRepositoryProvider.overrideWithValue(mockHabitRepository),
        ],
        child: const HabitTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('No habits yet'), findsOneWidget);
    expect(find.text('Add your first habit'), findsOneWidget);
  });

  testWidgets('Enters selection mode on long press, shows delete action, and deletes on confirmation', (tester) async {
    final habit = Habit(
      id: '1',
      name: 'Read for 20 minutes',
      icon: 'menu_book',
      color: '#7C3AED',
      createdAt: DateTime.now(),
      completed: true,
      currentStreak: 5,
      selectedDate: DateTime.now(),
      completedDates: {formatDateKey(DateTime.now())},
    );

    when(() => mockHabitRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => [habit]);
    when(() => mockHabitRepository.deleteHabit('1')).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiHabitRepositoryProvider.overrideWithValue(mockHabitRepository),
        ],
        child: const HabitTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify habit card is rendered with icon and streak
    expect(find.text('Read for 20 minutes'), findsOneWidget);
    expect(find.text('Streak: 5 days'), findsOneWidget);

    // Normal browsing does NOT show delete icon
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // Long press on habit card to enter selection mode
    await tester.longPress(find.text('Read for 20 minutes'));
    await tester.pumpAndSettle();

    // Verify selection mode action bar is active
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

    // Tap delete action button in top bar
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Check dialog appeared
    expect(find.text('Delete habit?'), findsOneWidget);
    expect(find.text("Delete 'Read for 20 minutes' and all of its completion history?"), findsOneWidget);

    // Tap Delete button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockHabitRepository.deleteHabit('1')).called(1);
  });

  testWidgets('ProgressSummary displays "64 / 128 habit-days" and "50%", never "habits"', (tester) async {
    const score = HabitScore(
      score: 50.0,
      completed: 64,
      total: 128,
      habitDaysCompleted: 64,
      habitDaysTotal: 128,
      habitsCount: 2,
    );

    when(() => mockHabitRepository.getHabitScore(any()))
        .thenAnswer((_) async => score);
    when(() => mockHabitRepository.getHabits(date: any(named: 'date')))
        .thenAnswer((_) async => [
              Habit(
                id: '1',
                name: 'Walking',
                createdAt: DateTime.now(),
              ),
            ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiHabitRepositoryProvider.overrideWithValue(mockHabitRepository),
        ],
        child: const HabitTrackerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Habit Score card
    expect(find.text('HABIT SCORE'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('64 / 128 habit-days'), findsOneWidget);

    // MUST NEVER display "64 / 128 habits"
    expect(find.text('64 / 128 habits'), findsNothing);
  });
}
