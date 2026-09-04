package io.kals.tickoff.repository;

import io.kals.core.repository.AbstractBaseRepository;
import io.kals.tickoff.entity.HabitCompletion;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface HabitCompletionRepository extends AbstractBaseRepository<HabitCompletion, String> {

    Optional<HabitCompletion> findByHabitIdAndCompletionDate(String habitId, LocalDate completionDate);

    boolean existsByHabitIdAndCompletionDate(String habitId, LocalDate completionDate);

    void deleteByHabitIdAndCompletionDate(String habitId, LocalDate completionDate);

    void deleteAllByHabitId(String habitId);

    long countByHabitIdInAndCompletionDate(Collection<String> habitIds, LocalDate completionDate);

    @Query("SELECT c.completionDate FROM HabitCompletion c WHERE c.habitId = :habitId AND c.completionDate <= :date ORDER BY c.completionDate DESC")
    List<LocalDate> findCompletionDatesByHabitIdAndDateLessThanEqual(
            @Param("habitId") String habitId,
            @Param("date") LocalDate date
    );

    @Query("SELECT c FROM HabitCompletion c WHERE c.habitId IN :habitIds ORDER BY c.completionDate ASC")
    List<HabitCompletion> findByHabitIdInOrderByCompletionDateAsc(
            @Param("habitIds") Collection<String> habitIds
    );

    @Query("SELECT c.completionDate FROM HabitCompletion c WHERE c.habitId = :habitId ORDER BY c.completionDate ASC")
    List<LocalDate> findCompletionDatesByHabitIdOrderByCompletionDateAsc(
            @Param("habitId") String habitId
    );
}
