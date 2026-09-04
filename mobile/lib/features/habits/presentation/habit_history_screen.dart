import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../notes/domain/habit_note.dart';
import '../../notes/presentation/daily_note_screen.dart';
import '../domain/habit.dart';
import '../domain/habit_icons_catalog.dart';
import 'habit_controller.dart';
import 'widgets/edit_habit_bottom_sheet.dart';
import 'widgets/streak_heatmap.dart';

class HabitTimelineEvent {
  final DateTime date;
  final String iconEmoji;
  final String title;
  final String? subtitle;

  const HabitTimelineEvent({
    required this.date,
    required this.iconEmoji,
    required this.title,
    this.subtitle,
  });
}

class HabitHistoryScreen extends ConsumerStatefulWidget {
  final Habit habit;

  const HabitHistoryScreen({super.key, required this.habit});

  static Future<void> show(BuildContext context, Habit habit) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HabitHistoryScreen(habit: habit)),
    );
  }

  @override
  ConsumerState<HabitHistoryScreen> createState() => _HabitHistoryScreenState();
}

class _HabitHistoryScreenState extends ConsumerState<HabitHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.habit.selectedDate ?? DateTime.now();
  }

  List<HabitTimelineEvent> _generateTimelineEvents(
    Habit habit,
    List<HabitNote> notes,
  ) {
    final events = <HabitTimelineEvent>[];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final creationDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );

    // 1. Habit Started Event
    events.add(
      HabitTimelineEvent(
        date: creationDate,
        iconEmoji: '🚩',
        title: 'Habit Started',
        subtitle: 'Journey began on ${DateFormat('MMM d, yyyy').format(creationDate)}',
      ),
    );

    // 2. Parse completion dates ascending
    final sortedDates = habit.completedDates
        .map((d) {
          try {
            return DateTime.parse(d);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    // Find continuous streak runs
    if (sortedDates.isNotEmpty) {
      int runLength = 1;
      final milestoneTargets = {3, 7, 14, 30, 50, 100};

      for (int i = 0; i < sortedDates.length; i++) {
        final current = sortedDates[i];
        if (i > 0) {
          final prev = sortedDates[i - 1];
          if (current.difference(prev).inDays == 1) {
            runLength++;
          } else {
            // Previous streak ended
            if (runLength >= 2) {
              final endedDate = prev.add(const Duration(days: 1));
              events.add(
                HabitTimelineEvent(
                  date: endedDate,
                  iconEmoji: '🔥',
                  title: '$runLength day streak ended',
                  subtitle: 'Streak broken after $runLength consecutive days',
                ),
              );
            }
            runLength = 1;
          }
        }

        // Check milestones
        if (milestoneTargets.contains(runLength)) {
          events.add(
            HabitTimelineEvent(
              date: current,
              iconEmoji: '🏆',
              title: '$runLength day streak',
              subtitle: 'Milestone achieved!',
            ),
          );
        }
      }

      // Check current ongoing streak
      final currentStreak = habit.currentStreak;
      if (currentStreak > 0) {
        events.add(
          HabitTimelineEvent(
            date: todayDate,
            iconEmoji: '🔥',
            title: '$currentStreak day ongoing streak',
            subtitle: 'Keep the momentum going!',
          ),
        );
      }
    }

    // 3. Add Notes
    for (final note in notes) {
      if (note.content.isNotEmpty) {
        try {
          final noteDate = DateTime.parse(note.date);
          events.add(
            HabitTimelineEvent(
              date: noteDate,
              iconEmoji: '📝',
              title: 'Daily Note',
              subtitle: note.content,
            ),
          );
        } catch (_) {}
      }
    }

    // Sort newest to oldest
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  int _calculateBestStreak(Set<String> dateStrings) {
    if (dateStrings.isEmpty) return 0;
    final dates = dateStrings
        .map((d) {
          try {
            return DateTime.parse(d);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort((a, b) => a.compareTo(b));

    int best = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else if (dates[i].difference(dates[i - 1]).inDays > 1) {
        current = 1;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    // Watch current state of habits from provider to keep live synced
    final habitsList = ref.watch(habitControllerProvider).value ?? [];
    final habit = habitsList.firstWhere(
      (h) => h.id == widget.habit.id,
      orElse: () => widget.habit,
    );

    final shades = habit.colorShades;
    final habitIconData = getHabitIcon(habit.icon);
    final cardBg = AppTheme.getCardColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final borderColor = AppTheme.getBorderColor(context);

    // Calculate Summary Stats
    final totalCompleted = habit.completedDates.length;
    final bestStreak = _calculateBestStreak(habit.completedDates);

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final creationDate = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final totalEligibleDays = (todayDate.difference(creationDate).inDays + 1).clamp(1, 99999);
    final completionRate = ((totalCompleted / totalEligibleDays) * 100).clamp(0.0, 100.0);

    // Fetch notes if available (from note content in habit or cached)
    final notesList = <HabitNote>[];
    if (habit.noteContent != null && habit.noteContent!.isNotEmpty) {
      notesList.add(
        HabitNote(
          id: 'current',
          habitId: habit.id,
          date: formatDateKey(_selectedDate),
          content: habit.noteContent!,
        ),
      );
    }

    final timelineEvents = _generateTimelineEvents(habit, notesList);

    // Group timeline events by Month & Year (e.g. "September 2026")
    final groupedEvents = <String, List<HabitTimelineEvent>>{};
    for (final ev in timelineEvents) {
      final key = DateFormat('MMMM yyyy').format(ev.date);
      groupedEvents.putIfAbsent(key, () => []).add(ev);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          habit.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textSecondary),
            tooltip: 'Edit Habit',
            onPressed: () => EditHabitBottomSheet.show(context, habit),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ─── 1. Header Hero Card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shades.primary.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: shades.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(habitIconData, color: shades.primary, size: 34),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (habit.description != null && habit.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    habit.description!,
                    style: TextStyle(fontSize: 14, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // 4 Summary Metrics (2x2 Grid)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'CURRENT STREAK',
                        '${habit.currentStreak} days',
                        '🔥',
                        shades.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'BEST STREAK',
                        '$bestStreak days',
                        '🏆',
                        shades.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'TOTAL COMPLETED',
                        '$totalCompleted days',
                        '✓',
                        shades.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        'COMPLETION RATE',
                        '${completionRate.toStringAsFixed(1)}%',
                        '📊',
                        shades.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 2. Heatmap & Daily Note Action ───────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'COMPLETION HISTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    // Add / View Daily Note button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: shades.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      icon: Icon(
                        habit.hasNote ? Icons.description_rounded : Icons.edit_note_rounded,
                        size: 20,
                      ),
                      label: Text(
                        habit.hasNote ? 'View Note' : '+ Add Note',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () => DailyNoteScreen.show(
                        context,
                        habit,
                        _selectedDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreakHeatmap(
                  habit: habit,
                  selectedDate: _selectedDate,
                  onSelectDate: (d) => setState(() => _selectedDate = d),
                  colorShades: shades,
                  weeksCount: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 3. Timeline Events ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'TIMELINE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),

          if (groupedEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No timeline events yet.',
                  style: TextStyle(color: textSecondary),
                ),
              ),
            )
          else
            ...groupedEvents.entries.map((entry) {
              final monthTitle = entry.key;
              final eventsInMonth = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8, bottom: 10),
                    child: Text(
                      monthTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  ...eventsInMonth.map((ev) {
                    final formattedEventDate = DateFormat('d MMM').format(ev.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Emoji Badge
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: shades.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                ev.iconEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Event Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                if (ev.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ev.subtitle!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSecondary,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Date text
                          Text(
                            formattedEventDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    String label,
    String value,
    String icon,
    Color accentColor,
  ) {
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.getBorderColor(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
