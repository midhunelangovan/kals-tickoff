import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../../notes/presentation/daily_note_screen.dart';
import '../../domain/habit.dart';
import '../../domain/habit_icons_catalog.dart';
import 'completion_celebration_overlay.dart';
import 'streak_heatmap.dart';

class HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final ValueChanged<DateTime>? onSelectDate;
  final bool isSelected;
  final bool isSelectionMode;
  final DateTime selectedDate;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    this.onLongPress,
    this.onTap,
    this.onSelectDate,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.selectedDate,
  });

  @override
  ConsumerState<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _buttonAnimController;
  late final Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();
    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _buttonScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
    ]).animate(_buttonAnimController);
  }

  @override
  void dispose() {
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final animationEnabled = ref.read(tickAnimationEnabledProvider);
    final willComplete = !widget.habit.completed;

    // 1. Immediately trigger state update and database persistence (0ms)
    widget.onToggle();

    // 2. Animate button bounce & trigger screen-level bottom-center celebration
    if (animationEnabled && willComplete) {
      _buttonAnimController.forward(from: 0.0);
      ref.read(completionCelebrationProvider.notifier).trigger(
            CompletionCelebrationState(
              habitId: widget.habit.id,
              habitName: widget.habit.name,
              habitColor: widget.habit.colorShades.primary,
              triggerKey: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } else {
      _buttonAnimController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final isSelected = widget.isSelected;
    final isSelectionMode = widget.isSelectionMode;
    final shades = habit.colorShades;
    final habitIconData = getHabitIcon(habit.icon);
    final streakDays = habit.currentStreak;
    final streakLabel = streakDays == 1 ? '1 day' : '$streakDays days';
    final streakText = 'Streak: $streakLabel';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isSelected
        ? shades.lightBackground
        : (isDark ? AppTheme.darkCardColor : AppTheme.cardColor);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final defaultBorder = AppTheme.getBorderColor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? shades.selected
              : (habit.completed ? shades.border : defaultBorder),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? shades.primary.withValues(alpha: 0.12)
                : (habit.completed
                    ? shades.primary.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02)),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          hoverColor: shades.hover.withValues(alpha: 0.08),
          splashColor: shades.pressed.withValues(alpha: 0.12),
          highlightColor: shades.hover.withValues(alpha: 0.06),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: [Selection Check/Icon] + Habit Name + Streak + Note Button + [Complete Button]
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Selection checkbox indicator when in selection mode
                    if (isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? shades.selected : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? shades.selected : textSecondary,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],

                    // Habit Icon Badge (styled with habit's specific color)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: shades.lightBackground,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Icon(
                          habitIconData,
                          color: shades.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Habit Name & Streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            streakText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: streakDays > 0 ? shades.text : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right action area
                    if (!isSelectionMode) ...[
                      // Small Daily Note button with note indicator 📝
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        icon: habit.hasNote
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: shades.lightBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: shades.border, width: 1),
                                ),
                                child: const Text(
                                  '📝',
                                  style: TextStyle(fontSize: 15),
                                ),
                              )
                            : Icon(
                                Icons.edit_note_rounded,
                                color: textSecondary.withValues(alpha: 0.65),
                                size: 24,
                              ),
                        tooltip: habit.hasNote ? 'View Note' : 'Add Note',
                        onPressed: () => DailyNoteScreen.show(
                          context,
                          habit,
                          widget.selectedDate,
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Completion Button (tactile bounce, no particles attached)
                      GestureDetector(
                        onTap: _handleToggle,
                        child: AnimatedBuilder(
                          animation: _buttonScaleAnim,
                          builder: (context, child) {
                            final scale = _buttonAnimController.isAnimating
                                ? _buttonScaleAnim.value
                                : 1.0;
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: habit.completed
                                  ? shades.completed
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: habit.completed
                                    ? shades.completed
                                    : (isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1)),
                                width: 1.8,
                              ),
                            ),
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: habit.completed ? 1.0 : 0.0,
                                curve: Curves.easeOutBack,
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom: 12-Week Heatmap with habit color shades
                StreakHeatmap(
                  habit: habit,
                  selectedDate: widget.selectedDate,
                  onSelectDate: widget.onSelectDate,
                  colorShades: shades,
                  weeksCount: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
