package io.kals.tickoff.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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
public class CreateHabitRequest {

    @NotBlank(message = "Habit name cannot be blank")
    @Size(min = 1, max = 100, message = "Habit name must be between 1 and 100 characters")
    private String name;

    @Size(max = 50, message = "Habit icon identifier must be at most 50 characters")
    private String icon;

    @Size(max = 255, message = "Description must be at most 255 characters")
    private String description;

    @Size(max = 50, message = "Color must be at most 50 characters")
    private String color;

    public CreateHabitRequest(String name) {
        this.name = name;
        this.icon = "bolt";
        this.description = null;
        this.color = "#7C3AED";
    }
}
