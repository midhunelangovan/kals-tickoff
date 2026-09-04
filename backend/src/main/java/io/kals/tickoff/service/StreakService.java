package io.kals.tickoff.service;

import io.kals.tickoff.repository.HabitCompletionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class StreakService {

    private final HabitCompletionRepository completionRepository;

    /**
     * Calculates the current streak for a single habit relative to today.
     * Rules:
     * 1. If today is completed: count consecutive completed days backwards starting from today.
     * 2. If today is NOT completed: allow streak to continue from yesterday if yesterday is completed.
     * 3. If neither today nor yesterday is completed: current streak is 0.
     */
    public int calculateCurrentStreak(String habitId, LocalDate today) {
        if (habitId == null || today == null) {
            return 0;
        }

        List<LocalDate> completedDatesList = completionRepository
                .findCompletionDatesByHabitIdAndDateLessThanEqual(habitId, today);

        Set<LocalDate> completedDates = new HashSet<>(completedDatesList);
        return calculateStreakFromDateSet(completedDates, today);
    }

    /**
     * Pure function to calculate current streak given completed dates and today's date.
     */
    public int calculateStreakFromDateSet(Set<LocalDate> completedDates, LocalDate today) {
        if (completedDates == null || today == null || completedDates.isEmpty()) {
            return 0;
        }

        LocalDate startDate;
        if (completedDates.contains(today)) {
            startDate = today;
        } else if (completedDates.contains(today.minusDays(1))) {
            startDate = today.minusDays(1);
        } else {
            return 0;
        }

        int streak = 0;
        LocalDate checkDate = startDate;

        while (completedDates.contains(checkDate)) {
            streak++;
            checkDate = checkDate.minusDays(1);
        }

        return streak;
    }
}
