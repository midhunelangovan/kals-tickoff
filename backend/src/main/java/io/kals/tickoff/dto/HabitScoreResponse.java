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
    private double score;
    private long completed;
    private long total;
    private long expected;
}
