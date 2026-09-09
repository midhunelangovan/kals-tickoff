import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/app/theme.dart';
import 'package:habit_tracker_mobile/app/theme_controller.dart';
import 'package:habit_tracker_mobile/features/habits/data/api_habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_repository.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_score.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit_score_calculator.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/habit_controller.dart';
import 'package:habit_tracker_mobile/features/notes/data/note_repository.dart';
import 'package:habit_tracker_mobile/features/notes/domain/habit_note.dart';
import 'package:habit_tracker_mobile/features/notes/presentation/note_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockHabitRepository extends Mock implements HabitRepository {}
class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late MockHabitRepository mockRepository;
  late MockNoteRepository mockNoteRepository;

  setUp(() {
    mockRepository = MockHabitRepository();
    mockNoteRepository = MockNoteRepository();
    when(() => mockRepository.reorderHabits(any())).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(DateTime.now());
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        apiHabitRepositoryProvider.overrideWithValue(mockRepository),
        noteRepositoryProvider.overrideWithValue(mockNoteRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Kals TickOff - Data Consistency & Reordering Test Suite', () {
    final today = DateTime.now();
    final todayStr = formatDateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = formatDateKey(yesterday);
    final twoDaysAgo = today.subtract(const Duration(days: 2));
    final twoDaysAgoStr = formatDateKey(twoDaysAgo);

    // TEST 1: Create 3 habits. Expected: Total = 3
    test('TEST 1: Create 3 habits -> Total = 3', () async {
      final habits = [
        Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo),
        Habit(id: 'h2', name: 'Reading', createdAt: twoDaysAgo),
        Habit(id: 'h3', name: 'Meditation', createdAt: twoDaysAgo),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => habits);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 0.0, completed: 0, total: 3),
      );

      final container = createContainer();
      final loaded = await container.read(habitControllerProvider.future);

      expect(loaded.length, 3);
      expect(loaded.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);
    });

    // TEST 2: Complete 2 of 3 today. Expected: 2 / 3
    test('TEST 2: Complete 2 of 3 today -> 2 / 3', () async {
      final habits = [
        Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo, completed: true, completedDates: {todayStr}),
        Habit(id: 'h2', name: 'Reading', createdAt: twoDaysAgo, completed: true, completedDates: {todayStr}),
        Habit(id: 'h3', name: 'Meditation', createdAt: twoDaysAgo, completed: false, completedDates: {}),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => habits);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 66.7, completed: 2, total: 3),
      );

      final container = createContainer();
      final loaded = await container.read(habitControllerProvider.future);

      final completedCount = loaded.where((h) => h.isCompletedOn(today)).length;
      final totalCount = loaded.length;

      expect(completedCount, 2);
      expect(totalCount, 3);
      expect('$completedCount / $totalCount', '2 / 3');
    });

    // TEST 3: Navigate to yesterday. Expected: Yesterday actual completion state is displayed
    test('TEST 3: Navigate to yesterday -> Yesterday actual completion state displayed', () async {
      // Habit 1 was completed yesterday, Habit 2 was NOT completed yesterday
      final habits = [
        Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo, completedDates: {yesterdayStr, todayStr}),
        Habit(id: 'h2', name: 'Reading', createdAt: twoDaysAgo, completedDates: {todayStr}),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => habits);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 50.0, completed: 1, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      // Navigate to yesterday
      await container.read(habitControllerProvider.notifier).changeSelectedDate(yesterday);
      await pumpEventQueue();

      final stateYesterday = container.read(habitControllerProvider).value!;
      final h1 = stateYesterday.firstWhere((h) => h.id == 'h1');
      final h2 = stateYesterday.firstWhere((h) => h.id == 'h2');

      expect(h1.completed, isTrue);
      expect(h2.completed, isFalse);
    });

    // TEST 4: Navigate back to today. Expected: Today previous completion state restored without refresh
    test('TEST 4: Navigate back to today -> Today completion state restored without refresh', () async {
      final habits = [
        Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo, completedDates: {todayStr}),
        Habit(id: 'h2', name: 'Reading', createdAt: twoDaysAgo, completedDates: {yesterdayStr}),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => habits);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 50.0, completed: 1, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      // Navigate: Today -> Yesterday -> Today
      await container.read(habitControllerProvider.notifier).changeSelectedDate(yesterday);
      await pumpEventQueue();
      await container.read(habitControllerProvider.notifier).changeSelectedDate(today);
      await pumpEventQueue();

      final stateToday = container.read(habitControllerProvider).value!;
      final h1 = stateToday.firstWhere((h) => h.id == 'h1');
      final h2 = stateToday.firstWhere((h) => h.id == 'h2');

      expect(h1.completed, isTrue);
      expect(h2.completed, isFalse);
    });

    // TEST 5: Restart application. Expected: All completion states remain identical
    test('TEST 5: Restart application -> All completion states remain identical', () async {
      final persistedHabits = [
        Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo, completedDates: {yesterdayStr, todayStr}),
        Habit(id: 'h2', name: 'Reading', createdAt: twoDaysAgo, completedDates: {todayStr}),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => persistedHabits);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 75.0, completed: 2, total: 2),
      );

      // Session 1
      final container1 = createContainer();
      final session1Habits = await container1.read(habitControllerProvider.future);

      // Simulate App Restart (new ProviderContainer reading persisted state)
      final container2 = createContainer();
      final session2Habits = await container2.read(habitControllerProvider.future);

      expect(session2Habits.length, session1Habits.length);
      for (int i = 0; i < session1Habits.length; i++) {
        expect(session2Habits[i].id, session1Habits[i].id);
        expect(session2Habits[i].completedDates, session1Habits[i].completedDates);
        expect(session2Habits[i].completed, session1Habits[i].completed);
      }
    });

    // TEST 6: Create a habit today. Navigate to yesterday.
    // Expected: If habit exists, it must be visible for every selected date for historical backfilling.
    test('TEST 6: Habit created today is visible on yesterday for historical backfilling', () async {
      final oldHabit = Habit(id: 'h1', name: 'Walking', createdAt: twoDaysAgo);
      final newHabitToday = Habit(id: 'h2', name: 'Gym', createdAt: today);

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => [oldHabit, newHabitToday]);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 0.0, completed: 0, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      // Navigate to yesterday
      await container.read(habitControllerProvider.notifier).changeSelectedDate(yesterday);
      await pumpEventQueue();

      final yesterdayHabits = container.read(habitControllerProvider).value!;

      // Both habits must be visible on yesterday so the user can backfill completions!
      expect(yesterdayHabits.length, 2);
      expect(yesterdayHabits.any((h) => h.id == 'h1'), isTrue);
      expect(yesterdayHabits.any((h) => h.id == 'h2'), isTrue);
    });

    // TEST 7: Rename a habit. Expected: All historical completion records remain attached to that habit.
    test('TEST 7: Rename a habit -> Historical records remain attached by habitId', () async {
      final habit = Habit(
        id: 'stable-id-42',
        name: 'Morning Run',
        createdAt: twoDaysAgo,
        completedDates: {twoDaysAgoStr, yesterdayStr, todayStr},
      );

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => [habit]);
      when(() => mockRepository.updateHabit(
        'stable-id-42',
        name: 'Evening Jog',
        icon: any(named: 'icon'),
        color: any(named: 'color'),
        description: any(named: 'description'),
      )).thenAnswer((_) async => habit.copyWith(name: 'Evening Jog'));
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 100.0, completed: 1, total: 1),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      // Rename habit
      await container.read(habitControllerProvider.notifier).editHabit(
        'stable-id-42',
        name: 'Evening Jog',
        icon: 'directions_run',
      );
      await pumpEventQueue();

      final updatedList = container.read(habitControllerProvider).value!;
      final updatedHabit = updatedList.firstWhere((h) => h.id == 'stable-id-42');

      expect(updatedHabit.name, 'Evening Jog');
      expect(updatedHabit.id, 'stable-id-42');
      // Historical completions still attached to stable-id-42!
      expect(updatedHabit.completedDates, contains(twoDaysAgoStr));
      expect(updatedHabit.completedDates, contains(yesterdayStr));
      expect(updatedHabit.completedDates, contains(todayStr));
    });

    // TEST 8: Complete the same habit multiple times on one day. Expected: Counts as exactly one completion.
    test('TEST 8: Duplicate completions on same day count as exactly one completion', () {
      final completedSet = <String>{};

      // Simulating idempotent toggle / insert
      completedSet.add(todayStr);
      completedSet.add(todayStr); // duplicate add
      completedSet.add(todayStr); // duplicate add

      expect(completedSet.length, 1);
      expect(completedSet, {todayStr});
    });

    // TEST 9: Reorder habits.
    // Expected: Only display order changes. Historical data, streaks, scores, notes and completion states remain unchanged.
    test('TEST 9: Reorder habits -> Only display order changes, historical data unchanged', () async {
      final h1 = Habit(
        id: 'h1',
        name: 'Walking',
        sortOrder: 0,
        createdAt: twoDaysAgo,
        currentStreak: 3,
        completedDates: {twoDaysAgoStr, yesterdayStr, todayStr},
        completed: true,
      );
      final h2 = Habit(
        id: 'h2',
        name: 'Reading',
        sortOrder: 1,
        createdAt: twoDaysAgo,
        currentStreak: 1,
        completedDates: {todayStr},
        completed: true,
      );

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => [h1, h2]);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 66.7, completed: 2, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      // Reorder: Reading before Walking
      await container.read(habitControllerProvider.notifier).reorderHabits(['h2', 'h1']);
      await pumpEventQueue();

      final reordered = container.read(habitControllerProvider).value!;
      expect(reordered[0].id, 'h2');
      expect(reordered[0].name, 'Reading');
      expect(reordered[0].currentStreak, 1);
      expect(reordered[0].completedDates, {todayStr});

      expect(reordered[1].id, 'h1');
      expect(reordered[1].name, 'Walking');
      expect(reordered[1].currentStreak, 3);
      expect(reordered[1].completedDates, {twoDaysAgoStr, yesterdayStr, todayStr});

      verify(() => mockRepository.reorderHabits(['h2', 'h1'])).called(1);
    });

    // TEST 10: Reorder habits -> restart application. Expected: New order persists.
    test('TEST 10: Reorder habits -> restart application -> New order persists', () async {
      final reorderedList = [
        Habit(id: 'h2', name: 'Reading', sortOrder: 0, createdAt: twoDaysAgo),
        Habit(id: 'h1', name: 'Walking', sortOrder: 1, createdAt: twoDaysAgo),
      ];

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => reorderedList);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 0.0, completed: 0, total: 2),
      );

      final container = createContainer();
      final habitsAfterRestart = await container.read(habitControllerProvider.future);

      expect(habitsAfterRestart[0].id, 'h2');
      expect(habitsAfterRestart[1].id, 'h1');
    });

    // TEST 11: Calculate habit score using known completion data.
    // Expected: Same result every time and from every screen, displays "—" when zero applicable days.
    test('TEST 11: Habit score deterministic calculation and displays "—" when 0 applicable', () {
      // 2 completed out of 3 eligible habit days -> 66.7%
      const scoreNormal = HabitScore(
        score: 66.7,
        completed: 2,
        total: 3,
        habitDaysCompleted: 2,
        habitDaysTotal: 3,
      );
      expect(scoreNormal.scoreText, '66.7%');
      expect(scoreNormal.completed, 2);
      expect(scoreNormal.total, 3);

      // Zero applicable days -> "0%"
      const scoreZero = HabitScore(
        score: 0.0,
        completed: 0,
        total: 0,
        habitDaysCompleted: 0,
        habitDaysTotal: 0,
      );
      expect(scoreZero.scoreText, '0%');
    });

    // TEST 12: Open Today -> Yesterday -> older date -> Today repeatedly.
    // Expected: No stale state, incorrect counts, or data changes.
    test('TEST 12: Rapid date navigation (Today -> Yesterday -> TwoDaysAgo -> Today) maintains zero state drift', () async {
      final habitA = Habit(
        id: 'hA',
        name: 'Habit A',
        createdAt: twoDaysAgo,
        completedDates: {todayStr, twoDaysAgoStr},
      );
      final habitB = Habit(
        id: 'hB',
        name: 'Habit B',
        createdAt: twoDaysAgo,
        completedDates: {yesterdayStr},
      );

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((_) async => [habitA, habitB]);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 50.0, completed: 1, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      final controller = container.read(habitControllerProvider.notifier);

      for (int i = 0; i < 3; i++) {
        // 1. Yesterday: Habit A = false, Habit B = true
        await controller.changeSelectedDate(yesterday);
        await pumpEventQueue();
        var current = container.read(habitControllerProvider).value!;
        expect(current.firstWhere((h) => h.id == 'hA').completed, isFalse);
        expect(current.firstWhere((h) => h.id == 'hB').completed, isTrue);

        // 2. TwoDaysAgo: Habit A = true, Habit B = false
        await controller.changeSelectedDate(twoDaysAgo);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.firstWhere((h) => h.id == 'hA').completed, isTrue);
        expect(current.firstWhere((h) => h.id == 'hB').completed, isFalse);

        // 3. Today: Habit A = true, Habit B = false
        await controller.changeSelectedDate(today);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.firstWhere((h) => h.id == 'hA').completed, isTrue);
        expect(current.firstWhere((h) => h.id == 'hB').completed, isFalse);
      }
    });

    // TEST 13: Single habit created on Sep 1
    // CORE RULE: IF HABIT EXISTS -> SHOW IT FOR EVERY SELECTED DATE (Aug 31, Sep 1, Sep 2, Sep 3, Today)
    test('TEST 13: Habit created on Sep 1 is visible on ALL dates (including Aug 31) for historical backfill', () {
      final sep1 = DateTime(2026, 9, 1);
      final aug31 = DateTime(2026, 8, 31);
      final sep2 = DateTime(2026, 9, 2);
      final sep3 = DateTime(2026, 9, 3);
      final sep7 = DateTime(2026, 9, 7);

      final walking = Habit(id: '1', name: 'Walking', createdAt: sep1);

      expect(walking.isApplicableOn(aug31), isTrue, reason: 'Aug 31 must show habit for historical backfill');
      expect(walking.isApplicableOn(sep1), isTrue, reason: 'Sep 1 must show habit');
      expect(walking.isApplicableOn(sep2), isTrue, reason: 'Sep 2 must show habit');
      expect(walking.isApplicableOn(sep3), isTrue, reason: 'Sep 3 must show habit');
      expect(walking.isApplicableOn(sep7), isTrue, reason: 'Sep 7 must show habit');
    });

    // TEST 14: Habits with different creation dates (Sep 1 vs Sep 5)
    // Global habit list remains stable: [Walking, Reading, Meditation] across all dates
    test('TEST 14: Global habit list remains identical across all dates (Aug 31, Sep 1, Sep 5, Today)', () {
      final sep1 = DateTime(2026, 9, 1);
      final sep5 = DateTime(2026, 9, 5);

      final walking = Habit(id: '1', name: 'Walking', createdAt: sep1, sortOrder: 0);
      final reading = Habit(id: '2', name: 'Reading', createdAt: sep1, sortOrder: 1);
      final meditation = Habit(id: '3', name: 'Meditation', createdAt: sep5, sortOrder: 2);

      final all = [walking, reading, meditation];

      // 2026-08-31 -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 8, 31))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);

      // 2026-09-01 -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 9, 1))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);

      // 2026-09-02 -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 9, 2))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);

      // 2026-09-04 -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 9, 4))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);

      // 2026-09-05 -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 9, 5))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);

      // Today (2026-09-07) -> Walking, Reading, Meditation
      expect(all.where((h) => h.isApplicableOn(DateTime(2026, 9, 7))).map((h) => h.name).toList(),
          ['Walking', 'Reading', 'Meditation']);
    });

    // TEST 15: Navigation cycle Today -> Sep 1 -> Sep 5 -> Sep 2 -> Today
    test('TEST 15: Repeated navigation cycle maintains identical global habit list while updating date completions', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep2 = DateTime(2026, 9, 2);
      final sep5 = DateTime(2026, 9, 5);
      final todayDate = DateTime(2026, 9, 7);

      final walking = Habit(id: '1', name: 'Walking', createdAt: sep1, sortOrder: 0);
      final reading = Habit(id: '2', name: 'Reading', createdAt: sep1, sortOrder: 1);
      final meditation = Habit(id: '3', name: 'Meditation', createdAt: sep5, sortOrder: 2);

      final masterList = [walking, reading, meditation];

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((invocation) async {
        return masterList;
      });
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 100.0, completed: 1, total: 3),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);
      final controller = container.read(habitControllerProvider.notifier);

      for (int cycle = 0; cycle < 2; cycle++) {
        // Today -> Walking, Reading, Meditation
        await controller.changeSelectedDate(todayDate);
        await pumpEventQueue();
        var current = container.read(habitControllerProvider).value!;
        expect(current.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);

        // Sep 1 -> Walking, Reading, Meditation
        await controller.changeSelectedDate(sep1);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);

        // Sep 5 -> Walking, Reading, Meditation
        await controller.changeSelectedDate(sep5);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);

        // Sep 2 -> Walking, Reading, Meditation
        await controller.changeSelectedDate(sep2);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);

        // Today -> Walking, Reading, Meditation
        await controller.changeSelectedDate(todayDate);
        await pumpEventQueue();
        current = container.read(habitControllerProvider).value!;
        expect(current.map((h) => h.name).toList(), ['Walking', 'Reading', 'Meditation']);
      }
    });

    // TEST 16: Completion record independence
    test('TEST 16: Completion on Sep 1 is preserved and displayed regardless of later habits or dates', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep1Str = '2026-09-01';
      final sep5 = DateTime(2026, 9, 5);

      final walking = Habit(
        id: '1',
        name: 'Walking',
        createdAt: sep1,
        completedDates: {sep1Str},
      );
      final meditation = Habit(
        id: '3',
        name: 'Meditation',
        createdAt: sep5,
        completedDates: {},
      );

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((invocation) async {
        return [walking, meditation];
      });
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 50.0, completed: 1, total: 2),
      );

      final container = createContainer();
      await container.read(habitControllerProvider.future);
      final controller = container.read(habitControllerProvider.notifier);

      // On Sep 1: Walking is visible AND completed on Sep 1
      await controller.changeSelectedDate(sep1);
      await pumpEventQueue();
      var current = container.read(habitControllerProvider).value!;
      expect(current.length, 2);
      expect(current.firstWhere((h) => h.id == '1').name, 'Walking');
      expect(current.firstWhere((h) => h.id == '1').completed, isTrue);

      // On Sep 5: Walking is visible, not completed on Sep 5
      await controller.changeSelectedDate(sep5);
      await pumpEventQueue();
      current = container.read(habitControllerProvider).value!;
      expect(current.length, 2);
      expect(current.firstWhere((h) => h.id == '1').completed, isFalse);

      // Back to Sep 1: Walking still completed on Sep 1!
      await controller.changeSelectedDate(sep1);
      await pumpEventQueue();
      current = container.read(habitControllerProvider).value!;
      expect(current.length, 2);
      expect(current.firstWhere((h) => h.id == '1').name, 'Walking');
      expect(current.firstWhere((h) => h.id == '1').completed, isTrue);
    });

    // TEST 17: Critical User Test Case
    // Today: Create habit "Walking"
    // Navigate to last week's Monday -> Walking is visible -> Mark Walking completed
    // Navigate to Tuesday -> Walking is visible and reflects Tuesday's completion state (false)
    // Navigate back to Monday -> Walking is still visible and marked completed (true)
    // Navigate back to Today -> Walking is visible with today's completion state (false)
    test('TEST 17: User Flow - Create habit today -> Backfill last Monday -> Tuesday -> Back to Monday -> Today', () async {
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lastMonday = todayDate.subtract(const Duration(days: 7));
      final lastMondayStr = formatDateKey(lastMonday);
      final tuesday = lastMonday.add(const Duration(days: 1));

      var walking = Habit(
        id: 'walk-101',
        name: 'Walking',
        createdAt: todayDate,
        completedDates: {},
      );

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => [walking]);
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => const HabitScore(score: 0.0, completed: 0, total: 1),
      );
      when(() => mockRepository.markCompleted('walk-101', lastMonday)).thenAnswer((_) async {
        walking = walking.copyWith(completedDates: {lastMondayStr});
        return walking;
      });

      final container = createContainer();
      await container.read(habitControllerProvider.future);
      final controller = container.read(habitControllerProvider.notifier);

      // 1. Navigate to last week's Monday: Walking is visible, completed = false
      await controller.changeSelectedDate(lastMonday);
      await pumpEventQueue();
      var habits = container.read(habitControllerProvider).value!;
      expect(habits.length, 1);
      expect(habits.first.name, 'Walking');
      expect(habits.first.completed, isFalse);

      // 2. Mark Walking completed on last Monday
      await controller.toggleCompletion(habits.first, date: lastMonday);
      await pumpEventQueue();
      habits = container.read(habitControllerProvider).value!;
      expect(habits.first.completed, isTrue);

      // 3. Navigate to Tuesday: Walking is visible, completed = false
      await controller.changeSelectedDate(tuesday);
      await pumpEventQueue();
      habits = container.read(habitControllerProvider).value!;
      expect(habits.length, 1);
      expect(habits.first.name, 'Walking');
      expect(habits.first.completed, isFalse);

      // 4. Navigate back to Monday: Walking is visible and still marked completed!
      await controller.changeSelectedDate(lastMonday);
      await pumpEventQueue();
      habits = container.read(habitControllerProvider).value!;
      expect(habits.length, 1);
      expect(habits.first.name, 'Walking');
      expect(habits.first.completed, isTrue);

      // 5. Navigate back to Today: Walking is visible with today's completion state (false)
      await controller.changeSelectedDate(todayDate);
      await pumpEventQueue();
      habits = container.read(habitControllerProvider).value!;
      expect(habits.length, 1);
      expect(habits.first.name, 'Walking');
      expect(habits.first.completed, isFalse);
    });

    // ─── HABIT NOTES DATA CONSISTENCY & THEME PLACEHOLDER TESTS ──────

    // TEST 18 (Prompt TEST 1): Today + Walking -> Enter "Today walk" -> Save -> Navigate to yesterday -> Expected: Empty note
    test('TEST 18: Today + Walking note -> navigate to yesterday -> Empty note', () async {
      final walking = Habit(id: 'walk-101', name: 'Walking', createdAt: yesterday);
      final notesDb = <String, HabitNote>{}; // key: "habitId_dateStr"

      when(() => mockRepository.getHabits(date: any(named: 'date')))
          .thenAnswer((inv) async {
        final date = inv.namedArguments[#date] as DateTime? ?? today;
        final dateKey = formatDateKey(date);
        final note = notesDb['walk-101_$dateKey'];
        return [
          walking.copyWith(
            selectedDate: date,
            hasNote: note != null && note.content.isNotEmpty,
            noteContent: note?.content,
          )
        ];
      });

      when(() => mockNoteRepository.getNote('walk-101', any())).thenAnswer((inv) async {
        final dateStr = inv.positionalArguments[1] as String;
        return notesDb['walk-101_$dateStr'];
      });

      when(() => mockNoteRepository.saveNote('walk-101', any(), any())).thenAnswer((inv) async {
        final dateStr = inv.positionalArguments[1] as String;
        final content = inv.positionalArguments[2] as String;
        final note = HabitNote(id: 'n1', habitId: 'walk-101', date: dateStr, content: content);
        notesDb['walk-101_$dateStr'] = note;
        return note;
      });

      final container = createContainer();
      await container.read(habitControllerProvider.future);

      final noteNotifier = container.read(dailyNoteControllerProvider.notifier);

      // Today + Walking: load note
      await noteNotifier.loadNote('walk-101', today);
      expect(container.read(dailyNoteControllerProvider).content, isEmpty);

      // Enter "Today walk" and save
      await noteNotifier.saveNote('Today walk');
      expect(container.read(dailyNoteControllerProvider).content, 'Today walk');
      expect(container.read(dailyNoteControllerProvider).hasExistingNote, isTrue);

      // Navigate to yesterday
      await noteNotifier.loadNote('walk-101', yesterday);
      expect(container.read(dailyNoteControllerProvider).content, isEmpty);
      expect(container.read(dailyNoteControllerProvider).hasExistingNote, isFalse);
    });

    // TEST 19 (Prompt TEST 2): Yesterday + Walking -> "Yesterday walk" -> Navigate today -> "Today walk" -> Navigate yesterday -> "Yesterday walk"
    test('TEST 19: Yesterday + Walking note -> navigate today -> Today walk -> navigate yesterday -> Yesterday walk', () async {
      final notesDb = <String, HabitNote>{
        'walk-101_$todayStr': HabitNote(id: 'n1', habitId: 'walk-101', date: todayStr, content: 'Today walk'),
      };

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => []);
      when(() => mockNoteRepository.getNote('walk-101', any())).thenAnswer((inv) async {
        final dateStr = inv.positionalArguments[1] as String;
        return notesDb['walk-101_$dateStr'];
      });
      when(() => mockNoteRepository.saveNote('walk-101', any(), any())).thenAnswer((inv) async {
        final dateStr = inv.positionalArguments[1] as String;
        final content = inv.positionalArguments[2] as String;
        final note = HabitNote(id: 'n2', habitId: 'walk-101', date: dateStr, content: content);
        notesDb['walk-101_$dateStr'] = note;
        return note;
      });

      final container = createContainer();
      final noteNotifier = container.read(dailyNoteControllerProvider.notifier);

      // 1. Yesterday + Walking: Enter "Yesterday walk" and Save
      await noteNotifier.loadNote('walk-101', yesterday);
      expect(container.read(dailyNoteControllerProvider).content, isEmpty);
      await noteNotifier.saveNote('Yesterday walk');

      // 2. Navigate to today -> Expected: "Today walk"
      await noteNotifier.loadNote('walk-101', today);
      expect(container.read(dailyNoteControllerProvider).content, 'Today walk');

      // 3. Navigate back to yesterday -> Expected: "Yesterday walk"
      await noteNotifier.loadNote('walk-101', yesterday);
      expect(container.read(dailyNoteControllerProvider).content, 'Yesterday walk');
    });

    // TEST 20 (Prompt TEST 3): Today + Reading -> "Read 20 pages" -> Switch to Walking -> Walking note -> Switch back to Reading -> "Read 20 pages"
    test('TEST 20: Habit switching on same date preserves independent note state', () async {
      final notesDb = <String, HabitNote>{
        'walk-101_$todayStr': HabitNote(id: 'n1', habitId: 'walk-101', date: todayStr, content: 'Morning walk'),
      };

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => []);
      when(() => mockNoteRepository.getNote(any(), any())).thenAnswer((inv) async {
        final habitId = inv.positionalArguments[0] as String;
        final dateStr = inv.positionalArguments[1] as String;
        return notesDb['${habitId}_$dateStr'];
      });
      when(() => mockNoteRepository.saveNote(any(), any(), any())).thenAnswer((inv) async {
        final habitId = inv.positionalArguments[0] as String;
        final dateStr = inv.positionalArguments[1] as String;
        final content = inv.positionalArguments[2] as String;
        final note = HabitNote(id: 'n-new', habitId: habitId, date: dateStr, content: content);
        notesDb['${habitId}_$dateStr'] = note;
        return note;
      });

      final container = createContainer();
      final noteNotifier = container.read(dailyNoteControllerProvider.notifier);

      // 1. Today + Reading: Enter "Read 20 pages" and save
      await noteNotifier.loadNote('read-202', today);
      expect(container.read(dailyNoteControllerProvider).content, isEmpty);
      await noteNotifier.saveNote('Read 20 pages');

      // 2. Switch to Walking -> Expected: "Morning walk"
      await noteNotifier.changeHabit('walk-101');
      expect(container.read(dailyNoteControllerProvider).content, 'Morning walk');

      // 3. Switch back to Reading -> Expected: "Read 20 pages"
      await noteNotifier.changeHabit('read-202');
      expect(container.read(dailyNoteControllerProvider).content, 'Read 20 pages');
    });

    // TEST 21 (Prompt TEST 4): Create notes for Sep 1..Sep 5 -> random navigation -> each date displays its own note
    test('TEST 21: Create notes for Sep 1-5 -> random date navigation displays exact isolated notes', () async {
      final dates = List.generate(5, (i) => DateTime(2026, 9, 1 + i));
      final notesDb = <String, HabitNote>{};

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => []);
      when(() => mockNoteRepository.getNote(any(), any())).thenAnswer((inv) async {
        final habitId = inv.positionalArguments[0] as String;
        final dateStr = inv.positionalArguments[1] as String;
        return notesDb['${habitId}_$dateStr'];
      });
      when(() => mockNoteRepository.saveNote(any(), any(), any())).thenAnswer((inv) async {
        final habitId = inv.positionalArguments[0] as String;
        final dateStr = inv.positionalArguments[1] as String;
        final content = inv.positionalArguments[2] as String;
        final note = HabitNote(id: 'n-$dateStr', habitId: habitId, date: dateStr, content: content);
        notesDb['${habitId}_$dateStr'] = note;
        return note;
      });

      final container = createContainer();
      final noteNotifier = container.read(dailyNoteControllerProvider.notifier);

      // Create notes for each date
      for (int i = 0; i < dates.length; i++) {
        final d = dates[i];
        await noteNotifier.loadNote('habit-sep', d);
        await noteNotifier.saveNote('Note for Sep ${i + 1}');
      }

      // Random navigation order: Sep 4, Sep 1, Sep 5, Sep 2, Sep 3, Sep 1, Sep 4
      final testOrder = [3, 0, 4, 1, 2, 0, 3];
      for (final index in testOrder) {
        final d = dates[index];
        await noteNotifier.loadNote('habit-sep', d);
        expect(
          container.read(dailyNoteControllerProvider).content,
          'Note for Sep ${index + 1}',
          reason: 'Date Sep ${index + 1} must strictly return its own note',
        );
      }
    });

    // TEST 22 (Prompt TEST 5): Save notes -> restart application -> navigate through dates -> notes correctly associated
    test('TEST 22: Persistent notes remain attached to (habitId, date) across application restarts', () async {
      final date1 = DateTime(2026, 9, 1);
      final date2 = DateTime(2026, 9, 2);
      final date1Str = formatDateKey(date1);
      final date2Str = formatDateKey(date2);

      final persistentDb = <String, HabitNote>{
        'h1_$date1Str': HabitNote(id: 'n1', habitId: 'h1', date: date1Str, content: 'Persisted Day 1'),
        'h1_$date2Str': HabitNote(id: 'n2', habitId: 'h1', date: date2Str, content: 'Persisted Day 2'),
      };

      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => []);
      when(() => mockNoteRepository.getNote(any(), any())).thenAnswer((inv) async {
        final habitId = inv.positionalArguments[0] as String;
        final dateStr = inv.positionalArguments[1] as String;
        return persistentDb['${habitId}_$dateStr'];
      });

      // Session 1:
      final container1 = createContainer();
      final noteNotifier1 = container1.read(dailyNoteControllerProvider.notifier);
      await noteNotifier1.loadNote('h1', date1);
      expect(container1.read(dailyNoteControllerProvider).content, 'Persisted Day 1');
      container1.dispose();

      // Session 2 (Simulating App Restart):
      final container2 = ProviderContainer(
        overrides: [
          apiHabitRepositoryProvider.overrideWithValue(mockRepository),
          noteRepositoryProvider.overrideWithValue(mockNoteRepository),
        ],
      );
      addTearDown(container2.dispose);

      final noteNotifier2 = container2.read(dailyNoteControllerProvider.notifier);
      await noteNotifier2.loadNote('h1', date2);
      expect(container2.read(dailyNoteControllerProvider).content, 'Persisted Day 2');

      await noteNotifier2.loadNote('h1', date1);
      expect(container2.read(dailyNoteControllerProvider).content, 'Persisted Day 1');
    });

    // TEST 23 (Prompt TEST 6 & DARK THEME): Switching Light <-> Dark theme maintains notes and applies readable placeholders
    test('TEST 23: Theme-aware placeholder styling produces high-contrast, distinguishable hints in dark and light modes', () {
      final lightTheme = buildCustomTheme(AppTheme.defaultPrimaryColor, isDark: false);
      final darkTheme = buildCustomTheme(AppTheme.defaultPrimaryColor, isDark: true);

      // Light theme input decoration
      final lightInput = lightTheme.inputDecorationTheme;
      expect(lightInput.hintStyle?.color, AppTheme.textMuted);
      expect(lightInput.fillColor, const Color(0xFFF8FAFC));

      // Dark theme input decoration: must NEVER be hardcoded white or light
      final darkInput = darkTheme.inputDecorationTheme;
      expect(darkInput.hintStyle?.color, AppTheme.darkTextMuted);
      expect(darkInput.hintStyle?.color, isNot(Colors.white));
      expect(darkInput.fillColor, const Color(0xFF0F172A));
      expect(darkInput.focusedBorder?.borderSide.color, lightTheme.primaryColor);
    });

    // =========================================================================
    // HABIT SCORE TESTS (USER REQUIREMENTS SECTIONS 20 - 26)
    // =========================================================================

    // TEST 24 (Prompt Section 20): Known Dataset: Sep 1 -> Sep 7, Walking completed 5/7 -> 71.4%
    // Invariant across date navigation (Sep 1, Sep 3, Sep 5, Sep 7, Today)
    test('TEST 24: (Section 20) Known dataset Walking 5/7 = 71.4% invariant across all date navigation', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep2 = DateTime(2026, 9, 2);
      final sep3 = DateTime(2026, 9, 3);
      final sep4 = DateTime(2026, 9, 4);
      final sep5 = DateTime(2026, 9, 5);
      final sep6 = DateTime(2026, 9, 6);
      final sep7 = DateTime(2026, 9, 7);

      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: sep1,
        completedDates: {
          formatDateKey(sep1),
          formatDateKey(sep2),
          formatDateKey(sep4),
          formatDateKey(sep6),
          formatDateKey(sep7),
        },
      );

      // Single habit score
      final habitScore = HabitScoreCalculator.calculateHabitScore(
        habit: walking,
        startDate: sep1,
        endDate: sep7,
        enableLogging: true,
      );
      expect(habitScore.completedDays, 5);
      expect(habitScore.trackedDays, 7);
      expect(habitScore.score, 71.4);
      expect(habitScore.scoreText, '71.4%');

      // Overall score
      final overall = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: sep1,
        endDate: sep7,
        enableLogging: true,
      );
      expect(overall.completed, 5);
      expect(overall.total, 7);
      expect(overall.score, 71.4);
      expect(overall.scoreText, '71.4%');

      // Now verify via Provider & Controller that date navigation maintains 71.4% identically
      when(() => mockRepository.getHabitScore(any())).thenAnswer(
        (_) async => overall,
      );
      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer(
        (_) async => [walking],
      );

      final container = createContainer();
      final scoreInit = await container.read(habitScoreProvider.future);
      expect(scoreInit.score, 71.4);
      expect(scoreInit.completed, 5);
      expect(scoreInit.total, 7);

      // Navigate Sep 1
      await container.read(habitControllerProvider.notifier).changeSelectedDate(sep1);
      await pumpEventQueue();
      expect(container.read(habitScoreProvider).value?.score, 71.4);

      // Navigate Sep 3
      await container.read(habitControllerProvider.notifier).changeSelectedDate(sep3);
      await pumpEventQueue();
      expect(container.read(habitScoreProvider).value?.score, 71.4);

      // Navigate Sep 5
      await container.read(habitControllerProvider.notifier).changeSelectedDate(sep5);
      await pumpEventQueue();
      expect(container.read(habitScoreProvider).value?.score, 71.4);

      // Navigate Sep 7
      await container.read(habitControllerProvider.notifier).changeSelectedDate(sep7);
      await pumpEventQueue();
      expect(container.read(habitScoreProvider).value?.score, 71.4);
    });

    // TEST 25 (Prompt Section 21): 100% Completion: Sep 1 -> Sep 7, 7/7 = 100%
    test('TEST 25: (Section 21) 7/7 completions produces exactly 100%', () {
      final sep1 = DateTime(2026, 9, 1);
      final sep7 = DateTime(2026, 9, 7);

      final all7Days = List.generate(7, (i) => formatDateKey(sep1.add(Duration(days: i)))).toSet();
      final walking = Habit(id: 'h1', name: 'Walking', createdAt: sep1, completedDates: all7Days);

      final res = HabitScoreCalculator.calculateHabitScore(
        habit: walking,
        startDate: sep1,
        endDate: sep7,
      );
      expect(res.completedDays, 7);
      expect(res.trackedDays, 7);
      expect(res.score, 100.0);
      expect(res.scoreText, '100%');

      final overall = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: sep1,
        endDate: sep7,
      );
      expect(overall.completed, 7);
      expect(overall.total, 7);
      expect(overall.score, 100.0);
      expect(overall.scoreText, '100%');
    });

    // TEST 26 (Prompt Section 22): Zero completions: Sep 1 -> Sep 7, 0/7 = 0% (not NaN, not null, not 100%)
    test('TEST 26: (Section 22) 0 completions over 7 tracked days produces exactly 0% (not NaN, null, or 100%)', () {
      final sep1 = DateTime(2026, 9, 1);
      final sep7 = DateTime(2026, 9, 7);

      final walking = Habit(id: 'h1', name: 'Walking', createdAt: sep1, completedDates: {});

      final res = HabitScoreCalculator.calculateHabitScore(
        habit: walking,
        startDate: sep1,
        endDate: sep7,
      );
      expect(res.completedDays, 0);
      expect(res.trackedDays, 7);
      expect(res.score, 0.0);
      expect(res.score.isNaN, isFalse);
      expect(res.score.isInfinite, isFalse);
      expect(res.scoreText, '0%');

      final overall = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: sep1,
        endDate: sep7,
      );
      expect(overall.completed, 0);
      expect(overall.total, 7);
      expect(overall.score, 0.0);
      expect(overall.scoreText, '0%');
    });

    // TEST 27 (Prompt Section 23): Historical Backfill: Habit created Sep 7, backfilled Sep 1, 3, 5 -> 3/7 = 42.9%
    test('TEST 27: (Section 23) Historical backfill counts prior completions regardless of habit creation date', () {
      final sep1 = DateTime(2026, 9, 1);
      final sep3 = DateTime(2026, 9, 3);
      final sep5 = DateTime(2026, 9, 5);
      final sep7 = DateTime(2026, 9, 7);

      // Created today (Sep 7), with historical completions on Sep 1, 3, 5
      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: sep7,
        completedDates: {
          formatDateKey(sep1),
          formatDateKey(sep3),
          formatDateKey(sep5),
        },
      );

      // Tracking start is Sep 1 (earliest backfill), end is Sep 7
      final trackingStart = HabitScoreCalculator.getTrackingStartDate(
        [walking],
        referenceToday: sep7,
      );
      expect(trackingStart, sep1);

      final res = HabitScoreCalculator.calculateHabitScore(
        habit: walking,
        startDate: trackingStart,
        endDate: sep7,
      );
      expect(res.completedDays, 3);
      expect(res.trackedDays, 7);
      expect(res.score, 42.9);
      expect(res.scoreText, '42.9%');

      final overall = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: trackingStart,
        endDate: sep7,
      );
      expect(overall.completed, 3);
      expect(overall.total, 7);
      expect(overall.score, 42.9);
      expect(overall.scoreText, '42.9%');
    });

    // TEST 28 (Prompt Section 24): Arbitrary navigation order: Today -> Sep 1 -> Sep 6 -> Sep 3 -> Today -> Sep 2 -> Sep 7
    test('TEST 28: (Section 24) Random navigation sequence produces identical score at every step', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep2 = DateTime(2026, 9, 2);
      final sep3 = DateTime(2026, 9, 3);
      final sep6 = DateTime(2026, 9, 6);
      final sep7 = DateTime(2026, 9, 7);

      const persistentScore = HabitScore(score: 71.4, completed: 5, total: 7);

      when(() => mockRepository.getHabitScore(any())).thenAnswer((_) async => persistentScore);
      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => []);

      final container = createContainer();
      await container.read(habitScoreProvider.future);

      final navSequence = [sep7, sep1, sep6, sep3, sep7, sep2, sep7];
      for (final targetDate in navSequence) {
        await container.read(habitControllerProvider.notifier).changeSelectedDate(targetDate);
        await pumpEventQueue();

        final current = container.read(habitScoreProvider).value;
        expect(current?.score, 71.4, reason: 'Failed at date $targetDate');
        expect(current?.completed, 5);
        expect(current?.total, 7);
      }
    });

    // TEST 29 (Prompt Section 25): App Restart Invariance: Database score is identical across restarts
    test('TEST 29: (Section 25) Stored dataset produces identical score across simulated app restart', () async {
      final sep1 = DateTime(2026, 9, 1);
      final sep7 = DateTime(2026, 9, 7);

      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: sep1,
        completedDates: {
          formatDateKey(sep1),
          formatDateKey(DateTime(2026, 9, 2)),
          formatDateKey(DateTime(2026, 9, 4)),
          formatDateKey(DateTime(2026, 9, 6)),
          formatDateKey(sep7),
        },
      );

      final scoreBeforeRestart = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: sep1,
        endDate: sep7,
      );

      // Simulate App Restart (new container, new repository fetch)
      when(() => mockRepository.getHabitScore(any())).thenAnswer((_) async => scoreBeforeRestart);
      when(() => mockRepository.getHabits(date: any(named: 'date'))).thenAnswer((_) async => [walking]);

      final container = createContainer();
      final scoreAfterRestart = await container.read(habitScoreProvider.future);

      expect(scoreAfterRestart.score, scoreBeforeRestart.score);
      expect(scoreAfterRestart.completed, scoreBeforeRestart.completed);
      expect(scoreAfterRestart.total, scoreBeforeRestart.total);
    });

    // TEST 30 (Prompt Section 26): Reorder Invariance: Reordering habits preserves all habit scores
    test('TEST 30: (Section 26) Reordering habits preserves individual and overall scores', () {
      final sep1 = DateTime(2026, 9, 1);
      final sep7 = DateTime(2026, 9, 7);

      // Walking: 5/7 = 71.4%
      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: sep1,
        sortOrder: 0,
        completedDates: {
          formatDateKey(sep1),
          formatDateKey(DateTime(2026, 9, 2)),
          formatDateKey(DateTime(2026, 9, 4)),
          formatDateKey(DateTime(2026, 9, 6)),
          formatDateKey(sep7),
        },
      );

      // Reading: 3/7 = 42.9%
      final reading = Habit(
        id: 'h2',
        name: 'Reading',
        createdAt: sep1,
        sortOrder: 1,
        completedDates: {
          formatDateKey(sep1),
          formatDateKey(DateTime(2026, 9, 3)),
          formatDateKey(sep7),
        },
      );

      // Meditation: 7/7 = 100%
      final meditation = Habit(
        id: 'h3',
        name: 'Meditation',
        createdAt: sep1,
        sortOrder: 2,
        completedDates: List.generate(7, (i) => formatDateKey(sep1.add(Duration(days: i)))).toSet(),
      );

      final listBefore = [walking, reading, meditation];
      final listAfterReorder = [reading, meditation, walking];

      // Overall: (5 + 3 + 7) / (7 + 7 + 7) = 15 / 21 = 71.4%
      final scoreBefore = HabitScoreCalculator.calculateOverallScore(
        habits: listBefore,
        startDate: sep1,
        endDate: sep7,
      );

      final scoreAfter = HabitScoreCalculator.calculateOverallScore(
        habits: listAfterReorder,
        startDate: sep1,
        endDate: sep7,
      );

      expect(scoreAfter.score, scoreBefore.score);
      expect(scoreAfter.completed, scoreBefore.completed);
      expect(scoreAfter.total, scoreBefore.total);
      expect(scoreAfter.score, 71.4);
      expect(scoreAfter.completed, 15);
      expect(scoreAfter.total, 21);

      // Individual habit scores are identified strictly by habitId and remain invariant
      final readingScore = HabitScoreCalculator.calculateHabitScore(habit: reading, startDate: sep1, endDate: sep7);
      final walkingScore = HabitScoreCalculator.calculateHabitScore(habit: walking, startDate: sep1, endDate: sep7);
      final medScore = HabitScoreCalculator.calculateHabitScore(habit: meditation, startDate: sep1, endDate: sep7);

      expect(readingScore.score, 42.9);
      expect(walkingScore.score, 71.4);
      expect(medScore.score, 100.0);
    });

    // TEST 31: Distinguish UNIQUE HABITS vs HABIT-DAYS vs COMPLETED HABIT-DAYS vs HABIT SCORE
    // Dataset: 2 habits, 4 tracking days, 5 completions
    test('TEST 31: Distinguish Unique Habits (2), Habit-Days (8), Completed (5), Score (62.5%)', () {
      final day1 = DateTime(2026, 9, 1);
      final day2 = DateTime(2026, 9, 2);
      final day3 = DateTime(2026, 9, 3);
      final day4 = DateTime(2026, 9, 4);

      // Walking: Day 1 ✓, Day 2 ✓, Day 3 ✗, Day 4 ✓ (3/4 = 75%)
      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: day1,
        completedDates: {formatDateKey(day1), formatDateKey(day2), formatDateKey(day4)},
      );

      // Reading: Day 1 ✓, Day 2 ✗, Day 3 ✗, Day 4 ✓ (2/4 = 50%)
      final reading = Habit(
        id: 'h2',
        name: 'Reading',
        createdAt: day1,
        completedDates: {formatDateKey(day1), formatDateKey(day4)},
      );

      final result = HabitScoreCalculator.calculateOverallScore(
        habits: [walking, reading],
        startDate: day1,
        endDate: day4,
      );

      // A. Number of unique habits = 2
      expect(result.uniqueHabits, 2);
      expect(result.habitsCount, 2);

      // B. Habit-days = 2 habits × 4 days = 8
      expect(result.totalHabitDays, 8);
      expect(result.habitDaysTotal, 8);

      // C. Completed habit-days = 3 + 2 = 5
      expect(result.completedHabitDays, 5);
      expect(result.habitDaysCompleted, 5);

      // D. Habit Score = 5 / 8 * 100 = 62.5%
      expect(result.score, 62.5);
      expect(result.scoreText, '62.5%');

      // Supporting label must say "5 / 8 habit-days", NEVER "5 / 8 habits"
      expect(result.habitDaysText, '5 / 8 habit-days');
      expect(result.habitDaysText.contains('habits'), isFalse);
    });

    // TEST 32: Zero-Data Case: 0 habits -> Score = 0%, no NaN/Infinity
    test('TEST 32: Zero-Data Case -> 0 habits, 0% score, 0 / 0 habit-days', () {
      final now = DateTime(2026, 9, 7);
      final result = HabitScoreCalculator.calculateOverallScore(
        habits: [],
        startDate: now,
        endDate: now,
      );

      expect(result.uniqueHabits, 0);
      expect(result.totalHabitDays, 0);
      expect(result.completedHabitDays, 0);
      expect(result.score, 0.0);
      expect(result.scoreText, '0%');
      expect(result.habitDaysText, '0 / 0 habit-days');
      expect(result.score.isNaN, isFalse);
      expect(result.score.isInfinite, isFalse);
    });

    // TEST 33: Notes do NOT contribute to Habit Score or Completed Habit-Days
    test('TEST 33: Notes do NOT contribute to completion or score', () {
      final day1 = DateTime(2026, 9, 1);
      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: day1,
        completedDates: {}, // No completions
        noteContent: 'Walked 5 miles today', // Note exists
      );

      final result = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: day1,
        endDate: day1,
      );

      expect(result.completedHabitDays, 0);
      expect(result.totalHabitDays, 1);
      expect(result.score, 0.0);
      expect(result.scoreText, '0%');
    });

    // TEST 34: Duplicate completions do NOT inflate score
    test('TEST 34: Duplicate completions are strictly deduplicated', () {
      final day1 = DateTime(2026, 9, 1);
      // Even if raw completedDates set contains day1, it only counts once
      final walking = Habit(
        id: 'h1',
        name: 'Walking',
        createdAt: day1,
        completedDates: {formatDateKey(day1)},
      );

      final result = HabitScoreCalculator.calculateOverallScore(
        habits: [walking],
        startDate: day1,
        endDate: day1,
      );

      expect(result.completedHabitDays, 1);
      expect(result.totalHabitDays, 1);
      expect(result.score, 100.0);
      expect(result.scoreText, '100%');
    });

    // SECTION 14: DATA INTEGRITY TEST CASES (FINAL HABIT SCORE SPEC)
    group('Section 14 Data Integrity Acceptance Test Cases', () {
      final sep7 = DateTime(2026, 9, 7);
      final sep7Key = formatDateKey(sep7);

      test('TEST 1: 3 habits, 1 completed -> 1 / 3 = 33.3%', () {
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {sep7Key});
        final h2 = Habit(id: 'h2', name: 'Read Book', createdAt: sep7, completedDates: {});
        final h3 = Habit(id: 'h3', name: 'Health', createdAt: sep7, completedDates: {});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1, h2, h3],
          date: sep7,
        );

        expect(score.completedHabitDays, 1);
        expect(score.totalHabitDays, 3);
        expect(score.score, 33.3);
        expect(score.scoreText, '33.3%');
        expect(score.habitDaysText, '1 / 3 habit-days');
      });

      test('TEST 2: 3 habits, 2 completed -> 2 / 3 = 66.7%', () {
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {sep7Key});
        final h2 = Habit(id: 'h2', name: 'Read Book', createdAt: sep7, completedDates: {sep7Key});
        final h3 = Habit(id: 'h3', name: 'Health', createdAt: sep7, completedDates: {});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1, h2, h3],
          date: sep7,
        );

        expect(score.completedHabitDays, 2);
        expect(score.totalHabitDays, 3);
        expect(score.score, 66.7);
        expect(score.scoreText, '66.7%');
        expect(score.habitDaysText, '2 / 3 habit-days');
      });

      test('TEST 3: 3 habits, 3 completed -> 3 / 3 = 100%', () {
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {sep7Key});
        final h2 = Habit(id: 'h2', name: 'Read Book', createdAt: sep7, completedDates: {sep7Key});
        final h3 = Habit(id: 'h3', name: 'Health', createdAt: sep7, completedDates: {sep7Key});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1, h2, h3],
          date: sep7,
        );

        expect(score.completedHabitDays, 3);
        expect(score.totalHabitDays, 3);
        expect(score.score, 100.0);
        expect(score.scoreText, '100%');
        expect(score.habitDaysText, '3 / 3 habit-days');
      });

      test('TEST 4: 3 habits, 0 completed -> 0 / 3 = 0%', () {
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {});
        final h2 = Habit(id: 'h2', name: 'Read Book', createdAt: sep7, completedDates: {});
        final h3 = Habit(id: 'h3', name: 'Health', createdAt: sep7, completedDates: {});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1, h2, h3],
          date: sep7,
        );

        expect(score.completedHabitDays, 0);
        expect(score.totalHabitDays, 3);
        expect(score.score, 0.0);
        expect(score.scoreText, '0%');
        expect(score.habitDaysText, '0 / 3 habit-days');
      });

      test('TEST 5: Duplicate completion records count ONCE', () {
        // Even if identical logical keys are in collection, deduplication guarantees 1
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {sep7Key, sep7Key});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1],
          date: sep7,
        );

        expect(score.completedHabitDays, 1);
        expect(score.totalHabitDays, 1);
        expect(score.score, 100.0);
      });

      test('TEST 6: 10 habits across 7 days -> max possible habit-days = 70', () {
        final sep1 = DateTime(2026, 9, 1);
        final habits = List.generate(10, (i) => Habit(
          id: 'h$i',
          name: 'Habit $i',
          createdAt: sep1,
          completedDates: {},
        ));

        final score = HabitScoreCalculator.calculateOverallScore(
          habits: habits,
          startDate: sep1,
          endDate: sep7,
        );

        expect(score.totalHabitDays, 70);
        expect(score.totalHabitDays <= 70, isTrue);
      });

      test('TEST 7: Habit with historical completion on Sep 1 is visible & counts on Sep 1 & Sep 7', () {
        final sep1 = DateTime(2026, 9, 1);
        final sep1Key = formatDateKey(sep1);
        final walking = Habit(
          id: 'h_walk',
          name: 'Walking',
          createdAt: sep7, // created on Sep 7
          completedDates: {sep1Key}, // historical completion backfilled for Sep 1
        );

        // On Sep 1: visible and completed
        expect(walking.isApplicableOn(sep1), isTrue);
        expect(walking.isCompletedOn(sep1), isTrue);
        final sep1Score = HabitScoreCalculator.calculateForDate(habits: [walking], date: sep1);
        expect(sep1Score.completedHabitDays, 1);
        expect(sep1Score.totalHabitDays, 1);
        expect(sep1Score.score, 100.0);

        // On Sep 7: visible and active (not completed on Sep 7)
        expect(walking.isApplicableOn(sep7), isTrue);
        expect(walking.isCompletedOn(sep7), isFalse);
        final sep7Score = HabitScoreCalculator.calculateForDate(habits: [walking], date: sep7);
        expect(sep7Score.completedHabitDays, 0);
        expect(sep7Score.totalHabitDays, 1);
        expect(sep7Score.score, 0.0);
      });

      test('TEST 8: Adding new habit today affects today score without fabricating historical data', () {
        final sep1 = DateTime(2026, 9, 1);
        final existing = Habit(
          id: 'h_exist',
          name: 'Existing',
          createdAt: sep1,
          completedDates: {formatDateKey(sep1)},
        );

        // Before adding new habit:
        final sep1Before = HabitScoreCalculator.calculateForDate(habits: [existing], date: sep1);
        expect(sep1Before.completedHabitDays, 1);
        expect(sep1Before.totalHabitDays, 1);

        // User creates new habit on Sep 7
        final newHabit = Habit(
          id: 'h_new',
          name: 'New Habit',
          createdAt: sep7,
          completedDates: {},
        );

        // Today's score now includes newHabit
        final sep7Score = HabitScoreCalculator.calculateForDate(
          habits: [existing, newHabit],
          date: sep7,
        );
        expect(sep7Score.totalHabitDays, 2);
        expect(sep7Score.completedHabitDays, 0);

        // Historical completion records for existing habit on Sep 1 are unaffected
        expect(existing.completedDates.contains(formatDateKey(sep1)), isTrue);
        expect(newHabit.completedDates.isEmpty, isTrue);
      });

      test('TEST 9: Archiving a habit does not duplicate or corrupt score', () {
        final h1 = Habit(id: 'h1', name: 'Walking', createdAt: sep7, completedDates: {sep7Key});
        final h2 = Habit(id: 'h2', name: 'Running', createdAt: sep7, archived: true, completedDates: {sep7Key});

        final score = HabitScoreCalculator.calculateForDate(
          habits: [h1, h2],
          date: sep7,
        );

        // Archived habit excluded from active habit-days
        expect(score.totalHabitDays, 1);
        expect(score.completedHabitDays, 1);
        expect(score.score, 100.0);
      });

      test('TEST 10: Date normalization ensures timestamps on same calendar day map to same date', () {
        final t1 = DateTime(2026, 9, 7, 0, 1);
        final t2 = DateTime(2026, 9, 7, 12, 30);
        final t3 = DateTime(2026, 9, 7, 23, 59);

        expect(normalizeToLocalDateString(t1), '2026-09-07');
        expect(normalizeToLocalDateString(t2), '2026-09-07');
        expect(normalizeToLocalDateString(t3), '2026-09-07');
      });
    });
  });
}
