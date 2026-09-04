package io.kals.tickoff.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class HabitResponse {

    private String id;
    private String habitId;
    private String name;
    private String icon;
    private String description;
    private String color;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    private boolean archived;
    @Builder.Default
    private Integer sortOrder = 0;
    private int currentStreak;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate selectedDate;

    private Boolean completedOnSelectedDate;
    private Boolean completedOnDate;
    private Boolean completedToday;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private List<LocalDate> completions;

    private Boolean hasNote;
    private String noteContent;
}
