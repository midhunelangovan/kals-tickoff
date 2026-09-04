package io.kals.tickoff.mapper;

import io.kals.tickoff.dto.CompletionResponse;
import io.kals.tickoff.dto.HabitResponse;
import io.kals.tickoff.entity.Habit;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.Collections;
import java.util.List;

@Component
public class HabitMapper {

    public HabitResponse toCreatedResponse(Habit habit, int currentStreak, boolean completedToday) {
        return HabitResponse.builder()
                .id(habit.getId())
                .habitId(habit.getId())
                .name(habit.getName())
                .icon(habit.getIcon())
                .description(habit.getDescription())
                .color(habit.getColor())
                .createdAt(habit.getCreatedAt())
                .archived(habit.isArchived())
                .sortOrder(habit.getSortOrder() != null ? habit.getSortOrder() : 0)
                .currentStreak(currentStreak)
                .completedToday(completedToday)
                .completedOnDate(completedToday)
                .completedOnSelectedDate(completedToday)
                .completions(Collections.emptyList())
                .hasNote(false)
                .noteContent(null)
                .build();
    }

    public HabitResponse toListResponse(
            Habit habit,
            LocalDate selectedDate,
            int currentStreak,
            boolean completedOnSelectedDate,
            List<LocalDate> completions,
            boolean hasNote,
            String noteContent
    ) {
        return HabitResponse.builder()
                .id(habit.getId())
                .habitId(habit.getId())
                .name(habit.getName())
                .icon(habit.getIcon())
                .description(habit.getDescription())
                .color(habit.getColor())
                .createdAt(habit.getCreatedAt())
                .archived(habit.isArchived())
                .sortOrder(habit.getSortOrder() != null ? habit.getSortOrder() : 0)
                .selectedDate(selectedDate)
                .currentStreak(currentStreak)
                .completedOnDate(completedOnSelectedDate)
                .completedOnSelectedDate(completedOnSelectedDate)
                .completions(completions)
                .hasNote(hasNote)
                .noteContent(noteContent)
                .build();
    }

    public CompletionResponse toCompletionResponse(
            String habitId,
            LocalDate completionDate,
            boolean completed,
            int currentStreak,
            List<LocalDate> completions
    ) {
        return CompletionResponse.builder()
                .habitId(habitId)
                .completionDate(completionDate)
                .completed(completed)
                .currentStreak(currentStreak)
                .completions(completions)
                .build();
    }
}
