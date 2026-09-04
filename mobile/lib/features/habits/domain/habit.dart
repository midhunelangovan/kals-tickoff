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
  });

  bool isCompletedOn(dynamic date) {
    if (date is DateTime) {
      return completedDates.contains(formatDateKey(date));
    }
    return completedDates.contains(date.toString());
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
      hasNote: hasNote ?? this.hasNote,
      noteContent: noteContent ?? this.noteContent,
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
