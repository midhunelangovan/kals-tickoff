import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../habits/domain/habit.dart';
import '../../habits/domain/habit_icons_catalog.dart';
import '../../habits/presentation/habit_controller.dart';

class ReorderHabitsScreen extends ConsumerStatefulWidget {
  const ReorderHabitsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReorderHabitsScreen()),
    );
  }

  @override
  ConsumerState<ReorderHabitsScreen> createState() => _ReorderHabitsScreenState();
}

class _ReorderHabitsScreenState extends ConsumerState<ReorderHabitsScreen> {
  List<Habit> _habits = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitControllerProvider);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final cardBg = AppTheme.getCardColor(context);
    final borderColor = AppTheme.getBorderColor(context);

    if (!_initialized && habitsAsync.hasValue) {
      _habits = List.from(habitsAsync.value ?? []);
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reorder Habits',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: _habits.isEmpty
          ? Center(
              child: Text(
                'No habits to reorder',
                style: TextStyle(color: textSecondary, fontSize: 16),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _habits.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _habits.removeAt(oldIndex);
                  _habits.insert(newIndex, item);
                });

                // Persist new ordering immediately
                final ids = _habits.map((h) => h.id).toList();
                ref.read(habitControllerProvider.notifier).reorderHabits(ids);
              },
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final shades = habit.colorShades;
                final habitIconData = getHabitIcon(habit.icon);

                return Container(
                  key: ValueKey(habit.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Reorder Drag Handle
                      ReorderableDragStartListener(
                        index: index,
                        child: Icon(
                          Icons.drag_handle_rounded,
                          color: textSecondary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Habit Icon Badge
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: shades.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            habitIconData,
                            color: shades.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Habit Name
                      Expanded(
                        child: Text(
                          habit.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
