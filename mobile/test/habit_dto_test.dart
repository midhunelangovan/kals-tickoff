import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker_mobile/features/habits/data/habit_dto.dart';
import 'package:habit_tracker_mobile/features/habits/data/habit_score_dto.dart';

void main() {
  group('HabitDto JSON Parsing', () {
    test(
      'parses habit list item with completedOnSelectedDate and completions history correctly',
      () {
        final json = {
          'id': 'test-uuid-1',
          'name': 'Read for 20 minutes',
          'icon': 'menu_book',
          'color': '#10B981',
          'createdAt': '2026-09-01T10:30:00',
          'archived': false,
          'selectedDate': '2026-08-31',
          'completedOnSelectedDate': true,
          'currentStreak': 5,
          'completions': [
            '2026-08-27',
            '2026-08-28',
            '2026-08-29',
            '2026-08-30',
            '2026-08-31',
          ],
        };

        final dto = HabitDto.fromJson(json);
        expect(dto.id, 'test-uuid-1');
        expect(dto.name, 'Read for 20 minutes');
        expect(dto.icon, 'menu_book');
        expect(dto.color, '#10B981');
        expect(dto.archived, false);
        expect(dto.completed, true);
        expect(dto.currentStreak, 5);
        expect(dto.completions, hasLength(5));

        final domain = dto.toDomain();
        expect(domain.id, 'test-uuid-1');
        expect(domain.name, 'Read for 20 minutes');
        expect(domain.icon, 'menu_book');
        expect(domain.color, '#10B981');
        expect(domain.completed, true);
        expect(domain.currentStreak, 5);
        expect(domain.isCompletedOn('2026-08-31'), true);
        expect(domain.isCompletedOn('2026-09-01'), false);
      },
    );

    test(
      'parses create habit response with completedToday field correctly',
      () {
        final json = {
          'id': 'test-uuid-2',
          'name': 'Drink water',
          'icon': 'water_drop',
          'color': '#06B6D4',
          'createdAt': '2026-09-01T10:30:00',
          'archived': false,
          'completedToday': false,
          'currentStreak': 0,
        };

        final dto = HabitDto.fromJson(json);
        expect(dto.id, 'test-uuid-2');
        expect(dto.name, 'Drink water');
        expect(dto.icon, 'water_drop');
        expect(dto.color, '#06B6D4');
        expect(dto.completed, false);
        expect(dto.currentStreak, 0);
      },
    );

    test(
      'HabitScoreDto parses score, date, and counts correctly',
      () {
        final json = {
          'date': '2026-09-02',
          'score': 66.7,
          'completed': 2,
          'total': 3,
        };

        final dto = HabitScoreDto.fromJson(json);
        expect(dto.date, '2026-09-02');
        expect(dto.score, 66.7);
        expect(dto.completed, 2);
        expect(dto.total, 3);
        expect(dto.expected, 3);

        final domain = dto.toDomain();
        expect(domain.date, '2026-09-02');
        expect(domain.score, 66.7);
        expect(domain.completed, 2);
        expect(domain.total, 3);
        expect(domain.expected, 3);
      },
    );

    test(
      'CompletionResponseDto parses completion payload and history correctly',
      () {
        final json = {
          'habitId': 'test-uuid-1',
          'completionDate': '2026-09-01',
          'completed': true,
          'currentStreak': 3,
          'completions': ['2026-08-30', '2026-08-31', '2026-09-01'],
        };

        final dto = CompletionResponseDto.fromJson(json);
        expect(dto.habitId, 'test-uuid-1');
        expect(dto.completionDate, '2026-09-01');
        expect(dto.completed, true);
        expect(dto.currentStreak, 3);
        expect(dto.completions, contains('2026-09-01'));
      },
    );
  });
}
