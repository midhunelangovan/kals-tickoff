package io.kals.tickoff.service;

import io.kals.tickoff.repository.HabitCompletionRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StreakServiceTest {

    @Mock
    private HabitCompletionRepository completionRepository;

    private StreakService streakService;

    @BeforeEach
    void setUp() {
        streakService = new StreakService(completionRepository);
    }

    @Test
    @DisplayName("Case 1: Today ✓, Yesterday ✓, 2 days ago ✓ -> Current streak = 3")
    void testCase1_todayCompleted_yesterdayCompleted_2daysAgoCompleted() {
        LocalDate today = LocalDate.of(2026, 9, 1);
        Set<LocalDate> completedDates = Set.of(
                today,
                today.minusDays(1),
                today.minusDays(2)
        );

        int streak = streakService.calculateStreakFromDateSet(completedDates, today);
        assertThat(streak).isEqualTo(3);
    }

    @Test
    @DisplayName("Case 2: Today ✗, Yesterday ✓, 2 days ago ✓ -> Current streak = 2")
    void testCase2_todayNotCompleted_yesterdayCompleted_2daysAgoCompleted() {
        LocalDate today = LocalDate.of(2026, 9, 1);
        Set<LocalDate> completedDates = Set.of(
                today.minusDays(1),
                today.minusDays(2)
        );

        int streak = streakService.calculateStreakFromDateSet(completedDates, today);
        assertThat(streak).isEqualTo(2);
    }

    @Test
    @DisplayName("Case 3: Today ✗, Yesterday ✗, 2 days ago ✓, 3 days ago ✓ -> Current streak = 0")
    void testCase3_todayNotCompleted_yesterdayNotCompleted_2daysAgoCompleted() {
        LocalDate today = LocalDate.of(2026, 9, 1);
        Set<LocalDate> completedDates = Set.of(
                today.minusDays(2),
                today.minusDays(3)
        );

        int streak = streakService.calculateStreakFromDateSet(completedDates, today);
        assertThat(streak).isEqualTo(0);
    }

    @Test
    @DisplayName("Case 4: Today ✓, Yesterday ✗, 2 days ago ✓ -> Current streak = 1")
    void testCase4_todayCompleted_yesterdayMissed_2daysAgoCompleted() {
        LocalDate today = LocalDate.of(2026, 9, 1);
        Set<LocalDate> completedDates = Set.of(
                today,
                today.minusDays(2)
        );

        int streak = streakService.calculateStreakFromDateSet(completedDates, today);
        assertThat(streak).isEqualTo(1);
    }

    @Test
    @DisplayName("Case 5: Repository integration with streak relative to today")
    void testCase5_repositoryQueryRelativeToday() {
        String habitId = "habit-123";
        LocalDate today = LocalDate.of(2026, 9, 1);

        when(completionRepository.findCompletionDatesByHabitIdAndDateLessThanEqual(habitId, today))
                .thenReturn(List.of(today, today.minusDays(1), today.minusDays(2), today.minusDays(3)));

        int streak = streakService.calculateCurrentStreak(habitId, today);
        assertThat(streak).isEqualTo(4);
    }

    @Test
    @DisplayName("Handles null and empty dates gracefully")
    void testNullAndEmptyHandling() {
        assertThat(streakService.calculateStreakFromDateSet(Set.of(), LocalDate.now())).isEqualTo(0);
        assertThat(streakService.calculateStreakFromDateSet(null, LocalDate.now())).isEqualTo(0);
        assertThat(streakService.calculateStreakFromDateSet(Set.of(LocalDate.now()), null)).isEqualTo(0);
    }
}
