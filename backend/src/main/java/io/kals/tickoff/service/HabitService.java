package io.kals.tickoff.service;

import io.kals.core.exception.Exceptions.ResourceNotFoundException;
import io.kals.tickoff.dto.CompletionResponse;
import io.kals.tickoff.dto.CreateHabitRequest;
import io.kals.tickoff.dto.HabitResponse;
import io.kals.tickoff.dto.HabitScoreResponse;
import io.kals.tickoff.dto.UpdateHabitRequest;
import io.kals.tickoff.entity.Habit;
import io.kals.tickoff.entity.HabitCompletion;
import io.kals.tickoff.entity.HabitNote;
import io.kals.tickoff.mapper.HabitMapper;
import io.kals.tickoff.repository.HabitCompletionRepository;
import io.kals.tickoff.repository.HabitNoteRepository;
import io.kals.tickoff.repository.HabitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HabitService {

    private final HabitRepository habitRepository;
    private final HabitCompletionRepository completionRepository;
    private final HabitNoteRepository habitNoteRepository;
    private final StreakService streakService;
    private final HabitMapper habitMapper;

    @Transactional
    public HabitResponse createHabit(CreateHabitRequest request) {
        Habit habit = Habit.create(
                request.getName().trim(),
                request.getIcon(),
                null,
                request.getDescription(),
                request.getColor()
        );
        Habit savedHabit = habitRepository.save(habit);
        return habitMapper.toCreatedResponse(savedHabit, 0, false);
    }

    @Transactional(readOnly = true)
    public List<HabitResponse> listHabits(LocalDate selectedDate) {
        LocalDate today = LocalDate.now();
        LocalDate effectiveSelectedDate = (selectedDate != null) ? selectedDate : today;
        List<Habit> habits = habitRepository.findAllByArchivedFalseOrderBySortOrderAscCreatedAtDesc();

        if (habits.isEmpty()) {
            return Collections.emptyList();
        }

        List<String> habitIds = habits.stream().map(Habit::getId).toList();
        List<HabitCompletion> allCompletions = completionRepository
                .findByHabitIdInOrderByCompletionDateAsc(habitIds);

        Map<String, List<LocalDate>> completionsByHabit = allCompletions.stream()
                .collect(Collectors.groupingBy(
                        HabitCompletion::getHabitId,
                        Collectors.mapping(HabitCompletion::getCompletionDate, Collectors.toList())
                ));

        Map<String, String> notesByHabit = habitNoteRepository
                .findByHabitIdInAndNoteDate(habitIds, effectiveSelectedDate).stream()
                .collect(Collectors.toMap(HabitNote::getHabitId, HabitNote::getContent));

        return habits.stream().map(habit -> {
            List<LocalDate> sortedDates = completionsByHabit.getOrDefault(habit.getId(), Collections.emptyList());
            Set<LocalDate> completedDates = new HashSet<>(sortedDates);

            boolean completedOnSelectedDate = completedDates.contains(effectiveSelectedDate);
            int currentStreak = streakService.calculateStreakFromDateSet(completedDates, today);
            String noteContent = notesByHabit.get(habit.getId());

            return habitMapper.toListResponse(
                    habit,
                    effectiveSelectedDate,
                    currentStreak,
                    completedOnSelectedDate,
                    sortedDates,
                    noteContent != null && !noteContent.isBlank(),
                    noteContent
            );
        }).toList();
    }

    @Transactional
    public void reorderHabits(List<String> habitIds) {
        if (habitIds == null || habitIds.isEmpty()) return;
        for (int i = 0; i < habitIds.size(); i++) {
            String id = habitIds.get(i);
            int order = i;
            habitRepository.findById(id).ifPresent(h -> {
                h.setSortOrder(order);
                habitRepository.save(h);
            });
        }
    }

    @Transactional(readOnly = true)
    public HabitScoreResponse calculateHabitScore(LocalDate targetDate) {
        LocalDate today = LocalDate.now();
        LocalDate selectedDate = (targetDate != null) ? targetDate : today;

        List<Habit> activeHabits = habitRepository.findAllByArchivedFalseOrderByCreatedAtDesc();
        if (activeHabits.isEmpty()) {
            return HabitScoreResponse.builder()
                    .date(selectedDate.toString())
                    .score(0.0)
                    .completed(0)
                    .total(0)
                    .expected(0)
                    .build();
        }

        LocalDate endDate = selectedDate.isAfter(today) ? today : selectedDate;

        long totalEligible = 0;
        long totalCompleted = 0;

        List<String> activeIds = activeHabits.stream().map(Habit::getId).toList();
        List<HabitCompletion> allCompletions = completionRepository.findByHabitIdInOrderByCompletionDateAsc(activeIds);
        Map<String, List<LocalDate>> completionsByHabit = allCompletions.stream()
                .collect(Collectors.groupingBy(HabitCompletion::getHabitId, Collectors.mapping(HabitCompletion::getCompletionDate, Collectors.toList())));

        for (Habit habit : activeHabits) {
            LocalDate startDate = habit.getCreatedAt().toLocalDate();
            if (endDate.isBefore(startDate)) {
                continue;
            }
            long eligibleDays = ChronoUnit.DAYS.between(startDate, endDate) + 1;
            totalEligible += eligibleDays;

            List<LocalDate> completions = completionsByHabit.getOrDefault(habit.getId(), Collections.emptyList());
            long completedInRange = completions.stream()
                    .filter(d -> !d.isBefore(startDate) && !d.isAfter(endDate))
                    .count();
            totalCompleted += completedInRange;
        }

        double score = totalEligible > 0
                ? Math.round(((double) totalCompleted / (double) totalEligible) * 1000.0) / 10.0
                : 0.0;

        return HabitScoreResponse.builder()
                .date(selectedDate.toString())
                .score(score)
                .completed(totalCompleted)
                .total(totalEligible)
                .expected(totalEligible)
                .build();
    }

    @Transactional
    public CompletionResponse markCompletion(String habitId, LocalDate date) {
        if (!habitRepository.existsById(habitId)) {
            throw new ResourceNotFoundException("NOT_FOUND", "Habit not found: " + habitId);
        }

        if (!completionRepository.existsByHabitIdAndCompletionDate(habitId, date)) {
            HabitCompletion completion = HabitCompletion.create(habitId, date);
            completionRepository.save(completion);
        }

        LocalDate today = LocalDate.now();
        int currentStreak = streakService.calculateCurrentStreak(habitId, today);
        List<LocalDate> completions = completionRepository.findCompletionDatesByHabitIdOrderByCompletionDateAsc(habitId);

        return habitMapper.toCompletionResponse(habitId, date, true, currentStreak, completions);
    }

    @Transactional
    public CompletionResponse unmarkCompletion(String habitId, LocalDate date) {
        if (!habitRepository.existsById(habitId)) {
            throw new ResourceNotFoundException("NOT_FOUND", "Habit not found: " + habitId);
        }

        if (completionRepository.existsByHabitIdAndCompletionDate(habitId, date)) {
            completionRepository.deleteByHabitIdAndCompletionDate(habitId, date);
        }

        LocalDate today = LocalDate.now();
        int currentStreak = streakService.calculateCurrentStreak(habitId, today);
        List<LocalDate> completions = completionRepository.findCompletionDatesByHabitIdOrderByCompletionDateAsc(habitId);

        return habitMapper.toCompletionResponse(habitId, date, false, currentStreak, completions);
    }

    @Transactional
    public HabitResponse updateHabit(String habitId, UpdateHabitRequest request) {
        Habit habit = habitRepository.findById(habitId)
                .orElseThrow(() -> new ResourceNotFoundException("NOT_FOUND", "Habit not found: " + habitId));

        String trimmedName = request.getName() != null ? request.getName().trim() : "";
        if (trimmedName.isEmpty()) {
            throw new IllegalArgumentException("Habit name cannot be blank");
        }

        habit.setName(trimmedName);
        if (request.getIcon() != null && !request.getIcon().isBlank()) {
            habit.setIcon(request.getIcon().trim());
        }
        if (request.getColor() != null && !request.getColor().isBlank()) {
            habit.setColor(request.getColor().trim());
        }
        if (request.getDescription() != null) {
            habit.setDescription(request.getDescription().trim());
        }

        Habit saved = habitRepository.save(habit);

        LocalDate today = LocalDate.now();
        int currentStreak = streakService.calculateCurrentStreak(habitId, today);
        boolean completedToday = completionRepository.existsByHabitIdAndCompletionDate(habitId, today);
        List<LocalDate> completions = completionRepository.findCompletionDatesByHabitIdOrderByCompletionDateAsc(habitId);
        HabitNote note = habitNoteRepository.findByHabitIdAndNoteDate(habitId, today).orElse(null);

        return habitMapper.toListResponse(
                saved, today, currentStreak, completedToday, completions,
                note != null && !note.getContent().isBlank(),
                note != null ? note.getContent() : null
        );
    }

    @Transactional
    public void deleteHabit(String habitId) {
        if (!habitRepository.existsById(habitId)) {
            throw new ResourceNotFoundException("NOT_FOUND", "Habit not found: " + habitId);
        }

        habitNoteRepository.deleteByHabitId(habitId);
        completionRepository.deleteAllByHabitId(habitId);
        habitRepository.deleteById(habitId);
    }

    @Transactional(readOnly = true)
    public HabitNote getNote(String habitId, LocalDate date) {
        return habitNoteRepository.findByHabitIdAndNoteDate(habitId, date).orElse(null);
    }

    @Transactional
    public HabitNote saveNote(String habitId, LocalDate date, String content) {
        if (!habitRepository.existsById(habitId)) {
            throw new ResourceNotFoundException("NOT_FOUND", "Habit not found: " + habitId);
        }

        HabitNote note = habitNoteRepository.findByHabitIdAndNoteDate(habitId, date)
                .map(existing -> {
                    existing.setContent(content != null ? content.trim() : "");
                    existing.setUpdatedAt(java.time.LocalDateTime.now());
                    return existing;
                })
                .orElseGet(() -> HabitNote.create(habitId, date, content));

        return habitNoteRepository.save(note);
    }

    @Transactional
    public void deleteNote(String habitId, LocalDate date) {
        habitNoteRepository.deleteByHabitIdAndNoteDate(habitId, date);
    }
}
