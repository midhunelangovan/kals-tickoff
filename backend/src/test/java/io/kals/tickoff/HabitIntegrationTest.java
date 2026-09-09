package io.kals.tickoff;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.kals.tickoff.dto.CompletionResponse;
import io.kals.tickoff.dto.CreateHabitRequest;
import io.kals.tickoff.dto.HabitResponse;
import io.kals.tickoff.dto.HabitScoreResponse;
import io.kals.tickoff.dto.UpdateHabitRequest;
import io.kals.tickoff.repository.HabitCompletionRepository;
import io.kals.tickoff.repository.HabitRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class HabitIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private HabitRepository habitRepository;

    @Autowired
    private HabitCompletionRepository completionRepository;

    @BeforeEach
    void setUp() {
        completionRepository.deleteAll();
        habitRepository.deleteAll();
    }

    @Test
    @DisplayName("Test streak consistency when navigating dates (Cases 1 - 5)")
    void testStreakConsistencyAcrossDates() throws Exception {
        LocalDate today = LocalDate.now();
        LocalDate yesterday = today.minusDays(1);
        LocalDate twoDaysAgo = today.minusDays(2);
        LocalDate threeDaysAgo = today.minusDays(3);

        // 1. Create a habit
        CreateHabitRequest createRequest = new CreateHabitRequest("Walking");
        MvcResult createResult = mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createRequest)))
                .andExpect(status().isCreated())
                .andReturn();

        HabitResponse createdHabit = objectMapper.readValue(
                createResult.getResponse().getContentAsString(),
                HabitResponse.class
        );
        String habitId = createdHabit.getId();

        io.kals.tickoff.entity.Habit habitEntity = habitRepository.findById(habitId).orElseThrow();
        habitEntity.setCreatedAt(threeDaysAgo.atStartOfDay());
        habitRepository.save(habitEntity);

        // ----------------------------------------------------
        // Case 1: Today ✓, Yesterday ✓, 2 days ago ✓ -> Streak = 3
        // ----------------------------------------------------
        mockMvc.perform(put("/habits/" + habitId + "/completions/" + today)).andExpect(status().isOk());
        mockMvc.perform(put("/habits/" + habitId + "/completions/" + yesterday)).andExpect(status().isOk());
        mockMvc.perform(put("/habits/" + habitId + "/completions/" + twoDaysAgo)).andExpect(status().isOk());

        // When Yesterday is selected:
        MvcResult getYesterdayResult = mockMvc.perform(get("/habits?date=" + yesterday))
                .andExpect(status().isOk())
                .andReturn();
        List<HabitResponse> listYesterday = objectMapper.readValue(
                getYesterdayResult.getResponse().getContentAsString(),
                new TypeReference<>() {}
        );
        assertThat(listYesterday.get(0).getCompletedOnSelectedDate()).isTrue();
        assertThat(listYesterday.get(0).getCurrentStreak()).isEqualTo(3);

        // When 2 days ago is selected:
        MvcResult get2DaysAgoResult = mockMvc.perform(get("/habits?date=" + twoDaysAgo))
                .andExpect(status().isOk())
                .andReturn();
        List<HabitResponse> list2DaysAgo = objectMapper.readValue(
                get2DaysAgoResult.getResponse().getContentAsString(),
                new TypeReference<>() {}
        );
        assertThat(list2DaysAgo.get(0).getCompletedOnSelectedDate()).isTrue();
        assertThat(list2DaysAgo.get(0).getCurrentStreak()).isEqualTo(3);

        // ----------------------------------------------------
        // Case 2: Today ✗, Yesterday ✓, 2 days ago ✓ -> Streak = 2
        // ----------------------------------------------------
        mockMvc.perform(delete("/habits/" + habitId + "/completions/" + today)).andExpect(status().isOk());

        MvcResult get2DaysAgoCase2 = mockMvc.perform(get("/habits?date=" + twoDaysAgo))
                .andExpect(status().isOk())
                .andReturn();
        List<HabitResponse> listCase2 = objectMapper.readValue(
                get2DaysAgoCase2.getResponse().getContentAsString(),
                new TypeReference<>() {}
        );
        assertThat(listCase2.get(0).getCompletedOnSelectedDate()).isTrue();
        assertThat(listCase2.get(0).getCurrentStreak()).isEqualTo(2);

        // ----------------------------------------------------
        // Case 3: Today ✗, Yesterday ✗, 2 days ago ✓, 3 days ago ✓ -> Streak = 0
        // ----------------------------------------------------
        mockMvc.perform(delete("/habits/" + habitId + "/completions/" + yesterday)).andExpect(status().isOk());
        mockMvc.perform(put("/habits/" + habitId + "/completions/" + threeDaysAgo)).andExpect(status().isOk());

        MvcResult get2DaysAgoCase3 = mockMvc.perform(get("/habits?date=" + twoDaysAgo))
                .andExpect(status().isOk())
                .andReturn();
        List<HabitResponse> listCase3 = objectMapper.readValue(
                get2DaysAgoCase3.getResponse().getContentAsString(),
                new TypeReference<>() {}
        );
        assertThat(listCase3.get(0).getCompletedOnSelectedDate()).isTrue();
        assertThat(listCase3.get(0).getCurrentStreak()).isEqualTo(0);

        // ----------------------------------------------------
        // Case 4: Today ✓, Yesterday ✗, 2 days ago ✓ -> Streak = 1
        // ----------------------------------------------------
        mockMvc.perform(put("/habits/" + habitId + "/completions/" + today)).andExpect(status().isOk());

        MvcResult get2DaysAgoCase4 = mockMvc.perform(get("/habits?date=" + twoDaysAgo))
                .andExpect(status().isOk())
                .andReturn();
        List<HabitResponse> listCase4 = objectMapper.readValue(
                get2DaysAgoCase4.getResponse().getContentAsString(),
                new TypeReference<>() {}
        );
        assertThat(listCase4.get(0).getCompletedOnSelectedDate()).isTrue();
        assertThat(listCase4.get(0).getCurrentStreak()).isEqualTo(1);

        // ----------------------------------------------------
        // Case 5: Mark / unmark historical date updates streak and completions
        // ----------------------------------------------------
        MvcResult markYesterdayResult = mockMvc.perform(put("/habits/" + habitId + "/completions/" + yesterday))
                .andExpect(status().isOk())
                .andReturn();
        CompletionResponse compYesterday = objectMapper.readValue(
                markYesterdayResult.getResponse().getContentAsString(),
                CompletionResponse.class
        );
        assertThat(compYesterday.getCurrentStreak()).isEqualTo(4);
        assertThat(compYesterday.getCompletions()).contains(threeDaysAgo, twoDaysAgo, yesterday, today);

        MvcResult unmark2DaysAgo = mockMvc.perform(delete("/habits/" + habitId + "/completions/" + twoDaysAgo))
                .andExpect(status().isOk())
                .andReturn();
        CompletionResponse uncomp2DaysAgo = objectMapper.readValue(
                unmark2DaysAgo.getResponse().getContentAsString(),
                CompletionResponse.class
        );
        assertThat(uncomp2DaysAgo.getCurrentStreak()).isEqualTo(2);
        assertThat(uncomp2DaysAgo.getCompletions()).doesNotContain(twoDaysAgo);
    }

    @Test
    @DisplayName("Permanent Habit Delete — deletes habit, completions cascade, and handles 404")
    void testDeleteHabit() throws Exception {
        CreateHabitRequest createA = new CreateHabitRequest("Walking");
        MvcResult resA = mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createA)))
                .andExpect(status().isCreated())
                .andReturn();
        String habitIdA = objectMapper.readValue(resA.getResponse().getContentAsString(), HabitResponse.class).getId();

        CreateHabitRequest createB = new CreateHabitRequest("Reading");
        MvcResult resB = mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createB)))
                .andExpect(status().isCreated())
                .andReturn();
        String habitIdB = objectMapper.readValue(resB.getResponse().getContentAsString(), HabitResponse.class).getId();

        LocalDate today = LocalDate.now();
        mockMvc.perform(put("/habits/" + habitIdA + "/completions/" + today)).andExpect(status().isOk());
        mockMvc.perform(put("/habits/" + habitIdB + "/completions/" + today)).andExpect(status().isOk());

        assertThat(completionRepository.existsByHabitIdAndCompletionDate(habitIdA, today)).isTrue();
        assertThat(completionRepository.existsByHabitIdAndCompletionDate(habitIdB, today)).isTrue();

        mockMvc.perform(delete("/habits/" + habitIdA))
                .andExpect(status().isNoContent());

        assertThat(habitRepository.existsById(habitIdA)).isFalse();
        assertThat(completionRepository.existsByHabitIdAndCompletionDate(habitIdA, today)).isFalse();

        assertThat(habitRepository.existsById(habitIdB)).isTrue();
        assertThat(completionRepository.existsByHabitIdAndCompletionDate(habitIdB, today)).isTrue();
    }

    @Test
    @DisplayName("Update Habit — modifies name, icon, and color")
    void testUpdateHabit() throws Exception {
        CreateHabitRequest create = CreateHabitRequest.builder()
                .name("Old Habit")
                .icon("bolt")
                .color("#7C3AED")
                .build();
        MvcResult createRes = mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(create)))
                .andExpect(status().isCreated())
                .andReturn();
        String id = objectMapper.readValue(createRes.getResponse().getContentAsString(), HabitResponse.class).getId();

        UpdateHabitRequest update = UpdateHabitRequest.builder()
                .name("New Habit Name")
                .icon("fitness_center")
                .color("#10B981")
                .build();

        MvcResult updateRes = mockMvc.perform(put("/habits/" + id)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(update)))
                .andExpect(status().isOk())
                .andReturn();

        HabitResponse updated = objectMapper.readValue(updateRes.getResponse().getContentAsString(), HabitResponse.class);
        assertThat(updated.getName()).isEqualTo("New Habit Name");
        assertThat(updated.getIcon()).isEqualTo("fitness_center");
        assertThat(updated.getColor()).isEqualTo("#10B981");
    }

    @Test
    @DisplayName("GET /habits/score — Calculates authoritative Habit Score based on active habits")
    void testHabitScoreCalculation() throws Exception {
        LocalDate today = LocalDate.now();

        // 1. Initially no habits -> 0.0%
        MvcResult scoreRes0 = mockMvc.perform(get("/habits/score?date=" + today))
                .andExpect(status().isOk())
                .andReturn();
        HabitScoreResponse score0 = objectMapper.readValue(scoreRes0.getResponse().getContentAsString(), HabitScoreResponse.class);
        assertThat(score0.getScore()).isEqualTo(0.0);
        assertThat(score0.getExpected()).isEqualTo(0);
        assertThat(score0.getCompleted()).isEqualTo(0);

        // 2. Create Habit A
        CreateHabitRequest createA = new CreateHabitRequest("Habit A");
        MvcResult resA = mockMvc.perform(post("/habits")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createA)))
                .andExpect(status().isCreated())
                .andReturn();
        String idA = objectMapper.readValue(resA.getResponse().getContentAsString(), HabitResponse.class).getId();

        // Expected = 1 (today), completed = 0 -> Score = 0.0%
        MvcResult scoreRes1 = mockMvc.perform(get("/habits/score?date=" + today))
                .andExpect(status().isOk())
                .andReturn();
        HabitScoreResponse score1 = objectMapper.readValue(scoreRes1.getResponse().getContentAsString(), HabitScoreResponse.class);
        assertThat(score1.getExpected()).isEqualTo(1);
        assertThat(score1.getCompleted()).isEqualTo(0);
        assertThat(score1.getScore()).isEqualTo(0.0);

        // 3. Complete Habit A for today -> Score = 100.0%
        mockMvc.perform(put("/habits/" + idA + "/completions/" + today)).andExpect(status().isOk());

        MvcResult scoreRes2 = mockMvc.perform(get("/habits/score?date=" + today))
                .andExpect(status().isOk())
                .andReturn();
        HabitScoreResponse score2 = objectMapper.readValue(scoreRes2.getResponse().getContentAsString(), HabitScoreResponse.class);
        assertThat(score2.getExpected()).isEqualTo(1);
        assertThat(score2.getCompleted()).isEqualTo(1);
        assertThat(score2.getScore()).isEqualTo(100.0);
    }
}
