package io.kals.tickoff.repository;

import io.kals.core.repository.AbstractBaseRepository;
import io.kals.tickoff.entity.Habit;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HabitRepository extends AbstractBaseRepository<Habit, String> {

    List<Habit> findAllByArchivedFalseOrderByCreatedAtDesc();

    List<Habit> findAllByArchivedFalseOrderBySortOrderAscCreatedAtDesc();

    List<Habit> findByCategoryId(String categoryId);
}
