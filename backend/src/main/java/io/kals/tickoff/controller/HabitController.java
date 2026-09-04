package io.kals.tickoff.controller;

import io.kals.tickoff.dto.CompletionResponse;
import io.kals.tickoff.dto.CreateHabitRequest;
import io.kals.tickoff.dto.HabitResponse;
import io.kals.tickoff.service.HabitService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/habits")
@RequiredArgsConstructor
public class HabitController {

    private final HabitService habitService;

    @PostMapping
    public ResponseEntity<HabitResponse> createHabit(@Valid @RequestBody CreateHabitRequest request) {
        HabitResponse response = habitService.createHabit(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @GetMapping
    public ResponseEntity<List<HabitResponse>> listHabits(
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        List<HabitResponse> response = habitService.listHabits(date);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/score")
    public ResponseEntity<io.kals.tickoff.dto.HabitScoreResponse> getHabitScore(
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
            LocalDate date
    ) {
        io.kals.tickoff.dto.HabitScoreResponse response = habitService.calculateHabitScore(date);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{habitId}")
    public ResponseEntity<HabitResponse> updateHabit(
            @PathVariable("habitId") String habitId,
            @Valid @RequestBody io.kals.tickoff.dto.UpdateHabitRequest request
    ) {
        HabitResponse response = habitService.updateHabit(habitId, request);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{habitId}")
    public ResponseEntity<Void> deleteHabit(@PathVariable("habitId") String habitId) {
        habitService.deleteHabit(habitId);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/{habitId}/completions/{date}")
    public ResponseEntity<CompletionResponse> markCompletion(
            @PathVariable("habitId") String habitId,
            @PathVariable("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        CompletionResponse response = habitService.markCompletion(habitId, date);
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{habitId}/completions/{date}")
    public ResponseEntity<CompletionResponse> unmarkCompletion(
            @PathVariable("habitId") String habitId,
            @PathVariable("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        CompletionResponse response = habitService.unmarkCompletion(habitId, date);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/reorder")
    public ResponseEntity<Void> reorderHabits(@RequestBody List<String> habitIds) {
        habitService.reorderHabits(habitIds);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{habitId}/notes")
    public ResponseEntity<io.kals.tickoff.entity.HabitNote> getNote(
            @PathVariable("habitId") String habitId,
            @RequestParam(name = "date", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        LocalDate effectiveDate = (date != null) ? date : LocalDate.now();
        io.kals.tickoff.entity.HabitNote note = habitService.getNote(habitId, effectiveDate);
        return ResponseEntity.ok(note);
    }

    @PutMapping("/{habitId}/notes/{date}")
    public ResponseEntity<io.kals.tickoff.entity.HabitNote> saveNote(
            @PathVariable("habitId") String habitId,
            @PathVariable("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestBody java.util.Map<String, String> body
    ) {
        String content = body != null ? body.get("content") : "";
        io.kals.tickoff.entity.HabitNote note = habitService.saveNote(habitId, date, content);
        return ResponseEntity.ok(note);
    }

    @DeleteMapping("/{habitId}/notes/{date}")
    public ResponseEntity<Void> deleteNote(
            @PathVariable("habitId") String habitId,
            @PathVariable("date") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        habitService.deleteNote(habitId, date);
        return ResponseEntity.noContent().build();
    }
}
