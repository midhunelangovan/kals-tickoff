import '../domain/habit.dart';

class HabitDto {
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
  final List<String> completions;
  final int sortOrder;
  final bool hasNote;
  final String? noteContent;

  HabitDto({
    required this.id,
    required this.name,
    this.icon = 'bolt',
    this.description,
    this.color,
    required this.createdAt,
    required this.archived,
    required this.completed,
    required this.currentStreak,
    this.selectedDate,
    this.completions = const [],
    this.sortOrder = 0,
    this.hasNote = false,
    this.noteContent,
  });

  factory HabitDto.fromJson(Map<String, dynamic> json) {
    final isCompleted =
        (json['completedOnSelectedDate'] as bool?) ??
        (json['completedOnDate'] as bool?) ??
        (json['completedToday'] as bool?) ??
        (json['completed'] as bool?) ??
        false;

    DateTime parsedCreatedAt;
    if (json['createdAt'] != null) {
      try {
        parsedCreatedAt = DateTime.parse(json['createdAt'] as String);
      } catch (_) {
        parsedCreatedAt = DateTime.now();
      }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    DateTime? parsedSelectedDate;
    if (json['selectedDate'] != null) {
      try {
        parsedSelectedDate = DateTime.parse(json['selectedDate'] as String);
      } catch (_) {
        parsedSelectedDate = null;
      }
    }

    List<String> parsedCompletions = [];
    if (json['completions'] is List) {
      parsedCompletions = (json['completions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    final habitId =
        (json['id'] as String?) ?? (json['habitId'] as String?) ?? '';

    return HabitDto(
      id: habitId,
      name: (json['name'] as String?) ?? '',
      icon: (json['icon'] as String?) ?? 'bolt',
      description: json['description'] as String?,
      color: json['color'] as String?,
      createdAt: parsedCreatedAt,
      archived: (json['archived'] as bool?) ?? false,
      completed: isCompleted,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      selectedDate: parsedSelectedDate,
      completions: parsedCompletions,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      hasNote: (json['hasNote'] as bool?) ?? false,
      noteContent: json['noteContent'] as String?,
    );
  }

  Habit toDomain() {
    return Habit(
      id: id,
      name: name,
      icon: icon,
      description: description,
      color: color,
      createdAt: createdAt,
      archived: archived,
      completed: completed,
      currentStreak: currentStreak,
      selectedDate: selectedDate,
      completedDates: completions.toSet(),
      sortOrder: sortOrder,
      hasNote: hasNote,
      noteContent: noteContent,
    );
  }
}

class CreateHabitRequestDto {
  final String name;
  final String icon;
  final String? description;
  final String? color;

  CreateHabitRequestDto({
    required this.name,
    this.icon = 'bolt',
    this.description,
    this.color,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'icon': icon,
    };
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (color != null && color!.isNotEmpty) {
      map['color'] = color;
    }
    return map;
  }
}

class UpdateHabitRequestDto {
  final String name;
  final String icon;
  final String? description;
  final String? color;

  UpdateHabitRequestDto({
    required this.name,
    required this.icon,
    this.description,
    this.color,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'icon': icon,
    };
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (color != null && color!.isNotEmpty) {
      map['color'] = color;
    }
    return map;
  }
}

class CompletionResponseDto {
  final String habitId;
  final String completionDate;
  final bool completed;
  final int currentStreak;
  final List<String> completions;

  CompletionResponseDto({
    required this.habitId,
    required this.completionDate,
    required this.completed,
    required this.currentStreak,
    this.completions = const [],
  });

  factory CompletionResponseDto.fromJson(Map<String, dynamic> json) {
    List<String> parsedCompletions = [];
    if (json['completions'] is List) {
      parsedCompletions = (json['completions'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return CompletionResponseDto(
      habitId: (json['habitId'] as String?) ?? (json['id'] as String?) ?? '',
      completionDate: (json['completionDate'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      completions: parsedCompletions,
    );
  }
}
