package io.kals.tickoff.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.kals.core.exception.Exceptions.ResourceNotFoundException;
import io.kals.tickoff.dto.CompletionResponse;
import io.kals.tickoff.dto.CreateHabitRequest;
import io.kals.tickoff.dto.HabitResponse;
import io.kals.tickoff.service.HabitService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(
        controllers = HabitController.class,
        excludeFilters = @ComponentScan.Filter(type = FilterType.ANNOTATION, classes = Service.class)
)
class HabitControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private HabitService habitService;

    @Test
    @DisplayName("POST /habits - Successfully creates a habit with icon")
    void createHabitSuccess() throws Exception {
        CreateHabitRequest request = new CreateHabitRequest("Read for 20 minutes");
        request.setIcon("reading");
        HabitResponse response = HabitResponse.builder()
                .id("test-id-123")
                .name("Read for 20 minutes")
                .icon("reading")
                .createdAt(LocalDateTime.of(2026, 9, 1, 10, 30, 0))
                .archived(false)
                .currentStreak(0)
                .completedToday(false)
                .build();

        when(habitService.createHabit(any(CreateHabitRequest.class))).thenReturn(response);

        mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value("test-id-123"))
                .andExpect(jsonPath("$.name").value("Read for 20 minutes"))
                .andExpect(jsonPath("$.icon").value("reading"))
                .andExpect(jsonPath("$.archived").value(false))
                .andExpect(jsonPath("$.currentStreak").value(0))
                .andExpect(jsonPath("$.completedToday").value(false));
    }

    @Test
    @DisplayName("POST /habits - Reject blank name with 400")
    void createHabitBlankName() throws Exception {
        CreateHabitRequest request = new CreateHabitRequest("   ");

        mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("POST /habits - Reject oversized name with 400")
    void createHabitOversizedName() throws Exception {
        String longName = "A".repeat(101);
        CreateHabitRequest request = new CreateHabitRequest(longName);

        mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("GET /habits - List habits returns 200 OK")
    void listHabitsSuccess() throws Exception {
        HabitResponse item = HabitResponse.builder()
                .id("test-id-123")
                .name("Read for 20 minutes")
                .icon("reading")
                .createdAt(LocalDateTime.of(2026, 9, 1, 10, 30, 0))
                .archived(false)
                .currentStreak(5)
                .completedOnDate(true)
                .build();

        when(habitService.listHabits(eq(LocalDate.of(2026, 9, 1)))).thenReturn(List.of(item));

        mockMvc.perform(get("/habits?date=2026-09-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value("test-id-123"))
                .andExpect(jsonPath("$[0].name").value("Read for 20 minutes"))
                .andExpect(jsonPath("$[0].icon").value("reading"))
                .andExpect(jsonPath("$[0].completedOnDate").value(true))
                .andExpect(jsonPath("$[0].currentStreak").value(5));
    }

    @Test
    @DisplayName("GET /habits - Invalid date format returns 400")
    void listHabitsInvalidDate() throws Exception {
        mockMvc.perform(get("/habits?date=invalid-date"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("GET /habits/score - Returns calculated habit score")
    void getHabitScoreSuccess() throws Exception {
        io.kals.tickoff.dto.HabitScoreResponse response = io.kals.tickoff.dto.HabitScoreResponse.builder()
                .score(66.7)
                .completed(20)
                .expected(30)
                .build();

        when(habitService.calculateHabitScore(LocalDate.of(2026, 9, 2))).thenReturn(response);

        mockMvc.perform(get("/habits/score?date=2026-09-02"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.score").value(66.7))
                .andExpect(jsonPath("$.completed").value(20))
                .andExpect(jsonPath("$.expected").value(30));
    }

    @Test
    @DisplayName("PUT /habits/{id} - Update habit returns 200 OK")
    void updateHabitSuccess() throws Exception {
        io.kals.tickoff.dto.UpdateHabitRequest request = io.kals.tickoff.dto.UpdateHabitRequest.builder()
                .name("Morning Running")
                .icon("directions_run")
                .color("#10B981")
                .build();
        HabitResponse response = HabitResponse.builder()
                .id("test-id-123")
                .name("Morning Running")
                .icon("directions_run")
                .color("#10B981")
                .build();

        when(habitService.updateHabit(eq("test-id-123"), any(io.kals.tickoff.dto.UpdateHabitRequest.class)))
                .thenReturn(response);

        mockMvc.perform(put("/habits/test-id-123")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("test-id-123"))
                .andExpect(jsonPath("$.name").value("Morning Running"))
                .andExpect(jsonPath("$.icon").value("directions_run"))
                .andExpect(jsonPath("$.color").value("#10B981"));
    }

    @Test
    @DisplayName("DELETE /habits/{id} - Delete habit returns 204 No Content")
    void deleteHabitSuccess() throws Exception {
        doNothing().when(habitService).deleteHabit("test-id-123");

        mockMvc.perform(delete("/habits/test-id-123"))
                .andExpect(status().isNoContent());
    }

    @Test
    @DisplayName("DELETE /habits/{id} - Unknown habit returns 404")
    void deleteHabitNotFound() throws Exception {
        doThrow(new ResourceNotFoundException("NOT_FOUND", "Habit not found: unknown"))
                .when(habitService).deleteHabit("unknown");

        mockMvc.perform(delete("/habits/unknown"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Habit not found: unknown"));
    }

    @Test
    @DisplayName("PUT /habits/{id}/completions/{date} - Mark completion returns 200 OK")
    void markCompletionSuccess() throws Exception {
        CompletionResponse response = CompletionResponse.builder()
                .habitId("123")
                .completionDate(LocalDate.of(2026, 9, 1))
                .completed(true)
                .currentStreak(5)
                .build();

        when(habitService.markCompletion("123", LocalDate.of(2026, 9, 1))).thenReturn(response);

        mockMvc.perform(put("/habits/123/completions/2026-09-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.habitId").value("123"))
                .andExpect(jsonPath("$.completionDate").value("2026-09-01"))
                .andExpect(jsonPath("$.completed").value(true))
                .andExpect(jsonPath("$.currentStreak").value(5));
    }

    @Test
    @DisplayName("PUT /habits/{id}/completions/{date} - Unknown habit returns 404")
    void markCompletionNotFound() throws Exception {
        when(habitService.markCompletion("unknown", LocalDate.of(2026, 9, 1)))
                .thenThrow(new ResourceNotFoundException("NOT_FOUND", "Habit not found: unknown"));

        mockMvc.perform(put("/habits/unknown/completions/2026-09-01"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.errorCode").value("NOT_FOUND"))
                .andExpect(jsonPath("$.message").value("Habit not found: unknown"));
    }

    @Test
    @DisplayName("DELETE /habits/{id}/completions/{date} - Unmark completion returns 200 OK")
    void unmarkCompletionSuccess() throws Exception {
        CompletionResponse response = CompletionResponse.builder()
                .habitId("123")
                .completionDate(LocalDate.of(2026, 9, 1))
                .completed(false)
                .currentStreak(0)
                .build();

        when(habitService.unmarkCompletion("123", LocalDate.of(2026, 9, 1))).thenReturn(response);

        mockMvc.perform(delete("/habits/123/completions/2026-09-01"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.habitId").value("123"))
                .andExpect(jsonPath("$.completionDate").value("2026-09-01"))
                .andExpect(jsonPath("$.completed").value(false))
                .andExpect(jsonPath("$.currentStreak").value(0));
    }
}
