package io.kals.tickoff.repository;

import io.kals.core.repository.AbstractBaseRepository;
import io.kals.tickoff.entity.HabitNote;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface HabitNoteRepository extends AbstractBaseRepository<HabitNote, String> {

    Optional<HabitNote> findByHabitIdAndNoteDate(String habitId, LocalDate noteDate);

    List<HabitNote> findByHabitIdInAndNoteDate(List<String> habitIds, LocalDate noteDate);

    void deleteByHabitIdAndNoteDate(String habitId, LocalDate noteDate);

    void deleteByHabitId(String habitId);
}
