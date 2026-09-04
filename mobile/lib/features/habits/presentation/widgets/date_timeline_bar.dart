import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../domain/streak_calculator.dart';
import '../habit_controller.dart';

class DateTimelineBar extends ConsumerStatefulWidget {
  const DateTimelineBar({super.key});

  @override
  ConsumerState<DateTimelineBar> createState() => _DateTimelineBarState();
}

class _DateTimelineBarState extends ConsumerState<DateTimelineBar> {
  late final ScrollController _scrollController;
  late final List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Generate past 14 days up to today (strictly NO future dates)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _dates = List.generate(
      14,
      (index) => today.subtract(Duration(days: 13 - index)),
    );

    // Auto-scroll to Today at initial render
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
    final selectedDate = ref.watch(selectedDateProvider);
    final shades = ref.watch(appThemeShadesProvider);
    final habits = ref.watch(habitControllerProvider).value ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      height: 94,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, today);

          final dateKey = formatDateKey(date);
          final hasCompletion = habits.any((h) => h.isCompletedOn(dateKey));

          final dayName = isToday ? 'TODAY' : DateFormat('E').format(date).toUpperCase();
          final dayNumber = DateFormat('d').format(date); // 26, 27...

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                ref.read(habitControllerProvider.notifier).changeSelectedDate(date);
              },
              hoverColor: shades.hover,
              splashColor: shades.pressed,
              highlightColor: shades.hover,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 76,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? shades.selected
                        : (isToday
                            ? shades.backgroundTint
                            : AppTheme.getCardColor(context)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? shades.selected
                          : (isToday
                              ? shades.border
                              : AppTheme.getBorderColor(context)),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: shades.primary.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isToday
                                  ? shades.primary
                                  : AppTheme.getTextSecondary(context)),
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppTheme.getTextPrimary(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                      // Indicator dot for completion activity or selection
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white
                              : (hasCompletion
                                  ? shades.primary
                                  : (isToday
                                      ? shades.primary
                                      : Colors.transparent)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
