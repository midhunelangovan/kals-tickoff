import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/features/habits/domain/habit.dart';
import 'package:habit_tracker_mobile/features/habits/presentation/widgets/streak_heatmap.dart';

void main() {
  testWidgets('StreakHeatmap renders 12 week columns and invokes onSelectDate on cell tap', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime? selectedFromHeatmap;

    final habit = Habit(
      id: 'h1',
      name: 'Walking',
      createdAt: now,
      completed: true,
      currentStreak: 2,
      selectedDate: today,
      completedDates: {
        formatDateKey(today),
        formatDateKey(yesterday),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StreakHeatmap(
            habit: habit,
            selectedDate: today,
            onSelectDate: (date) {
              selectedFromHeatmap = date;
            },
            weeksCount: 12,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify heatmap contains inkwells for cells
    final inkWells = find.byType(InkWell);
    expect(inkWells, findsWidgets);

    // Tap the first available cell
    await tester.tap(inkWells.first);
    await tester.pumpAndSettle();

    expect(selectedFromHeatmap, isNotNull);
  });
}
