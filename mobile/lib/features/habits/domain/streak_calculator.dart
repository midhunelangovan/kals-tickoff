import 'package:intl/intl.dart';

final _dateFormat = DateFormat('yyyy-MM-dd');

String formatDateKey(DateTime date) => _dateFormat.format(date);

/// Calculates current streak strictly relative to TODAY.
/// Rules:
/// 1. If TODAY is completed: count consecutive completed days backwards starting from TODAY.
/// 2. If TODAY is NOT completed: allow the streak to continue from YESTERDAY.
/// 3. If neither TODAY nor YESTERDAY is completed: streak = 0.
int calculateCurrentStreak(
  Set<String> completedDates, [
  DateTime? referenceDate,
]) {
  if (completedDates.isEmpty) return 0;
  final now = referenceDate ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final todayKey = formatDateKey(today);
  final yesterdayKey = formatDateKey(today.subtract(const Duration(days: 1)));

  DateTime checkDate;
  if (completedDates.contains(todayKey)) {
    checkDate = today;
  } else if (completedDates.contains(yesterdayKey)) {
    checkDate = today.subtract(const Duration(days: 1));
  } else {
    return 0;
  }

  int streak = 0;
  while (completedDates.contains(formatDateKey(checkDate))) {
    streak++;
    checkDate = checkDate.subtract(const Duration(days: 1));
  }

  return streak;
}
