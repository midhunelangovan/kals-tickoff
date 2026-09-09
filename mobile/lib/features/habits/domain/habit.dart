import 'habit_color_palette.dart';
import 'streak_calculator.dart';
export 'streak_calculator.dart';

class Habit {
  final String id;
  final String name;
  final String icon;
  final DateTime createdAt;
  final bool archived;
  final bool completed;
  final int currentStreak;
  final String? description;
  final String? color;
  final DateTime? selectedDate;
  final Set<String> completedDates;
  final int sortOrder;
  final bool hasNote;
  final String? noteContent;
  final Map<String, String> notesByDate;

  Set<String> get completions => completedDates;

  HabitColorShades get colorShades => HabitColorShades.fromHex(color);

  const Habit({
    required this.id,
    required this.name,
    this.icon = 'bolt',
    this.description,
    this.color,
    required this.createdAt,
    this.archived = false,
    this.completed = false,
    this.currentStreak = 0,
    this.selectedDate,
    this.completedDates = const {},
    this.sortOrder = 0,
    this.hasNote = false,
    this.noteContent,
    this.notesByDate = const {},
  });

  String get createdDateKey => normalizeToLocalDateString(createdAt);

  DateTime get createdAtDate {
    final key = createdDateKey;
    if (key.length >= 10) {
      final parts = key.substring(0, 10).split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]) ?? createdAt.year;
        final m = int.tryParse(parts[1]) ?? createdAt.month;
        final d = int.tryParse(parts[2]) ?? createdAt.day;
        return DateTime(y, m, d);
      }
    }
    return DateTime(createdAt.year, createdAt.month, createdAt.day);
  }

  /// Habits are global: if a habit exists, it is visible on every selected date to allow historical backfilling.
  bool isApplicableOn(dynamic date) => !archived;

  bool isCompletedOn(dynamic date) {
    final dateKey = normalizeToLocalDateString(date);
    if (dateKey.isEmpty) return false;
    return completedDates.contains(dateKey);
  }

  bool hasNoteOn(dynamic date) {
    final dateKey = normalizeToLocalDateString(date);
    if (dateKey.isEmpty) return false;
    final note = notesByDate[dateKey];
    return note != null && note.trim().isNotEmpty;
  }

  String? noteOn(dynamic date) {
    final dateKey = normalizeToLocalDateString(date);
    if (dateKey.isEmpty) return null;
    final note = notesByDate[dateKey];
    return (note != null && note.trim().isNotEmpty) ? note.trim() : null;
  }

  Habit copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    String? color,
    DateTime? createdAt,
    bool? archived,
    bool? completed,
    int? currentStreak,
    DateTime? selectedDate,
    Set<String>? completedDates,
    Set<String>? completions,
    int? sortOrder,
    bool? hasNote,
    String? noteContent,
    bool clearNote = false,
    Map<String, String>? notesByDate,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      archived: archived ?? this.archived,
      completed: completed ?? this.completed,
      currentStreak: currentStreak ?? this.currentStreak,
      selectedDate: selectedDate ?? this.selectedDate,
      completedDates: completions ?? completedDates ?? this.completedDates,
      sortOrder: sortOrder ?? this.sortOrder,
      hasNote: clearNote ? false : (hasNote ?? this.hasNote),
      noteContent: clearNote ? null : (noteContent ?? this.noteContent),
      notesByDate: notesByDate ?? this.notesByDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Habit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          color == other.color &&
          archived == other.archived &&
          completed == other.completed &&
          currentStreak == other.currentStreak &&
          selectedDate == other.selectedDate &&
          sortOrder == other.sortOrder &&
          hasNote == other.hasNote &&
          noteContent == other.noteContent;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      icon.hashCode ^
      color.hashCode ^
      archived.hashCode ^
      completed.hashCode ^
      currentStreak.hashCode ^
      selectedDate.hashCode ^
      sortOrder.hashCode ^
      hasNote.hashCode ^
      noteContent.hashCode;
}
