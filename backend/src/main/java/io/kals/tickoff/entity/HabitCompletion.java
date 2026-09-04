package io.kals.tickoff.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(
        name = "habit_completions",
        uniqueConstraints = @UniqueConstraint(name = "uq_habit_completion_date", columnNames = {"habit_id", "completion_date"})
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HabitCompletion {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @Column(name = "habit_id", length = 36, nullable = false)
    private String habitId;

    @Column(name = "completion_date", nullable = false)
    private LocalDate completionDate;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    public static HabitCompletion create(String habitId, LocalDate completionDate) {
        return HabitCompletion.builder()
                .id(UUID.randomUUID().toString())
                .habitId(habitId)
                .completionDate(completionDate)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
