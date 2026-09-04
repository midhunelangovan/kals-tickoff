package io.kals.tickoff.local.service

import io.kals.tickoff.local.repository.HabitSqliteRepository
import java.time.LocalDate

class StreakService(private val repository: HabitSqliteRepository) {

    /**
     * Calculates the current streak for a single habit relative to today.
     * Rules:
     * 1. If today is completed: count consecutive completed days backwards starting from today.
     * 2. If today is NOT completed: allow streak to continue from yesterday if yesterday is completed.
     * 3. If neither today nor yesterday is completed: current streak is 0.
     */
    fun calculateCurrentStreak(habitId: String?, today: LocalDate?): Int {
        if (habitId == null || today == null) {
            return 0
        }

        val completedDatesList = repository
            .findCompletionDatesByHabitIdAndDateLessThanEqual(habitId, today)

        val completedDates = completedDatesList.toSet()
        return calculateStreakFromDateSet(completedDates, today)
    }

    /**
     * Pure function to calculate current streak given completed dates and today's date.
     */
    fun calculateStreakFromDateSet(completedDates: Set<LocalDate>?, today: LocalDate?): Int {
        if (completedDates == null || today == null || completedDates.isEmpty()) {
            return 0
        }

        val startDate: LocalDate = when {
            completedDates.contains(today) -> today
            completedDates.contains(today.minusDays(1)) -> today.minusDays(1)
            else -> return 0
        }

        var streak = 0
        var checkDate = startDate

        while (completedDates.contains(checkDate)) {
            streak++
            checkDate = checkDate.minusDays(1)
        }

        return streak
    }
}
