import 'package:flutter/material.dart';

class HabitIconItem {
  final String id;
  final String label;
  final String emoji;
  final IconData iconData;

  const HabitIconItem({
    required this.id,
    required this.label,
    required this.emoji,
    required this.iconData,
  });
}

const List<HabitIconItem> predefinedHabitIcons = [
  HabitIconItem(
    id: 'walking',
    label: 'Walking',
    emoji: '🚶',
    iconData: Icons.directions_walk_rounded,
  ),
  HabitIconItem(
    id: 'coding',
    label: 'Coding',
    emoji: '💻',
    iconData: Icons.laptop_chromebook_rounded,
  ),
  HabitIconItem(
    id: 'reading',
    label: 'Reading',
    emoji: '📚',
    iconData: Icons.menu_book_rounded,
  ),
  HabitIconItem(
    id: 'workout',
    label: 'Workout',
    emoji: '🏋',
    iconData: Icons.fitness_center_rounded,
  ),
  HabitIconItem(
    id: 'water',
    label: 'Water',
    emoji: '💧',
    iconData: Icons.water_drop_rounded,
  ),
  HabitIconItem(
    id: 'meditation',
    label: 'Meditation',
    emoji: '🧘',
    iconData: Icons.self_improvement_rounded,
  ),
  HabitIconItem(
    id: 'writing',
    label: 'Writing',
    emoji: '📝',
    iconData: Icons.edit_note_rounded,
  ),
  HabitIconItem(
    id: 'goal',
    label: 'Goal',
    emoji: '🎯',
    iconData: Icons.track_changes_rounded,
  ),
  HabitIconItem(
    id: 'health',
    label: 'Health',
    emoji: '❤️',
    iconData: Icons.favorite_rounded,
  ),
  HabitIconItem(
    id: 'personal',
    label: 'Personal',
    emoji: '🌱',
    iconData: Icons.eco_rounded,
  ),
];

HabitIconItem getHabitIcon(String? iconId) {
  if (iconId == null || iconId.isEmpty) {
    return predefinedHabitIcons.first;
  }
  return predefinedHabitIcons.firstWhere(
    (item) => item.id.toLowerCase() == iconId.toLowerCase(),
    orElse: () => predefinedHabitIcons.first,
  );
}
