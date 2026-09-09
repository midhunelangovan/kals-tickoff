package io.kals.tickoff.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HabitScoreResponse {
    private String date;
    private String startDate;
    private String endDate;
    private double score;
    private long completed;
    private long total;
    private long expected;
    private Long dailyCompleted;
    private Long dailyTotal;
    private Long habitDaysCompleted;
    private Long habitDaysTotal;
    private Long habitsCount;
}
