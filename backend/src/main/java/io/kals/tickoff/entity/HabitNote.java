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
        name = "habit_notes",
        uniqueConstraints = @UniqueConstraint(
                name = "uq_habit_note_date",
                columnNames = {"habit_id", "note_date"}
        )
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HabitNote {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @Column(name = "habit_id", length = 36, nullable = false)
    private String habitId;

    @Column(name = "note_date", nullable = false)
    private LocalDate noteDate;

    @Column(name = "content", nullable = false, columnDefinition = "TEXT")
    private String content;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public static HabitNote create(String habitId, LocalDate date, String content) {
        LocalDateTime now = LocalDateTime.now();
        return HabitNote.builder()
                .id(UUID.randomUUID().toString())
                .habitId(habitId)
                .noteDate(date)
                .content(content != null ? content.trim() : "")
                .createdAt(now)
                .updatedAt(now)
                .build();
    }
}
