import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../app/theme_controller.dart';
import '../domain/habit.dart';
import 'habit_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import 'habit_history_screen.dart';
import 'widgets/add_habit_bottom_sheet.dart';
import 'widgets/completion_celebration_overlay.dart';
import 'widgets/date_selector_strip.dart';
import 'widgets/empty_habits_state.dart';
import 'widgets/habit_card.dart';
import 'widgets/progress_summary.dart';

class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  bool _isReorderMode = false;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatHeaderDate(DateTime selectedDate) {
    final today = DateTime.now();
    if (_isSameDay(selectedDate, today)) {
      return 'Today';
    } else if (_isSameDay(
      selectedDate,
      today.subtract(const Duration(days: 1)),
    )) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMM d').format(selectedDate);
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    WidgetRef ref,
    List<Habit> allHabits,
    Set<String> selectedIds,
  ) async {
    if (selectedIds.isEmpty) return;

    final selectedHabits =
        allHabits.where((h) => selectedIds.contains(h.id)).toList();
    final habitName = selectedHabits.length == 1
        ? "'${selectedHabits.first.name}'"
        : '${selectedHabits.length} habits';

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete habit?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          content: Text(
            "Delete $habitName and all of its completion history?",
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && context.mounted) {
      try {
        for (final habit in selectedHabits) {
          await ref.read(habitControllerProvider.notifier).deleteHabit(habit.id);
        }
        ref.read(selectedHabitIdsProvider.notifier).clear();
      } catch (e) {
        if (context.mounted) {
          String message = 'Unable to delete habit. Please try again.';
          if (e is DioException && e.response?.statusCode == 404) {
            message = 'Habit not found.';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitControllerProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedHabitIds = ref.watch(selectedHabitIdsProvider);
    final isSelectionMode = selectedHabitIds.isNotEmpty;

    final headerTitle = _formatHeaderDate(selectedDate);
    final formattedFullDate = DateFormat('MMMM d, yyyy').format(selectedDate);
    final shades = ref.watch(appThemeShadesProvider);

    final habitsList = habitsAsync.value ?? [];

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldBackground(context),
      appBar: isSelectionMode
          ? AppBar(
              toolbarHeight: 70,
              backgroundColor: shades.backgroundTint,
              leading: IconButton(
                icon: Icon(Icons.close_rounded, color: shades.primaryDark),
                onPressed: () {
                  ref.read(selectedHabitIdsProvider.notifier).clear();
                },
              ),
              title: Text(
                '${selectedHabitIds.length} selected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: shades.primaryDark,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  tooltip: 'Delete',
                  onPressed: () {
                    _confirmDeleteSelected(
                      context,
                      ref,
                      habitsList,
                      selectedHabitIds,
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            )
          : _isReorderMode
              ? AppBar(
                  toolbarHeight: 76,
                  title: Text(
                    'Reorder Habits',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.getTextPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  actions: [
                    TextButton.icon(
                      onPressed: () => setState(() => _isReorderMode = false),
                      icon: Icon(Icons.check_rounded, color: shades.primary, size: 22),
                      label: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: shades.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : AppBar(
                  toolbarHeight: 76,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        headerTitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.getTextPrimary(context),
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedFullDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.swap_vert_rounded,
                        color: AppTheme.getTextSecondary(context),
                        size: 26,
                      ),
                      tooltip: 'Reorder habits',
                      onPressed: () => setState(() => _isReorderMode = true),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: AppTheme.getTextSecondary(context),
                        size: 26,
                      ),
                      tooltip: 'Settings',
                      onPressed: () => SettingsScreen.show(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. Date Navigation Strip
              const DateSelectorStrip(),

          // 2. Habits Content
          Expanded(
            child: habitsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Unable to load habits',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please check that the local backend server is running.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref
                            .read(habitControllerProvider.notifier)
                            .loadHabits(),
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (habits) {
                if (habits.isEmpty) {
                  return RefreshIndicator(
                    color: shades.primary,
                    onRefresh: () => ref
                        .read(habitControllerProvider.notifier)
                        .loadHabits(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.55,
                          child: EmptyHabitsState(
                            onAddHabit: () => AddHabitBottomSheet.show(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isReorderMode) {
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    header: const ProgressSummary(),
                    itemCount: habits.length,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final mutableList = List<Habit>.from(habits);
                      final item = mutableList.removeAt(oldIndex);
                      mutableList.insert(newIndex, item);
                      final ids = mutableList.map((h) => h.id).toList();
                      ref.read(habitControllerProvider.notifier).reorderHabits(ids);
                    },
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      return HabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        selectedDate: selectedDate,
                        isSelected: false,
                        isSelectionMode: false,
                        isReordering: true,
                        reorderIndex: index,
                        onSelectDate: null,
                        onTap: null,
                        onLongPress: null,
                        onToggle: () {},
                      );
                    },
                  );
                }

                return RefreshIndicator(
                  color: shades.primary,
                  onRefresh: () => ref
                      .read(habitControllerProvider.notifier)
                      .loadHabits(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96, top: 4),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: habits.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const ProgressSummary();
                      }

                      final habit = habits[index - 1];
                      final isCardSelected = selectedHabitIds.contains(habit.id);

                      return HabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        selectedDate: selectedDate,
                        isSelected: isCardSelected,
                        isSelectionMode: isSelectionMode,
                        onSelectDate: (date) {
                          ref
                              .read(habitControllerProvider.notifier)
                              .changeSelectedDate(date);
                        },
                        onTap: () {
                          if (isSelectionMode) {
                            ref
                                .read(selectedHabitIdsProvider.notifier)
                                .toggle(habit.id);
                          } else {
                            HabitHistoryScreen.show(context, habit);
                          }
                        },
                        onLongPress: () {
                          ref
                              .read(selectedHabitIdsProvider.notifier)
                              .select(habit.id);
                        },
                        onToggle: () async {
                          try {
                            await ref
                                .read(habitControllerProvider.notifier)
                                .toggleCompletion(habit);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update "${habit.name}". Reverted.',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 3. Screen-Level Bottom-Center Completion Celebration Overlay
      const Positioned(
        left: 0,
        right: 0,
        bottom: 24,
        child: IgnorePointer(
          child: Center(
            child: CompletionCelebrationOverlay(),
          ),
        ),
      ),
    ],
  ),
      floatingActionButton: (isSelectionMode || _isReorderMode)
          ? null
          : FloatingActionButton.extended(
              onPressed: () => AddHabitBottomSheet.show(context),
              backgroundColor: shades.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                'New habit',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
    );
  }
}
