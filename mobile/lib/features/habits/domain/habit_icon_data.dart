import 'package:flutter/material.dart';

class HabitIconInfo {
  final String id;
  final String label;
  final IconData icon;

  const HabitIconInfo({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const List<HabitIconInfo> availableHabitIcons = [
  HabitIconInfo(
    id: 'directions_walk',
    label: 'Walking',
    icon: Icons.directions_walk_rounded,
  ),
  HabitIconInfo(
    id: 'directions_run',
    label: 'Running',
    icon: Icons.directions_run_rounded,
  ),
  HabitIconInfo(
    id: 'fitness_center',
    label: 'Gym',
    icon: Icons.fitness_center_rounded,
  ),
  HabitIconInfo(
    id: 'code',
    label: 'Coding',
    icon: Icons.code_rounded,
  ),
  HabitIconInfo(
    id: 'menu_book',
    label: 'Reading',
    icon: Icons.menu_book_rounded,
  ),
  HabitIconInfo(
    id: 'self_improvement',
    label: 'Meditation',
    icon: Icons.self_improvement_rounded,
  ),
  HabitIconInfo(
    id: 'water_drop',
    label: 'Water',
    icon: Icons.water_drop_rounded,
  ),
  HabitIconInfo(
    id: 'bedtime',
    label: 'Sleep',
    icon: Icons.bedtime_rounded,
  ),
  HabitIconInfo(
    id: 'restaurant',
    label: 'Food',
    icon: Icons.restaurant_rounded,
  ),
  HabitIconInfo(
    id: 'music_note',
    label: 'Music',
    icon: Icons.music_note_rounded,
  ),
  HabitIconInfo(
    id: 'work',
    label: 'Work',
    icon: Icons.work_outline_rounded,
  ),
  HabitIconInfo(
    id: 'school',
    label: 'Study',
    icon: Icons.school_rounded,
  ),
  HabitIconInfo(
    id: 'attach_money',
    label: 'Finance',
    icon: Icons.attach_money_rounded,
  ),
  HabitIconInfo(
    id: 'favorite',
    label: 'Health',
    icon: Icons.favorite_rounded,
  ),
  HabitIconInfo(
    id: 'track_changes',
    label: 'Goal',
    icon: Icons.track_changes_rounded,
  ),
  HabitIconInfo(
    id: 'eco',
    label: 'Nature',
    icon: Icons.eco_rounded,
  ),
  HabitIconInfo(
    id: 'cleaning_services',
    label: 'Cleaning',
    icon: Icons.cleaning_services_rounded,
  ),
  HabitIconInfo(
    id: 'alarm',
    label: 'Routine',
    icon: Icons.alarm_rounded,
  ),
  HabitIconInfo(
    id: 'brush',
    label: 'Creativity',
    icon: Icons.brush_rounded,
  ),
  HabitIconInfo(
    id: 'task_alt',
    label: 'Focus',
    icon: Icons.task_alt_rounded,
  ),
];

IconData getHabitIconData(String? iconId) {
  if (iconId == null || iconId.isEmpty) {
    return Icons.directions_walk_rounded;
  }

  // Handle legacy keys and modern IDs
  switch (iconId.toLowerCase()) {
    case 'walking':
    case 'directions_walk':
      return Icons.directions_walk_rounded;
    case 'running':
    case 'directions_run':
      return Icons.directions_run_rounded;
    case 'workout':
    case 'gym':
    case 'fitness_center':
      return Icons.fitness_center_rounded;
    case 'coding':
    case 'code':
      return Icons.code_rounded;
    case 'reading':
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'meditation':
    case 'self_improvement':
      return Icons.self_improvement_rounded;
    case 'water':
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'sleep':
    case 'bedtime':
      return Icons.bedtime_rounded;
    case 'food':
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'music':
    case 'music_note':
      return Icons.music_note_rounded;
    case 'work':
      return Icons.work_outline_rounded;
    case 'study':
    case 'school':
      return Icons.school_rounded;
    case 'money':
    case 'finance':
    case 'attach_money':
      return Icons.attach_money_rounded;
    case 'health':
    case 'favorite':
      return Icons.favorite_rounded;
    case 'goal':
    case 'track_changes':
      return Icons.track_changes_rounded;
    case 'personal':
    case 'eco':
      return Icons.eco_rounded;
    case 'cleaning':
    case 'cleaning_services':
      return Icons.cleaning_services_rounded;
    case 'alarm':
    case 'timer':
      return Icons.alarm_rounded;
    case 'brush':
    case 'art':
      return Icons.brush_rounded;
    case 'task_alt':
    case 'focus':
      return Icons.task_alt_rounded;
    default:
      return Icons.directions_walk_rounded;
  }
}
