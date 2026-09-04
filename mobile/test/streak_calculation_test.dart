import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/features/habits/domain/streak_calculator.dart';

void main() {
  group('Streak Calculation Rules (Cases 1 - 5)', () {
    final today = DateTime(2026, 9, 1);
    final yesterday = DateTime(2026, 8, 31);
    final twoDaysAgo = DateTime(2026, 8, 30);
    final threeDaysAgo = DateTime(2026, 8, 29);

    final todayKey = formatDateKey(today);
    final yesterdayKey = formatDateKey(yesterday);
    final twoDaysAgoKey = formatDateKey(twoDaysAgo);
    final threeDaysAgoKey = formatDateKey(threeDaysAgo);

    test(
      'Case 1: Today ✓, Yesterday ✓, 2 days ago ✓ -> Current streak = 3',
      () {
        final completions = {todayKey, yesterdayKey, twoDaysAgoKey};
        expect(calculateCurrentStreak(completions, today), 3);
      },
    );

    test(
      'Case 2: Today ✗, Yesterday ✓, 2 days ago ✓ -> Current streak = 2',
      () {
        final completions = {yesterdayKey, twoDaysAgoKey};
        expect(calculateCurrentStreak(completions, today), 2);
      },
    );

    test(
      'Case 3: Today ✗, Yesterday ✗, 2 days ago ✓, 3 days ago ✓ -> Current streak = 0',
      () {
        final completions = {twoDaysAgoKey, threeDaysAgoKey};
        expect(calculateCurrentStreak(completions, today), 0);
      },
    );

    test(
      'Case 4: Today ✓, Yesterday ✗, 2 days ago ✓ -> Current streak = 1',
      () {
        final completions = {todayKey, twoDaysAgoKey};
        expect(calculateCurrentStreak(completions, today), 1);
      },
    );

    test('Empty completions returns 0', () {
      expect(calculateCurrentStreak({}, today), 0);
    });

    test('Only today completed returns 1', () {
      expect(calculateCurrentStreak({todayKey}, today), 1);
    });

    test('Only yesterday completed returns 1', () {
      expect(calculateCurrentStreak({yesterdayKey}, today), 1);
    });
  });
}
