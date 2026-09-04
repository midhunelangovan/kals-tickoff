package io.kals.tickoff.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "habits")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Habit {

    @Id
    @Column(name = "id", length = 36, nullable = false)
    private String id;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "icon", length = 50, nullable = false)
    @Builder.Default
    private String icon = "walking";

    @Column(name = "category_id", length = 36, nullable = true)
    private String categoryId;

    @Column(name = "description", length = 255, nullable = true)
    private String description;

    @Column(name = "color", length = 50, nullable = false)
    @Builder.Default
    private String color = "#7C3AED";

    @Column(name = "archived", nullable = false)
    @Builder.Default
    private boolean archived = false;

    @Column(name = "sort_order", nullable = false)
    @Builder.Default
    private Integer sortOrder = 0;

    public static Habit create(String name) {
        return create(name, "walking", null, null, null);
    }

    public static Habit create(String name, String icon) {
        return create(name, icon, null, null, null);
    }

    public static Habit create(String name, String icon, String categoryId, String description, String color) {
        String effectiveIcon = (icon != null && !icon.isBlank()) ? icon.trim() : "walking";
        String effectiveColor = (color != null && !color.isBlank()) ? color.trim() : "#7C3AED";
        return Habit.builder()
                .id(UUID.randomUUID().toString())
                .name(name)
                .icon(effectiveIcon)
                .categoryId((categoryId != null && !categoryId.isBlank()) ? categoryId.trim() : null)
                .description((description != null && !description.isBlank()) ? description.trim() : null)
                .color(effectiveColor)
                .createdAt(LocalDateTime.now())
                .archived(false)
                .build();
    }
}
