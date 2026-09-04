import 'package:flutter/material.dart';
import '../../domain/habit.dart';
import '../../domain/habit_color_palette.dart';

class StreakHeatmap extends StatefulWidget {
  final Habit habit;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onSelectDate;
  final int weeksCount;
  final HabitColorShades? colorShades;

  const StreakHeatmap({
    super.key,
    required this.habit,
    required this.selectedDate,
    this.onSelectDate,
    this.weeksCount = 12,
    this.colorShades,
  });

  @override
  State<StreakHeatmap> createState() => _StreakHeatmapState();
}

class _StreakHeatmapState extends State<StreakHeatmap> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shades = widget.colorShades ?? widget.habit.colorShades;

    // Current week's Sunday (Sunday = 0 in our 0..6 mapping)
    final currentWeekSunday = today.subtract(Duration(days: today.weekday % 7));
    // Start date is (weeksCount - 1) weeks before current week's Sunday
    final startDate = currentWeekSunday.subtract(Duration(days: (widget.weeksCount - 1) * 7));

    const cellSpacing = 3.5;

    // Build list of columns (each column is a week)
    final weeks = List.generate(widget.weeksCount, (colIndex) {
      final weekSunday = startDate.add(Duration(days: colIndex * 7));
      return List.generate(7, (rowIndex) {
        return weekSunday.add(Duration(days: rowIndex));
      });
    });

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weeks.map((weekDays) {
          return Padding(
            padding: const EdgeInsets.only(right: cellSpacing),
            child: Column(
              children: weekDays.map((date) {
                final isFuture = date.isAfter(today);
                final isToday = _isSameDay(date, today);
                final isSelected = _isSameDay(date, widget.selectedDate);
                final isCompleted = !isFuture && widget.habit.isCompletedOn(date);

                return Padding(
                  padding: const EdgeInsets.only(bottom: cellSpacing),
                  child: _HeatmapCell(
                    date: date,
                    isFuture: isFuture,
                    isToday: isToday,
                    isSelected: isSelected,
                    isCompleted: isCompleted,
                    shades: shades,
                    onTap: isFuture ? null : () => widget.onSelectDate?.call(date),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HeatmapCell extends StatefulWidget {
  final DateTime date;
  final bool isFuture;
  final bool isToday;
  final bool isSelected;
  final bool isCompleted;
  final HabitColorShades shades;
  final VoidCallback? onTap;

  const _HeatmapCell({
    required this.date,
    required this.isFuture,
    required this.isToday,
    required this.isSelected,
    required this.isCompleted,
    required this.shades,
    this.onTap,
  });

  @override
  State<_HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<_HeatmapCell> {
  bool _isHovered = false;
  bool _isPressed = false;

  static const double cellSize = 13.0;
  static const double cellRadius = 3.0;
  static const double borderWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isFuture) {
      return SizedBox(
        width: cellSize,
        height: cellSize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(cellRadius),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: borderWidth,
            ),
          ),
        ),
      );
    }

    final shades = widget.shades;

    Color cellColor;
    Color borderColor;

    if (widget.isCompleted) {
      if (_isPressed) {
        cellColor = shades.pressed;
      } else if (_isHovered) {
        cellColor = shades.hover;
      } else {
        cellColor = shades.completed;
      }

      if (widget.isSelected) {
        borderColor = isDark ? Colors.white : const Color(0xFF0F172A);
      } else if (widget.isToday) {
        borderColor = isDark ? Colors.white70 : const Color(0xFF334155);
      } else {
        borderColor = shades.completed;
      }
    } else {
      // Incomplete day
      if (_isPressed) {
        cellColor = shades.pressed;
      } else if (_isHovered) {
        cellColor = shades.hover;
      } else {
        cellColor = shades.lightBackground;
      }

      if (widget.isSelected) {
        borderColor = shades.selected;
      } else if (widget.isToday) {
        borderColor = shades.primary;
      } else if (_isHovered) {
        borderColor = shades.primary;
      } else {
        borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
      }
    }

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: InkWell(
          hoverColor: shades.hover,
          splashColor: shades.pressed,
          highlightColor: shades.pressed,
          borderRadius: BorderRadius.circular(cellRadius),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(cellRadius),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
